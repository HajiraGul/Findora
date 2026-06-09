import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';

class AuthApiService extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 20);
    httpClient.defaultContentType = 'application/json';
    httpClient.addRequestModifier<dynamic>((request) {
      if (kDebugMode) {
        debugPrint('API REQUEST: ${request.method} ${request.url}');
      }

      return request;
    });
    httpClient.addResponseModifier<dynamic>((request, response) {
      if (kDebugMode) {
        debugPrint(
          'API RESPONSE: ${response.statusCode} ${request.method} ${request.url}',
        );
        debugPrint(
          'API BODY: ${_truncateForLog(response.bodyString ?? response.body)}',
        );
      }

      return response;
    });
    super.onInit();
  }

  String _truncateForLog(Object? value) {
    final text = value?.toString() ?? '';
    if (text.length <= 1200) return text;

    return '${text.substring(0, 1200)}... [truncated ${text.length} chars]';
  }

  Future<Response<dynamic>> login({
    required String email,
    required String password,
  }) {
    return post('/auth/login', {'email': email, 'password': password});
  }

  Future<Response<dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String cityOrUniversity,
    required String password,
  }) {
    return post('/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'cityOrUniversity': cityOrUniversity,
      'password': password,
    });
  }

  Future<Response<dynamic>> logout(String token) {
    return post(
      '/auth/logout',
      {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Response<dynamic>> forgotPassword({required String email}) {
    return post('/auth/forgot-password', {'email': email});
  }

  Future<Response<dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) {
    return post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'password': password,
    });
  }

  Future<Response<dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return post('/auth/verify-otp', {'email': email, 'otp': otp});
  }

  Future<Response<dynamic>> resendOtp({required String email}) {
    return post('/auth/resend-otp', {'email': email});
  }

  Future<Response<dynamic>> getProfile(String token) {
    return get('/users/me', headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response<dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String email,
    required String phone,
    required String cityOrUniversity,
  }) {
    return patch(
      '/users/me',
      {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'cityOrUniversity': cityOrUniversity,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Response<dynamic>> updateAvatar({
    required String token,
    required String avatarUrl,
  }) {
    return patch(
      '/users/me/avatar',
      {'avatarUrl': avatarUrl},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Response<dynamic>> updatePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) {
    return patch(
      '/users/me/password',
      {'currentPassword': currentPassword, 'newPassword': newPassword},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Response<dynamic>> updatePreferences({
    required String token,
    bool? notifications,
    bool? darkMode,
    bool? twoFactor,
    bool? biometric,
  }) {
    return patch(
      '/users/me/preferences',
      {
        if (notifications != null) 'notifications': notifications,
        if (darkMode != null) 'darkMode': darkMode,
        if (twoFactor != null) 'twoFactor': twoFactor,
        if (biometric != null) 'biometric': biometric,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Response<dynamic>> deleteAccount(String token) {
    return delete('/users/me', headers: {'Authorization': 'Bearer $token'});
  }
}
