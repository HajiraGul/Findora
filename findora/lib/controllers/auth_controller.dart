import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../services/auth_api_service.dart';

class AuthController extends GetxController {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final AuthApiService _authApiService;

  AuthController(this._authApiService);

  final isLoading = false.obs;
  final resetLoading = false.obs;
  final otpLoading = false.obs;
  final profileLoading = false.obs;
  final lastDevelopmentOtp = RxnString();
  final token = RxnString();
  final user = Rxn<AuthUser>();

  bool get isAuthenticated => token.value != null && token.value!.isNotEmpty;
  bool get isAdmin => user.value?.role == 'admin';

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedUser = prefs.getString(_userKey);

    if (storedToken == null || storedUser == null) return;

    token.value = storedToken;
    user.value = AuthUser.fromJson(
      jsonDecode(storedUser) as Map<String, dynamic>,
    );
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

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String cityOrUniversity,
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

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    token.value = null;
    user.value = null;
  }

  Future<void> _submitAuthRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      isLoading.value = true;
      final response = await request();

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

      final authUser = AuthUser.fromJson(userJson);
      await _saveSession(authToken, authUser);
      _storeDevelopmentOtp(body);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveSession(String? authToken, AuthUser authUser) async {
    final prefs = await SharedPreferences.getInstance();

    if (authToken != null && authToken.isNotEmpty) {
      await prefs.setString(_tokenKey, authToken);
      token.value = authToken;
    }

    await prefs.setString(_userKey, jsonEncode(authUser.toJson()));
    user.value = authUser;
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
