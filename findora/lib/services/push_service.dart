import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

/// Registers this device's FCM token so the `onNewChatMessage` Cloud Function
/// can target it, and surfaces foreground messages. Tokens are stored at
/// `device_tokens/{backendUserId}` — the same backend (Mongo) user id used in
/// chat `participantIds`, so the function can look the recipient up directly.
class PushService {
  bool _foregroundReady = false;

  Future<void> register(String userId) async {
    if (userId.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _saveToken(userId, token);

      messaging.onTokenRefresh.listen((t) => _saveToken(userId, t).ignore());
      _setupForegroundListener();
    } catch (_) {
      // Push simply stays off if Firebase isn't ready.
    }
  }

  Future<void> remove(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('device_tokens')
            .doc(userId)
            .set({
          'tokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
      }
      await messaging.deleteToken();
    } catch (_) {}
  }

  Future<void> _saveToken(String userId, String token) {
    return FirebaseFirestore.instance
        .collection('device_tokens')
        .doc(userId)
        .set({
      'tokens': FieldValue.arrayUnion([token]),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  void _setupForegroundListener() {
    if (_foregroundReady) return;
    _foregroundReady = true;
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      Get.snackbar(
        n.title ?? 'New message',
        n.body ?? '',
        snackPosition: SnackPosition.TOP,
      );
    });
  }
}
