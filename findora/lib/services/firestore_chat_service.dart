import 'package:cloud_firestore/cloud_firestore.dart';

/// Direct Firestore access for the two-participant claim chat.
///
/// Chat documents (`chats/{claimId}`) are still created and admin-gated by the
/// Node backend through the Admin SDK. This client only reads those documents
/// and appends messages to the `messages` subcollection. The `lastMessage`
/// summary and push notifications are produced by the `onNewChatMessage` Cloud
/// Function, so the client never needs write access to the chat document.
class FirestoreChatService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> doc) {
    return {...?doc.data(), 'id': doc.id};
  }

  Stream<List<Map<String, dynamic>>> watchMyChats(String userId) {
    final db = _db;
    if (db == null) return Stream.value(<Map<String, dynamic>>[]);
    return db
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map(_withId).toList());
  }

  Stream<Map<String, dynamic>?> watchChat(String chatId) {
    final db = _db;
    if (db == null) return Stream.value(null);
    return db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.exists ? _withId(doc) : null);
  }

  Future<Map<String, dynamic>?> getChat(String chatId) async {
    final db = _db;
    if (db == null) return null;
    final doc = await db.collection('chats').doc(chatId).get();
    return doc.exists ? _withId(doc) : null;
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    final db = _db;
    if (db == null) return Stream.value(<Map<String, dynamic>>[]);
    return db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map(_withId).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final db = _db;
    if (db == null) throw StateError('Firebase is not configured');
    await db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
