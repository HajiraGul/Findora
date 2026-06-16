import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../services/auth_api_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/push_service.dart';

class RememberedCredentials {
  final String email;
  final String password;

  const RememberedCredentials({required this.email, required this.password});
}

class AuthController extends GetxController {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _rememberEmailKey = 'remember_email';
  static const _rememberPasswordKey = 'remember_password';
  static const _rememberAccountsKey = 'remember_accounts';

  final AuthApiService _authApiService;
  final FirebaseAuthService _firebaseAuth;
  final PushService _push;

  // Credentials for "Remember me" live in the OS keychain/keystore rather than
  // SharedPreferences, since a password should never sit in plain text.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthController(this._authApiService, this._firebaseAuth, this._push);

  final isLoading = false.obs;
  final resetLoading = false.obs;
  final otpLoading = false.obs;
  final profileLoading = false.obs;
  final lastDevelopmentOtp = RxnString();
  final token = RxnString();
  final user = Rxn<AuthUser>();
  final profileStats = const ProfileStats(posts: 0, claims: 0, matches: 0).obs;

  bool get isAuthenticated => token.value != null && token.value!.isNotEmpty;
  bool get isAdmin => user.value?.role == 'admin';

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey);
      final storedUser = prefs.getString(_userKey);

      if (storedToken == null || storedUser == null) return;

      token.value = storedToken;
      user.value = AuthUser.fromJson(
        jsonDecode(storedUser) as Map<String, dynamic>,
      );
      _syncFirebaseSession(user.value!);
    } catch (_) {
      // A corrupt stored session must never crash startup — treat as logged out.
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _submitAuthRequest(
      () => _authApiService.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String cityOrUniversity,
    required String password,
  }) async {
    await _submitAuthRequest(
      () => _authApiService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        cityOrUniversity: cityOrUniversity,
        password: password,
      ),
    );
  }

  /// Runs "Continue with Google": signs into Firebase with the Google
  /// credential, exchanges the Firebase ID token for our backend JWT, and
  /// stores the session. Returns `false` if the user cancelled the picker.
  Future<bool> googleSignIn() async {
    try {
      isLoading.value = true;
      final idToken = await _firebaseAuth.signInWithGoogle();
      if (idToken == null) return false; // cancelled

      await _handleAuthResponse(
        await _authApiService.googleSignIn(idToken: idToken),
      );
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final currentToken = token.value;

    if (currentToken != null && currentToken.isNotEmpty) {
      try {
        isLoading.value = true;
        await _authApiService.logout(currentToken);
      } catch (_) {
        // Still clear the local session when the user explicitly logs out.
      } finally {
        isLoading.value = false;
      }
    }

    await _clearSession();
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      resetLoading.value = true;
      final response = await _authApiService.forgotPassword(email: email);

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      _storeDevelopmentOtp(response.body);
    } finally {
      resetLoading.value = false;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      resetLoading.value = true;
      final response = await _authApiService.resetPassword(
        email: email,
        otp: otp,
        password: password,
      );

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      lastDevelopmentOtp.value = null;
    } finally {
      resetLoading.value = false;
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      otpLoading.value = true;
      final response = await _authApiService.verifyOtp(email: email, otp: otp);

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      final body = response.body;
      if (body is Map<String, dynamic> &&
          body['user'] is Map<String, dynamic>) {
        final verifiedUser = AuthUser.fromJson(
          body['user'] as Map<String, dynamic>,
        );
        await _saveSession(token.value, verifiedUser);
      }
    } finally {
      otpLoading.value = false;
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      otpLoading.value = true;
      final response = await _authApiService.resendOtp(email: email);

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      _storeDevelopmentOtp(response.body);
    } finally {
      otpLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.getProfile(currentToken);

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      await _saveUserFromResponse(response.body);
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> refreshProfileSummary() async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.getProfileSummary(currentToken);

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      final body = response.body;
      if (body is! Map<String, dynamic>) {
        throw Exception('Profile summary response is invalid');
      }

      if (body['user'] is Map<String, dynamic>) {
        await _saveSession(
          token.value,
          AuthUser.fromJson(body['user'] as Map<String, dynamic>),
        );
      }

      if (body['stats'] is Map<String, dynamic>) {
        profileStats.value = ProfileStats.fromJson(
          body['stats'] as Map<String, dynamic>,
        );
      }
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String cityOrUniversity,
    String? about,
  }) async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.updateProfile(
        token: currentToken,
        fullName: fullName,
        email: email,
        phone: phone,
        cityOrUniversity: cityOrUniversity,
        about: about,
      );

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      await _saveUserFromResponse(response.body);
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> updateAvatar({required String avatarUrl}) async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.updateAvatar(
        token: currentToken,
        avatarUrl: avatarUrl,
      );

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      await _saveUserFromResponse(response.body);
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.updatePassword(
        token: currentToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      await _clearSession();
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> updatePreferences({
    bool? notifications,
    bool? darkMode,
    bool? twoFactor,
    bool? biometric,
  }) async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.updatePreferences(
        token: currentToken,
        notifications: notifications,
        darkMode: darkMode,
        twoFactor: twoFactor,
        biometric: biometric,
      );

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      await _saveUserFromResponse(response.body);
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    final currentToken = _requireToken();

    try {
      profileLoading.value = true;
      final response = await _authApiService.deleteAccount(currentToken);

      if (!response.isOk) {
        throw Exception(_extractErrorMessage(response.body));
      }

      await _clearSession();
    } finally {
      profileLoading.value = false;
    }
  }

  /// All accounts saved via "Remember me", as an ordered email -> password map.
  /// Passwords live in the OS keychain/keystore, never in SharedPreferences.
  Future<Map<String, String>> loadRememberedAccounts() async {
    final accounts = <String, String>{};
    try {
      final raw = await _secureStorage.read(key: _rememberAccountsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            accounts[key.toString()] = value.toString();
          });
        }
      }

      // Back-compat: fold in any credentials saved by the old single-account
      // keys so users who upgraded keep their remembered login.
      final legacyEmail = await _secureStorage.read(key: _rememberEmailKey);
      final legacyPassword = await _secureStorage.read(key: _rememberPasswordKey);
      if (legacyEmail != null &&
          legacyPassword != null &&
          !accounts.containsKey(legacyEmail)) {
        accounts[legacyEmail] = legacyPassword;
      }
    } catch (_) {
      return {};
    }
    return accounts;
  }

  /// Convenience for callers that only want the most recently saved account.
  Future<RememberedCredentials?> loadRememberedCredentials() async {
    final accounts = await loadRememberedAccounts();
    if (accounts.isEmpty) return null;
    final email = accounts.keys.first;
    return RememberedCredentials(email: email, password: accounts[email]!);
  }

  Future<void> saveRememberedCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final accounts = await loadRememberedAccounts();
      accounts[email] = password;
      await _secureStorage.write(
        key: _rememberAccountsKey,
        value: jsonEncode(accounts),
      );
    } catch (_) {
      // Never block sign-in if the keychain is unavailable.
    }
  }

  /// Forgets a single saved account (used when "Remember me" is unchecked or
  /// the user removes an account from the saved list).
  Future<void> removeRememberedAccount(String email) async {
    try {
      final accounts = await loadRememberedAccounts();
      accounts.remove(email);
      await _secureStorage.write(
        key: _rememberAccountsKey,
        value: jsonEncode(accounts),
      );

      // Clean up the legacy keys if they pointed at this account.
      if (await _secureStorage.read(key: _rememberEmailKey) == email) {
        await _secureStorage.delete(key: _rememberEmailKey);
        await _secureStorage.delete(key: _rememberPasswordKey);
      }
    } catch (_) {}
  }

  Future<void> clearRememberedCredentials() async {
    try {
      await _secureStorage.delete(key: _rememberAccountsKey);
      await _secureStorage.delete(key: _rememberEmailKey);
      await _secureStorage.delete(key: _rememberPasswordKey);
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final previousUserId = user.value?.id;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    token.value = null;
    user.value = null;

    if (previousUserId != null && previousUserId.isNotEmpty) {
      _push.remove(previousUserId).ignore();
    }
    _firebaseAuth.signOut().ignore();
  }

  Future<void> _submitAuthRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      isLoading.value = true;
      await _handleAuthResponse(await request());
    } finally {
      isLoading.value = false;
    }
  }

  /// Persists the `{ token, user }` payload shared by every sign-in path
  /// (login, register, Google). Throws a user-facing message on any problem.
  Future<void> _handleAuthResponse(Response<dynamic> response) async {
    if (!response.isOk) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected server response');
    }

    final authToken = body['token']?.toString();
    final userJson = body['user'];

    if (authToken == null || userJson is! Map<String, dynamic>) {
      throw Exception('Authentication response is missing token or user');
    }

    await _saveSession(authToken, AuthUser.fromJson(userJson));
    _storeDevelopmentOtp(body);
  }

  Future<void> _saveSession(String? authToken, AuthUser authUser) async {
    final prefs = await SharedPreferences.getInstance();

    if (authToken != null && authToken.isNotEmpty) {
      await prefs.setString(_tokenKey, authToken);
      token.value = authToken;
    }

    await prefs.setString(_userKey, jsonEncode(authUser.toJson()));
    user.value = authUser;

    _syncFirebaseSession(authUser);
  }

  void _syncFirebaseSession(AuthUser authUser) {
    // Fire-and-forget: get a Firebase identity (shadow account), then register
    // this device for push. Failures never block the real backend session.
    _firebaseAuth
        .ensureSignedIn(authUser.email)
        .then((_) => _push.register(authUser.id))
        .ignore();
  }

  Future<void> _saveUserFromResponse(dynamic body) async {
    if (body is! Map<String, dynamic> ||
        body['user'] is! Map<String, dynamic>) {
      throw Exception('User response is missing profile data');
    }

    await _saveSession(token.value, AuthUser.fromJson(body['user']));
  }

  String _requireToken() {
    final currentToken = token.value;

    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('Please sign in again');
    }

    return currentToken;
  }

  void _storeDevelopmentOtp(dynamic body) {
    if (body is Map<String, dynamic> && body['otp'] != null) {
      lastDevelopmentOtp.value = body['otp'].toString();
    }
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((error) => error.toString()).join('\n');
      }

      final message = body['message'];
      if (message != null) return message.toString();
    }

    return 'Unable to connect to Findora. Please try again.';
  }
}
