import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    } on FirebaseAuthException catch (e) {
      // Non-fatal, but DON'T swallow silently: with no Firebase identity, every
      // Firestore chat read/write is rejected with permission-denied and the
      // real cause stays invisible (which is exactly what happened here).
      if (e.code == 'operation-not-allowed' ||
          e.code == 'configuration-not-found') {
        // ignore: avoid_print
        print('[firebase-auth] Email/Password sign-in is DISABLED for this '
            'Firebase project. Enable it in Firebase Console → Authentication → '
            'Sign-in method, otherwise chat stays permission-denied. (${e.code})');
      } else {
        // ignore: avoid_print
        print('[firebase-auth] shadow sign-in failed: ${e.code} ${e.message}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[firebase-auth] shadow sign-in failed: $e');
    }
  }

  /// Runs the "Continue with Google" flow and returns a *Firebase* ID token
  /// that the backend can verify with the Admin SDK to mint our own JWT.
  ///
  /// Returns `null` if the user cancels the Google account picker (so callers
  /// can quietly abort rather than show an error). Throws on real failures.
  Future<String?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user dismissed the picker

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    // Sign into Firebase with the Google credential. This also gives the device
    // a real (non-shadow) Firebase identity, which satisfies the Firestore
    // chat/push rules for this user.
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final token = await userCredential.user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Google sign-in did not return a valid token');
    }

    return token;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
