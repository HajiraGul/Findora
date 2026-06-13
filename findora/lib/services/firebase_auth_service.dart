import 'package:firebase_auth/firebase_auth.dart';

/// "Shadow" Firebase Auth account, used only so the device carries a Firebase
/// identity that satisfies Firestore security rules. This is NOT the app's real
/// login — the real login stays with the Node backend (JWT). Every user signs
/// into Firebase with the same shared password, keyed by their real email.
///
/// SECURITY NOTE: because the password is shared and ships inside the app, this
/// identity is not trustworthy on its own — anyone who extracts the scheme can
/// sign in as any email. The Firestore rules therefore cannot truly restrict a
/// chat to its two participants (ceiling: "any authenticated device"). To get
/// real per-user enforcement, swap this for backend-minted custom tokens
/// (uid == Mongo _id) and tighten the rules — that is a one-method change here.
/// See FIREBASE_PUSH_CHAT_SETUP.md.
class FirebaseAuthService {
  // Must satisfy Firebase's password policy (>= 6 chars).
  static const _sharedPassword = 'Findora#shadow2026';

  /// Signs the device into the shadow Firebase account, creating it the first
  /// time. Fire-and-forget: any failure just leaves chat/push unavailable and
  /// never affects the real backend session.
  Future<void> ensureSignedIn(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return;

      try {
        await auth.signInWithEmailAndPassword(
          email: normalized,
          password: _sharedPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          await auth.createUserWithEmailAndPassword(
            email: normalized,
            password: _sharedPassword,
          );
        } else {
          rethrow;
        }
      }
    } catch (_) {
      // Ignored on purpose; see doc comment above.
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
