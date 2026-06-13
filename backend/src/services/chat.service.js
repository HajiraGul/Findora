const Claim = require('../models/claim.model');
const { getDb } = require('../config/firebase');

const CHATS_COLLECTION = 'chats';
const MESSAGES_COLLECTION = 'messages';
const MESSAGES_PAGE_LIMIT = 200;

function chatFromDoc(doc) {
  return { id: doc.id, ...doc.data() };
}

function messageFromDoc(doc) {
  return { id: doc.id, ...doc.data() };
}

function isParticipant(chat, user) {
  return chat.participantIds.includes(user._id.toString());
}

// Creates (or re-enables) the chat for an approved claim. The chat document id
// is the claim id, so one approved claim maps to exactly one conversation
// between the claimant and the user who posted the item.
async function ensureChatForClaim(claimId) {
  const claim = await Claim.findById(claimId)
    .populate({
      path: 'item',
      select: 'title postedBy',
      populate: { path: 'postedBy', select: 'fullName' },
    })
    .populate('claimant', 'fullName');

  if (!claim) {
    const error = new Error('Claim not found');
    error.statusCode = 404;
    throw error;
  }
  if (claim.status !== 'approved') {
    const error = new Error('Chat can only be unlocked for approved claims');
    error.statusCode = 400;
    throw error;
  }

  const db = getDb();
  const ref = db.collection(CHATS_COLLECTION).doc(claim._id.toString());
  const snapshot = await ref.get();
  const now = Date.now();

  if (snapshot.exists) {
    if (!snapshot.data().enabled) {
      await ref.update({ enabled: true, updatedAt: now });
    }
    return chatFromDoc(await ref.get());
  }

  const poster = claim.item.postedBy;
  const chat = {
    claimId: claim._id.toString(),
    itemId: claim.item._id.toString(),
    itemTitle: claim.item.title,
    posterId: poster._id.toString(),
    posterName: poster.fullName,
    claimantId: claim.claimant._id.toString(),
    claimantName: claim.claimant.fullName,
    participantIds: [poster._id.toString(), claim.claimant._id.toString()],
    enabled: true,
    lastMessage: null,
    createdAt: now,
    updatedAt: now,
  };

  await ref.set(chat);
  return { id: ref.id, ...chat };
}

// Lets a chat participant (the claimant or the item poster) open the chat for
// an approved claim, creating it on demand if it was never made — e.g. the
// claim was approved while Firebase wasn't configured yet. Idempotent.
async function openChatForClaim(claimId, user) {
  const claim = await Claim.findById(claimId).populate('item', 'postedBy');
  if (!claim) {
    const error = new Error('Claim not found');
    error.statusCode = 404;
    throw error;
  }

  const posterId =
    claim.item && claim.item.postedBy ? claim.item.postedBy.toString() : null;
  const claimantId = claim.claimant.toString();
  const uid = user._id.toString();

  if (uid !== posterId && uid !== claimantId && user.role !== 'admin') {
    const error = new Error('Access denied');
    error.statusCode = 403;
    throw error;
  }

  // ensureChatForClaim enforces that the claim is approved before unlocking.
  return ensureChatForClaim(claimId);
}

async function getMyChats(user) {
  const db = getDb();
  const snapshot = await db
    .collection(CHATS_COLLECTION)
    .where('participantIds', 'array-contains', user._id.toString())
    .get();

  return snapshot.docs
    .map(chatFromDoc)
    .sort((a, b) => (b.updatedAt || 0) - (a.updatedAt || 0));
}

async function getChatById(chatId, user) {
  const db = getDb();
  const snapshot = await db.collection(CHATS_COLLECTION).doc(chatId).get();

  if (!snapshot.exists) {
    const error = new Error('Chat not found');
    error.statusCode = 404;
    throw error;
  }

  const chat = chatFromDoc(snapshot);
  if (!isParticipant(chat, user) && user.role !== 'admin') {
    const error = new Error('Access denied');
    error.statusCode = 403;
    throw error;
  }

  return chat;
}

// Participants can still read history while a chat is disabled; only sending
// is blocked, so the admin decision never deletes evidence of past messages.
async function listMessages(chatId, user, afterMs) {
  const chat = await getChatById(chatId, user);

  const db = getDb();
  let query = db
    .collection(CHATS_COLLECTION)
    .doc(chatId)
    .collection(MESSAGES_COLLECTION)
    .orderBy('sentAt', 'asc');

  if (afterMs) {
    query = query.where('sentAt', '>', afterMs);
  }

  const snapshot = await query.limit(MESSAGES_PAGE_LIMIT).get();

  return {
    chat,
    messages: snapshot.docs.map(messageFromDoc),
  };
}

async function sendMessage(chatId, user, text) {
  const chat = await getChatById(chatId, user);

  if (!isParticipant(chat, user)) {
    const error = new Error('Only chat participants can send messages');
    error.statusCode = 403;
    throw error;
  }
  if (!chat.enabled) {
    const error = new Error('This chat has been disabled by the admin');
    error.statusCode = 403;
    throw error;
  }

  const db = getDb();
  const chatRef = db.collection(CHATS_COLLECTION).doc(chatId);
  const now = Date.now();
  const message = {
    senderId: user._id.toString(),
    senderName: user.fullName,
    text,
    sentAt: now,
  };

  const messageRef = await chatRef.collection(MESSAGES_COLLECTION).add(message);
  await chatRef.update({
    lastMessage: { text, senderId: message.senderId, sentAt: now },
    updatedAt: now,
  });

  return { id: messageRef.id, ...message };
}

async function listAllChats() {
  const db = getDb();
  const snapshot = await db
    .collection(CHATS_COLLECTION)
    .orderBy('updatedAt', 'desc')
    .get();

  return snapshot.docs.map(chatFromDoc);
}

async function setChatEnabled(chatId, enabled) {
  const db = getDb();
  const ref = db.collection(CHATS_COLLECTION).doc(chatId);
  const snapshot = await ref.get();

  if (!snapshot.exists) {
    const error = new Error('Chat not found');
    error.statusCode = 404;
    throw error;
  }

  await ref.update({ enabled, updatedAt: Date.now() });
  return chatFromDoc(await ref.get());
}

module.exports = {
  ensureChatForClaim,
  openChatForClaim,
  getMyChats,
  getChatById,
  listMessages,
  sendMessage,
  listAllChats,
  setChatEnabled,
};
