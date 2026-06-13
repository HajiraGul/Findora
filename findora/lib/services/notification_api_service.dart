import 'package:get/get.dart';

import '../config/app_config.dart';

class NotificationApiService extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);
    httpClient.defaultContentType = 'application/json';
    super.onInit();
  }

  Map<String, String> _auth(String token) => {
        'Authorization': 'Bearer $token',
      };

  Future<Response<dynamic>> getNotifications(String token, {int page = 1, int limit = 30}) {
    return get(
      '/notifications',
      query: {'page': '$page', 'limit': '$limit'},
      headers: _auth(token),
    );
  }

  Future<Response<dynamic>> getUnreadCount(String token) {
    return get('/notifications/unread-count', headers: _auth(token));
  }

  Future<Response<dynamic>> markRead(String token, String id) {
    return patch('/notifications/$id/read', {}, headers: _auth(token));
  }

  Future<Response<dynamic>> markAllRead(String token) {
    return patch('/notifications/read-all', {}, headers: _auth(token));
  }
}
