const mongoose = require('mongoose');

const Item = require('../models/item.model');
const Notification = require('../models/notification.model');
const { getDb, getMessagingClient, isFirebaseConfigured } = require('../config/firebase');
const { findMatchesForItem } = require('./match.service');

const DEVICE_TOKENS_COLLECTION = 'device_tokens';

// Best-effort FCM push to every device the user has registered. Notifications
// are always persisted in Mongo first; if Firebase isn't configured or the push
// fails, the in-app feed still works — push simply stays off, mirroring how the
// client treats it.
async function pushToUser(userId, { title, body, data = {} }) {
  if (!isFirebaseConfigured()) return;

  try {
    const db = getDb();
    const tokenSnap = await db
      .collection(DEVICE_TOKENS_COLLECTION)
      .doc(userId.toString())
      .get();
    const tokens = tokenSnap.exists ? tokenSnap.data().tokens || [] : [];
    if (!tokens.length) return;

    // FCM data values must all be strings.
    const stringData = {};
    Object.entries(data).forEach(([key, value]) => {
      stringData[key] = value == null ? '' : String(value);
    });

    const response = await getMessagingClient().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: stringData,
      android: { priority: 'high' },
    });

    // Drop tokens Firebase reports as dead so they don't accumulate.
    const stale = [];
    response.responses.forEach((result, index) => {
      if (
        !result.success &&
        result.error &&
        (result.error.code === 'messaging/registration-token-not-registered' ||
          result.error.code === 'messaging/invalid-registration-token')
      ) {
        stale.push(tokens[index]);
      }
    });
    if (stale.length) {
      const { FieldValue } = require('firebase-admin/firestore');
      await db
        .collection(DEVICE_TOKENS_COLLECTION)
        .doc(userId.toString())
        .set({ tokens: FieldValue.arrayRemove(...stale) }, { merge: true });
    }
  } catch (error) {
    console.error(`Push to ${userId} failed: ${error.message}`);
  }
}

async function createNotification({ user, type, title, body, data = {} }) {
  const notification = await Notification.create({ user, type, title, body, data });

  // Fire the push without blocking the caller.
  pushToUser(user, {
    title,
    body,
    data: { kind: data.kind || type, notificationId: notification._id.toString(), ...data },
  }).catch(() => {});

  return notification.toSafeObject();
}

async function listNotifications(userId, { page = 1, limit = 30 } = {}) {
  const skip = (page - 1) * limit;
  const [notifications, total, unread] = await Promise.all([
    Notification.find({ user: userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Notification.countDocuments({ user: userId }),
    Notification.countDocuments({ user: userId, isRead: false }),
  ]);

  return {
    notifications: notifications.map((n) => n.toSafeObject()),
    unreadCount: unread,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
}

async function getUnreadCount(userId) {
  const unreadCount = await Notification.countDocuments({ user: userId, isRead: false });
  return { unreadCount };
}

async function markAsRead(userId, notificationId) {
  if (!mongoose.Types.ObjectId.isValid(notificationId)) {
    const error = new Error('Invalid notification id');
    error.statusCode = 400;
    throw error;
  }

  const notification = await Notification.findOneAndUpdate(
    { _id: notificationId, user: userId },
    { isRead: true },
    { new: true }
  );

  if (!notification) {
    const error = new Error('Notification not found');
    error.statusCode = 404;
    throw error;
  }

  return notification.toSafeObject();
}

async function markAllAsRead(userId) {
  await Notification.updateMany({ user: userId, isRead: false }, { isRead: true });
  return { unreadCount: 0 };
}

// ── Match-driven notifications ──────────────────────────────────────────────

// Fired (fire-and-forget) right after an item is created. Notifies the new
// poster about any matches, and notifies each matched item's owner that a new
// opposite item may match theirs. Never throws — match notifications must never
// break item creation.
async function notifyMatchesForNewItem(item) {
  try {
    const matches = await findMatchesForItem(item);
    if (!matches.length) return;

    const oppositeWord = item.status === 'lost' ? 'found' : 'lost';
    const plural = matches.length === 1 ? '' : 'es';

    // 1. One aggregated notification to the user who just posted.
    await createNotification({
      user: ownerIdOf(item),
      type: 'match',
      title:
        matches.length === 1
          ? 'Possible match found'
          : `${matches.length} possible matches found`,
      body: `We found ${matches.length} ${oppositeWord} item${
        matches.length === 1 ? '' : 's'
      } that may match your "${item.title}".`,
      data: { kind: 'match', itemId: item._id.toString() },
    });

    // 2. One notification to each matched item's owner.
    for (const match of matches) {
      if (!match.item.postedById) continue;
      // eslint-disable-next-line no-await-in-loop
      await createNotification({
        user: match.item.postedById,
        type: 'match',
        title: 'A new item may match yours',
        body: `A newly reported ${item.status} item may match your "${match.item.title}". Tap to review.`,
        data: { kind: 'match', itemId: match.item.id, matchItemId: item._id.toString() },
      });
    }
  } catch (error) {
    console.error(`Match notifications for item ${item && item._id} failed: ${error.message}`);
  }
}

// Found-item owner nudges the lost-item owner ("I think I found yours"). The
// caller must own `sourceItemId`; the lost item's owner receives the alert.
async function notifyOwnerOfMatch(user, sourceItemId, matchItemId) {
  if (
    !mongoose.Types.ObjectId.isValid(sourceItemId) ||
    !mongoose.Types.ObjectId.isValid(matchItemId)
  ) {
    const error = new Error('Invalid item id');
    error.statusCode = 400;
    throw error;
  }

  const [source, target] = await Promise.all([
    Item.findById(sourceItemId),
    Item.findById(matchItemId),
  ]);

  if (!source) {
    const error = new Error('Item not found');
    error.statusCode = 404;
    throw error;
  }
  if (source.postedBy.toString() !== user._id.toString()) {
    const error = new Error('You can only notify owners from your own post');
    error.statusCode = 403;
    throw error;
  }
  if (!target) {
    const error = new Error('Match item not found');
    error.statusCode = 404;
    throw error;
  }
  if (target.postedBy.toString() === user._id.toString()) {
    const error = new Error('You cannot notify yourself');
    error.statusCode = 400;
    throw error;
  }

  await createNotification({
    user: target.postedBy,
    type: 'match',
    title: 'Someone may have found your item',
    body: `${user.fullName} thinks the "${source.title}" they reported matches your "${target.title}". Tap to review and claim.`,
    data: {
      kind: 'match',
      itemId: target._id.toString(),
      matchItemId: source._id.toString(),
    },
  });

  return { notified: true };
}

function ownerIdOf(item) {
  return item.postedBy && item.postedBy._id ? item.postedBy._id : item.postedBy;
}

module.exports = {
  createNotification,
  listNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  notifyMatchesForNewItem,
  notifyOwnerOfMatch,
};
