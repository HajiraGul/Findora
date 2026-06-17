import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/chat_controller.dart';
import '../controllers/item_controller.dart';
import '../models/chat_model.dart';
import '../utils/picked_image_data.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  late final ChatController _chatController;
  int _renderedMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatController = Get.find<ChatController>();
    // Defer to after the first frame: openConversation mutates reactive state
    // (activeChat / messages / isLoadingMessages), which must not happen during
    // the build phase, or GetX throws "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatController.openConversation(widget.conversation);
    });
  }

  @override
  void dispose() {
    _chatController.closeConversation();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    final error = await _chatController.sendMessage(text);

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  // Lets the user attach a photo to the conversation. Sending an image is a
  // separate flow from the text field, so typing a message is never affected.
  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xff0A5EB0)),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xff0A5EB0)),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (file == null) return;

      final picked = await PickedImageData.fromXFile(file);
      final error = await _chatController.sendImage(picked);
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final text = msg.contains('permission') || msg.contains('denied')
          ? 'Permission denied. Please allow access in Settings.'
          : 'Unable to pick image';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  // Only the item's poster confirms the handover. Resolving the item closes
  // every chat tied to it on the backend; the live chat stream then flips this
  // screen to the closed banner, so we don't disable anything by hand here.
  Future<void> _markAsClaimed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as claimed?'),
        content: Text(
          'This marks "${widget.conversation.itemTitle}" as resolved and closes '
          'this conversation. You can still read the messages afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark as claimed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await Get.find<ItemController>()
        .resolveItem(widget.conversation.itemId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Marked as claimed. This chat is now closed.'
              : 'Could not update the post. Please try again.',
        ),
      ),
    );
  }

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherName =
        widget.conversation.otherPartyName(_chatController.currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xff17324D),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xffDCEFFF),
              child: Icon(Icons.person, color: Color(0xff0A5EB0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff17324D),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.conversation.itemTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            final chat = _chatController.activeChat.value;
            final isPoster =
                widget.conversation.posterId == _chatController.currentUserId;
            // Show the handover action only to the poster, and only while the
            // conversation is still open.
            if (!isPoster || chat == null || !chat.enabled) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Mark as claimed',
              icon: const Icon(Icons.task_alt_rounded, color: Color(0xff0A5EB0)),
              onPressed: _markAsClaimed,
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value &&
                  _chatController.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final msgs = _chatController.messages;
              if (msgs.isEmpty) {
                return const Center(
                  child: Text(
                    'Say hello — this chat was approved by the admin.',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              if (msgs.length != _renderedMessageCount) {
                _renderedMessageCount = msgs.length;
                _scrollToBottomAfterBuild();
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(18),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];
                  return _messageBubble(
                    text: msg.text,
                    imageUrl: msg.imageUrl,
                    isMe: msg.senderId == _chatController.currentUserId,
                    time: msg.formattedTime,
                  );
                },
              );
            }),
          ),
          Obx(() {
            final chat = _chatController.activeChat.value;
            final disabled = chat != null && !chat.enabled;
            return disabled
                ? _disabledBanner(chat.closedReason == 'resolved')
                : _messageInput();
          }),
        ],
      ),
    );
  }

  Widget _disabledBanner(bool resolved) {
    final color = resolved ? const Color(0xff0A5EB0) : Colors.red;
    final icon = resolved ? Icons.task_alt_rounded : Icons.lock_outline_rounded;
    final text = resolved
        ? 'This item has been marked as claimed. The chat is now closed.'
        : 'This chat has been disabled by the admin.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble({
    required String text,
    String? imageUrl,
    required bool isMe,
    required String time,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasText = text.trim().isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe
                ? [const Color(0xff0A84FF), const Color(0xff0066D6)]
                : [Colors.white, const Color(0xffEEF7FF)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasImage) _bubbleImage(imageUrl),
            if (hasImage && hasText) const SizedBox(height: 8),
            if (hasText)
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xff17324D),
                ),
              ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleImage(String imageUrl) {
    return GestureDetector(
      onTap: () => _openImageViewer(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: 220,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 220,
              height: 160,
              alignment: Alignment.center,
              color: Colors.black12,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            width: 220,
            height: 120,
            alignment: Alignment.center,
            color: Colors.black12,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // Full-screen, pinch-to-zoom viewer for a tapped chat image.
  void _openImageViewer(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Obx(() {
            final uploading = _chatController.isUploadingImage.value;
            return IconButton(
              onPressed: uploading ? null : _showImageSourceSheet,
              tooltip: 'Send a photo',
              icon: uploading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xff0A5EB0),
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0xff0A5EB0)),
            );
          }),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xffF4F8FC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final sending = _chatController.isSending.value;
            return GestureDetector(
              onTap: sending ? null : sendMessage,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            );
          }),
        ],
      ),
    );
  }
}
