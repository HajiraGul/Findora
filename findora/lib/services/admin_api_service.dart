import 'package:get/get.dart';

import '../config/app_config.dart';

class AdminApiService extends GetConnect {
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

  Future<Response<dynamic>> getStats(String token) {
    return get('/admin/stats', headers: _auth(token));
  }

  Future<Response<dynamic>> getUsers({
    required String token,
    String? q,
    int page = 1,
    int limit = 50,
  }) {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (q != null && q.isNotEmpty) query['q'] = q;
    return get('/users', headers: _auth(token), query: query);
  }

  Future<Response<dynamic>> banUser({
    required String token,
    required String userId,
  }) {
    return patch('/users/$userId/ban', {}, headers: _auth(token));
  }

  Future<Response<dynamic>> unbanUser({
    required String token,
    required String userId,
  }) {
    return patch('/users/$userId/unban', {}, headers: _auth(token));
  }

  Future<Response<dynamic>> deleteUser({
    required String token,
    required String userId,
  }) {
    return delete('/users/$userId', headers: _auth(token));
  }
}
