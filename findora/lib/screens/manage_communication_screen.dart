import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';

class ManageCommunicationScreen extends StatefulWidget {
  const ManageCommunicationScreen({super.key});

  @override
  State<ManageCommunicationScreen> createState() =>
      _ManageCommunicationScreenState();
}

class _ManageCommunicationScreenState extends State<ManageCommunicationScreen> {
  late final ChatController _chatController;
  final Set<String> _updating = {};

  @override
  void initState() {
    super.initState();
    _chatController = Get.find<ChatController>();
    _chatController.fetchAllChats();
  }

  Future<void> _toggleChat(ChatConversation chat) async {
    setState(() => _updating.add(chat.id));
    final ok = await _chatController.setChatEnabled(chat.id, !chat.enabled);
    if (!mounted) return;
    setState(() => _updating.remove(chat.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (chat.enabled ? 'Chat Disabled' : 'Chat Enabled')
              : 'Failed to update chat',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff17324D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Communication",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (_chatController.isLoadingAdminChats.value &&
            _chatController.adminChats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = _chatController.adminChats;
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "No chats yet.\n\nA chat is created when you approve a claim.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _chatController.fetchAllChats,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            itemCount: chats.length,
            itemBuilder: (context, index) => _chatCard(chats[index]),
          ),
        );
      }),
    );
  }

  Widget _chatCard(ChatConversation chat) {
    final isUpdating = _updating.contains(chat.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xffF4FAFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xffDCEFFF),
                child: Icon(Icons.chat, color: Color(0xff0A5EB0)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${chat.posterName} ↔ ${chat.claimantName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xff17324D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      chat.lastMessageText ??
                          'Item: ${chat.itemTitle} — no messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chat.enabled
                      ? Colors.green.withOpacity(.12)
                      : Colors.red.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chat.enabled ? "Active" : "Disabled",
                  style: TextStyle(
                    color: chat.enabled ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: chat.enabled ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isUpdating ? null : () => _toggleChat(chat),
              child: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(chat.enabled ? "Disable Chat" : "Enable Chat"),
            ),
          ),
        ],
      ),
    );
  }
}
