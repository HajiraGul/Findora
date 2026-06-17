const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

exports.onNewChatMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const { chatId } = event.params;

    const chatRef = db.collection('chats').doc(chatId);
    const chatSnap = await chatRef.get();
    if (!chatSnap.exists) return;
    const chat = chatSnap.data();

    // Image-only messages carry no text, so fall back to a short label for the
    // conversation-list preview and the push notification body.
    const preview =
      message.text && message.text.trim()
        ? message.text
        : message.imageUrl
          ? '📷 Photo'
          : '';

    const now = Date.now();
    await chatRef.update({
      lastMessage: {
        text: preview,
        senderId: message.senderId,
        sentAt: message.sentAt || now,
      },
      updatedAt: now,
    });

    const recipientId = (chat.participantIds || []).find(
      (id) => id !== message.senderId
    );
    if (!recipientId) return;

    const tokenSnap = await db.collection('device_tokens').doc(recipientId).get();
    const tokens = tokenSnap.exists ? tokenSnap.data().tokens || [] : [];
    if (!tokens.length) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: message.senderName || chat.itemTitle || 'New message',
        body: preview,
      },
      data: { type: 'chat', chatId },
      android: { priority: 'high' },
    });

    // Drop tokens Firebase reports as invalid so they don't pile up.
    const stale = [];
    response.responses.forEach((r, i) => {
      if (
        !r.success &&
        r.error &&
        (r.error.code === 'messaging/registration-token-not-registered' ||
          r.error.code === 'messaging/invalid-registration-token')
      ) {
        stale.push(tokens[i]);
      }
    });
    if (stale.length) {
      const { FieldValue } = require('firebase-admin/firestore');
      await db
        .collection('device_tokens')
        .doc(recipientId)
        .set({ tokens: FieldValue.arrayRemove(...stale) }, { merge: true });
    }
  }
);
