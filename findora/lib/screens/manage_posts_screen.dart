import 'package:flutter/material.dart';
import 'post_review_screen.dart';

class ManagePostsScreen extends StatelessWidget {
  const ManagePostsScreen({super.key});

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
          "Manage Posts",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _postCard(
            context,
            title: "Black Wallet",
            location: "CS Department",
            user: "Ali Raza",
            status: "Pending Review",
            color: Colors.orange,
          ),
          _postCard(
            context,
            title: "Student ID Card",
            location: "Library",
            user: "Sara Khan",
            status: "Approved",
            color: Colors.green,
          ),
          _postCard(
            context,
            title: "iPhone 13",
            location: "Cafeteria",
            user: "Hassan Ahmed",
            status: "Flagged",
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _postCard(
    BuildContext context, {
    required String title,
    required String location,
    required String user,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xffF3FAFF)],
        ),
        borderRadius: BorderRadius.circular(26),
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
                radius: 28,
                backgroundColor: Color(0xffDCEFFF),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xff0A5EB0),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Color(0xff17324D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$location • by $user",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xff0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PostReviewScreen(),
                      ),
                    );
                  },
                  child: const Text("Review"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post deleted")),
                    );
                  },
                  child: const Text("Delete"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
