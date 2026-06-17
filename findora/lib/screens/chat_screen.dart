import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/item_controller.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
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
    required bool isMe,
    required String time,
  }) {
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

  Widget _messageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
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
