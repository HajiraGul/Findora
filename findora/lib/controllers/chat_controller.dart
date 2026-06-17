import 'dart:async';

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/chat_model.dart';
import '../services/chat_api_service.dart';
import '../services/firestore_chat_service.dart';
import '../utils/picked_image_data.dart';

/// An image the user just picked that is still uploading. Rendered optimistically
/// in the conversation (with a loader) until the real message arrives over the
/// live Firestore stream.
class PendingImage {
  final String id;
  final PickedImageData image;
  const PendingImage({required this.id, required this.image});
}

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
  final isUploadingImage = false.obs;
  // Images still uploading, shown optimistically at the end of the thread.
  final pendingImages = <PendingImage>[].obs;
  int _pendingSeq = 0;

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

  /// Opens the conversation for an approved claim. Asks the backend to ensure
  /// the chat exists (idempotent) — this self-heals claims that were approved
  /// before chat was configured, instead of leaving the user stuck. Falls back
  /// to a direct Firestore read if the backend call fails.
  Future<ChatConversation?> openChatByClaimId(String claimId) async {
    if (_token.isNotEmpty) {
      try {
        final response =
            await _api.openChatForClaim(token: _token, claimId: claimId);
        if (response.isOk && response.body is Map) {
          final chat = (response.body as Map)['chat'];
          if (chat is Map) {
            return ChatConversation.fromJson(Map<String, dynamic>.from(chat));
          }
        }
      } catch (_) {
        // Fall through to a direct Firestore read below.
      }
    }

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
    pendingImages.clear();
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
    pendingImages.clear();
  }

  Future<String?> sendMessage(String text, {String? imageUrl}) async {
    final chat = activeChat.value;
    final trimmed = text.trim();
    final uid = currentUserId;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (chat == null || uid.isEmpty) return null;
    if (trimmed.isEmpty && !hasImage) return null;
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
        imageUrl: imageUrl,
      );
      // The new message arrives through the live messages stream.
      return null;
    } catch (e) {
      // Surface the real cause so the failure is diagnosable instead of a
      // generic "try again".
      // ignore: avoid_print
      print('[chat] sendMessage failed: $e');
      final detail = e.toString().toLowerCase();
      if (detail.contains('not configured') ||
          detail.contains('no firebase') ||
          detail.contains('no-app')) {
        return 'Chat unavailable: Firebase isn\'t set up on this device.';
      }
      if (detail.contains('permission-denied') ||
          detail.contains('permission_denied')) {
        return 'Not allowed to send — you\'re not signed in to chat. Restart the app.';
      }
      return 'Unable to send: $e';
    } finally {
      isSending.value = false;
    }
  }

  /// Uploads a picked image to the backend (Cloudinary) and then appends an
  /// image message to the conversation. Text messages are unaffected — this is
  /// a separate path that only runs when the user attaches a photo.
  Future<String?> sendImage(PickedImageData picked) async {
    final chat = activeChat.value;
    final uid = currentUserId;
    if (chat == null || uid.isEmpty) return null;
    if (!(activeChat.value?.enabled ?? false)) {
      return 'This chat has been disabled by the admin';
    }
    if (_token.isEmpty) return 'Please sign in again to send photos.';

    // Show the image right away with a loader; it's removed once the real
    // message lands (or the upload fails).
    final pending = PendingImage(id: 'pending_${_pendingSeq++}', image: picked);
    pendingImages.add(pending);

    try {
      isUploadingImage.value = true;
      final response = await _api.uploadImage(
        token: _token,
        chatId: chat.id,
        dataUrl: picked.dataUrl,
      );

      if (!response.isOk) {
        return extractError(response.body);
      }
      final url = response.body is Map
          ? (response.body as Map)['url']?.toString() ?? ''
          : '';
      if (url.isEmpty) {
        return 'Image upload failed. Please try again.';
      }

      return sendMessage('', imageUrl: url);
    } catch (e) {
      // ignore: avoid_print
      print('[chat] sendImage failed: $e');
      return 'Unable to send photo: $e';
    } finally {
      isUploadingImage.value = false;
      pendingImages.remove(pending);
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
