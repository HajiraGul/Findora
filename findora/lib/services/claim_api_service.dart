import 'package:get/get.dart';

import '../config/app_config.dart';

class ClaimApiService extends GetConnect {
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

  Future<Response<dynamic>> submitClaim({
    required String token,
    required Map<String, dynamic> data,
  }) {
    return post('/claims', data, headers: _auth(token));
  }

  Future<Response<dynamic>> getMyClaims({
    required String token,
    String? status,
  }) {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    return get('/claims/me', headers: _auth(token), query: query);
  }

  Future<Response<dynamic>> getClaim({
    required String token,
    required String id,
  }) {
    return get('/claims/$id', headers: _auth(token));
  }

  Future<Response<dynamic>> approveClaim({
    required String token,
    required String id,
    String? adminNote,
  }) {
    final body = adminNote != null ? {'adminNote': adminNote} : <String, dynamic>{};
    return patch('/claims/$id/approve', body, headers: _auth(token));
  }

  Future<Response<dynamic>> getAllClaims({
    required String token,
    String? status,
    int page = 1,
    int limit = 50,
  }) {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null && status.isNotEmpty) query['status'] = status;
    return get('/claims', headers: _auth(token), query: query);
  }

  Future<Response<dynamic>> rejectClaim({
    required String token,
    required String id,
    String? adminNote,
  }) {
    final body = adminNote != null ? {'adminNote': adminNote} : <String, dynamic>{};
    return patch('/claims/$id/reject', body, headers: _auth(token));
  }
}
