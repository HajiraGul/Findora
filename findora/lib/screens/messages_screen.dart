import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final ChatController _chatController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chatController = Get.find<ChatController>();
    _chatController.fetchMyChats();
  }

  List<ChatConversation> get _filtered {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _chatController.conversations.toList();
    return _chatController.conversations.where((c) {
      final other =
          c.otherPartyName(_chatController.currentUserId).toLowerCase();
      return other.contains(query) ||
          c.itemTitle.toLowerCase().contains(query);
    }).toList();
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search_rounded),
                  hintText: "Search conversations...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Obx(() {
                if (_chatController.isLoadingChats.value &&
                    _chatController.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = _filtered;
                if (chats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "No conversations yet.\n\nChat unlocks when the admin approves a claim on an item.",
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
                  onRefresh: _chatController.fetchMyChats,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: chats.length,
                    itemBuilder: (context, index) =>
                        _chatTile(context, chats[index]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(BuildContext context, ChatConversation chat) {
    final name = chat.otherPartyName(_chatController.currentUserId);
    final lastMessage = chat.lastMessageText ??
        'Chat unlocked for "${chat.itemTitle}" — say hello!';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversation: chat)),
        );
        _chatController.fetchMyChats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xffDCEFFF),
              child: Icon(Icons.person, size: 28, color: Color(0xff0A5EB0)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff17324D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.timeAgo,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (!chat.enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Disabled",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
