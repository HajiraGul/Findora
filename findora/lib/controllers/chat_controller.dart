import 'dart:async';

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/chat_model.dart';
import '../services/chat_api_service.dart';
import '../services/firestore_chat_service.dart';

class ChatController extends GetxController {
  final ChatApiService _api;
  final FirestoreChatService _firestore;

  ChatController(this._api, this._firestore);

  String get _token => Get.find<AuthController>().token.value ?? '';
  String get currentUserId => Get.find<AuthController>().user.value?.id ?? '';
  String get _currentUserName =>
      Get.find<AuthController>().user.value?.fullName ?? '';

  final conversations = <ChatConversation>[].obs;
  final isLoadingChats = false.obs;

  final activeChat = Rxn<ChatConversation>();
  final messages = <ChatMessage>[].obs;
  final isLoadingMessages = false.obs;
  final isSending = false.obs;

  final adminChats = <ChatConversation>[].obs;
  final isLoadingAdminChats = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _chatsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<Map<String, dynamic>?>? _activeChatSub;

  @override
  void onClose() {
    _chatsSub?.cancel();
    _messagesSub?.cancel();
    _activeChatSub?.cancel();
    super.onClose();
  }

  // ── My conversations (live Firestore stream) ──────────────────

  Future<void> fetchMyChats() async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    isLoadingChats.value = true;
    _chatsSub?.cancel();
    _chatsSub = _firestore.watchMyChats(uid).listen(
      (rows) {
        conversations.value = rows.map(ChatConversation.fromJson).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        isLoadingChats.value = false;
      },
      onError: (_) => isLoadingChats.value = false,
    );
  }

  /// One-shot lookup of the conversation unlocked for an approved claim.
  /// Returns null when the admin has not allowed chat for this claim yet.
  Future<ChatConversation?> openChatByClaimId(String claimId) async {
    final data = await _firestore.getChat(claimId);
    if (data == null) return null;
    return ChatConversation.fromJson(data);
  }

  // ── Active conversation (live Firestore streams) ──────────────

  void openConversation(ChatConversation chat) {
    _messagesSub?.cancel();
    _activeChatSub?.cancel();
    activeChat.value = chat;
    messages.clear();
    isLoadingMessages.value = true;

    _messagesSub = _firestore.watchMessages(chat.id).listen(
      (rows) {
        messages.value = rows.map(ChatMessage.fromJson).toList();
        isLoadingMessages.value = false;
      },
      onError: (_) => isLoadingMessages.value = false,
    );

    // Reflect admin enable/disable while the screen is open.
    _activeChatSub = _firestore.watchChat(chat.id).listen((data) {
      if (data == null) return;
      final fresh = ChatConversation.fromJson(data);
      if (activeChat.value?.id == fresh.id) activeChat.value = fresh;
    });
  }

  void closeConversation() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _activeChatSub?.cancel();
    _activeChatSub = null;
    activeChat.value = null;
    messages.clear();
  }

  Future<String?> sendMessage(String text) async {
    final chat = activeChat.value;
    final trimmed = text.trim();
    final uid = currentUserId;
    if (chat == null || trimmed.isEmpty || uid.isEmpty) return null;
    if (!(activeChat.value?.enabled ?? false)) {
      return 'This chat has been disabled by the admin';
    }

    try {
      isSending.value = true;
      await _firestore.sendMessage(
        chatId: chat.id,
        senderId: uid,
        senderName: _currentUserName,
        text: trimmed,
      );
      // The new message arrives through the live messages stream.
      return null;
    } catch (_) {
      return 'Unable to send message. Please try again.';
    } finally {
      isSending.value = false;
    }
  }

  // ── Admin moderation (stays on the backend REST API) ──────────

  Future<void> fetchAllChats() async {
    if (_token.isEmpty) return;
    try {
      isLoadingAdminChats.value = true;
      final response = await _api.getAllChats(token: _token);
      if (response.isOk && response.body is Map) {
        adminChats.value = _parseChats(response.body['chats']);
      }
    } catch (_) {
      // keep previous state on network error
    } finally {
      isLoadingAdminChats.value = false;
    }
  }

  Future<bool> setChatEnabled(String chatId, bool enabled) async {
    if (_token.isEmpty) return false;
    try {
      final response = await _api.setChatStatus(
        token: _token,
        chatId: chatId,
        enabled: enabled,
      );
      if (response.isOk && response.body is Map) {
        final json = response.body['chat'];
        if (json is Map<String, dynamic>) {
          final updated = ChatConversation.fromJson(json);
          final idx = adminChats.indexWhere((c) => c.id == chatId);
          if (idx != -1) adminChats[idx] = updated;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> unlockChatForClaim(String claimId) async {
    if (_token.isEmpty) return 'Please sign in again';
    try {
      final response = await _api.unlockChatForClaim(
        token: _token,
        claimId: claimId,
      );
      if (response.isOk) return null;
      return extractError(response.body);
    } catch (_) {
      return 'Unable to unlock chat. Please try again.';
    }
  }

  List<ChatConversation> _parseChats(dynamic list) {
    return ((list as List?) ?? [])
        .map((j) => ChatConversation.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  String extractError(dynamic body) {
    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('\n');
      }
      final message = body['message'];
      if (message != null) return message.toString();
    }
    return 'Something went wrong. Please try again.';
  }
}
