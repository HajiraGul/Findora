import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String userName;

  const ChatScreen({super.key, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  final List<Map<String, dynamic>> messages = [
    {
      "text": "Hi, I found an item that may belong to you.",
      "isMe": false,
      "time": "10:24 AM",
    },
    {
      "text": "Really? Can you share details please?",
      "isMe": true,
      "time": "10:25 AM",
    },
    {
      "text": "It is a black wallet with a university ID card.",
      "isMe": false,
      "time": "10:26 AM",
    },
  ];

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "text": messageController.text.trim(),
        "isMe": true,
        "time": "Now",
      });
    });

    messageController.clear();
  }

  Future<void> pickGalleryImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image selected: ${image.name}")));
    }
  }

  Future<void> pickCameraImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Captured: ${image.name}")));
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File selected: ${result.files.single.name}")),
      );
    }
  }

  void showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Wrap(
            children: [
              _optionTile(Icons.photo, "Gallery", pickGalleryImage),
              _optionTile(Icons.camera_alt, "Camera", pickCameraImage),
              _optionTile(Icons.insert_drive_file, "File", pickFile),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xffEAF5FF),
        child: Icon(icon, color: const Color(0xff0A5EB0)),
      ),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Stack(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xffDCEFFF),
                  child: Icon(Icons.person, color: Color(0xff0A5EB0)),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Color(0xff17324D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  "Secure Verified Chat",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _messageBubble(
                  text: msg["text"],
                  isMe: msg["isMe"],
                  time: msg["time"],
                );
              },
            ),
          ),
          _messageInput(),
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
          GestureDetector(
            onTap: showAttachmentOptions,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xffEAF5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.attach_file_rounded,
                color: Color(0xff0A5EB0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xffF4F8FC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
