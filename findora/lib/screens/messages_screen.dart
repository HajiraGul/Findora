import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

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
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search_rounded),
                  hintText: "Search conversations...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                children: [
                  _chatTile(
                    context,
                    name: "Ali Raza",
                    message: "I think the wallet belongs to you.",
                    time: "2m",
                    online: true,
                    unread: 2,
                  ),
                  _chatTile(
                    context,
                    name: "Sara Khan",
                    message: "Can you verify the lost phone details?",
                    time: "12m",
                    online: false,
                    unread: 1,
                  ),
                  _chatTile(
                    context,
                    name: "Lost & Found Desk",
                    message: "Your claim request is under review.",
                    time: "1h",
                    online: true,
                    unread: 0,
                  ),
                  _chatTile(
                    context,
                    name: "Hassan Ahmed",
                    message: "Thanks for confirming ownership.",
                    time: "Yesterday",
                    online: false,
                    unread: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(
    BuildContext context, {
    required String name,
    required String message,
    required String time,
    required bool online,
    required int unread,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(userName: name)),
        );
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
            Stack(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xffDCEFFF),
                  child: Icon(Icons.person, size: 28, color: Color(0xff0A5EB0)),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    height: 13,
                    width: 13,
                    decoration: BoxDecoration(
                      color: online ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
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
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xff0A84FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
