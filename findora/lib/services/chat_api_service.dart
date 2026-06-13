import 'package:get/get.dart';

import '../config/app_config.dart';

class ChatApiService extends GetConnect {
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

  Future<Response<dynamic>> getMyChats({required String token}) {
    return get('/chats', headers: _auth(token));
  }

  Future<Response<dynamic>> getChat({
    required String token,
    required String chatId,
  }) {
    return get('/chats/$chatId', headers: _auth(token));
  }

  Future<Response<dynamic>> getMessages({
    required String token,
    required String chatId,
    int? afterMs,
  }) {
    final query = <String, String>{};
    if (afterMs != null && afterMs > 0) query['after'] = '$afterMs';
    return get('/chats/$chatId/messages', headers: _auth(token), query: query);
  }

  Future<Response<dynamic>> sendMessage({
    required String token,
    required String chatId,
    required String text,
  }) {
    return post('/chats/$chatId/messages', {'text': text},
        headers: _auth(token));
  }

  /// Ensures the chat for an approved claim exists (creating it if needed) and
  /// returns it. Callable by the claimant or item poster.
  Future<Response<dynamic>> openChatForClaim({
    required String token,
    required String claimId,
  }) {
    return post('/chats/claim/$claimId', {}, headers: _auth(token));
  }

  // ── Admin ─────────────────────────────────────────────────────

  Future<Response<dynamic>> getAllChats({required String token}) {
    return get('/admin/chats', headers: _auth(token));
  }

  Future<Response<dynamic>> setChatStatus({
    required String token,
    required String chatId,
    required bool enabled,
  }) {
    return patch('/admin/chats/$chatId/status', {'enabled': enabled},
        headers: _auth(token));
  }

  Future<Response<dynamic>> unlockChatForClaim({
    required String token,
    required String claimId,
  }) {
    return post('/admin/chats/claim/$claimId', {}, headers: _auth(token));
  }
}
