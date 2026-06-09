import 'package:flutter/material.dart';

class ManageCommunicationScreen extends StatefulWidget {
  const ManageCommunicationScreen({super.key});

  @override
  State<ManageCommunicationScreen> createState() =>
      _ManageCommunicationScreenState();
}

class _ManageCommunicationScreenState extends State<ManageCommunicationScreen> {
  final List<Map<String, dynamic>> chats = [
    {
      "user1": "Ali Raza",
      "user2": "Sara Khan",
      "lastMessage": "Is this your wallet?",
      "active": true,
    },
    {
      "user1": "Hassan Ahmed",
      "user2": "Lost & Found Desk",
      "lastMessage": "Claim under review",
      "active": false,
    },
    {
      "user1": "Usman Tariq",
      "user2": "Ayesha Noor",
      "lastMessage": "Thanks for returning my item!",
      "active": true,
    },
  ];

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

      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

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
                            "${chat["user1"]} ↔ ${chat["user2"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xff17324D),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            chat["lastMessage"],
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
                        color: chat["active"]
                            ? Colors.green.withOpacity(.12)
                            : Colors.red.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        chat["active"] ? "Active" : "Disabled",
                        style: TextStyle(
                          color: chat["active"] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Chat muted")),
                          );
                        },
                        child: const Text("Mute"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: chat["active"]
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            chat["active"] = !chat["active"];
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                chat["active"]
                                    ? "Chat Enabled"
                                    : "Chat Disabled",
                              ),
                            ),
                          );
                        },
                        child: Text(chat["active"] ? "Disable" : "Enable"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
