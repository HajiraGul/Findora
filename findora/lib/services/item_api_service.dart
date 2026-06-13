import 'package:get/get.dart';

import '../config/app_config.dart';

class ItemApiService extends GetConnect {
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

  Future<Response<dynamic>> getItems({
    String? category,
    String? status,
    String? q,
    int page = 1,
    int limit = 20,
  }) {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (category != null && category != 'All') query['category'] = category;
    if (status != null && status != 'All') query['status'] = status.toLowerCase();
    if (q != null && q.isNotEmpty) query['q'] = q;
    return get('/items', query: query);
  }

  Future<Response<dynamic>> getMyItems(String token) {
    return get('/items/me', headers: _auth(token));
  }

  Future<Response<dynamic>> getNearbyItems({
    required double lat,
    required double lng,
    required double radiusKm,
    String sort = 'distance',
  }) {
    return get('/items/nearby', query: {
      'lat': '$lat',
      'lng': '$lng',
      'radiusKm': '$radiusKm',
      'sort': sort,
    });
  }

  Future<Response<dynamic>> getItem(String id) {
    return get('/items/$id');
  }

  Future<Response<dynamic>> createItem({
    required String token,
    required Map<String, dynamic> data,
  }) {
    return post('/items', data, headers: _auth(token));
  }

  Future<Response<dynamic>> updateItem({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) {
    return patch('/items/$id', data, headers: _auth(token));
  }

  Future<Response<dynamic>> deleteItem({
    required String token,
    required String id,
  }) {
    return delete('/items/$id', headers: _auth(token));
  }

  Future<Response<dynamic>> resolveItem({
    required String token,
    required String id,
  }) {
    return post('/items/$id/resolve', {}, headers: _auth(token));
  }

  Future<Response<dynamic>> getMatches({
    required String token,
    required String id,
  }) {
    return get('/items/$id/matches', headers: _auth(token));
  }

  Future<Response<dynamic>> notifyMatch({
    required String token,
    required String id,
    required String matchItemId,
  }) {
    return post(
      '/items/$id/notify-match',
      {'matchItemId': matchItemId},
      headers: _auth(token),
    );
  }
}
