import 'package:flutter/material.dart';

class PostReviewScreen extends StatelessWidget {
  const PostReviewScreen({super.key});

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
          "Post Review",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Post Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xffEAF5FF),
              ),
              child: const Icon(
                Icons.image,
                size: 60,
                color: Color(0xff0A5EB0),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Title
            const Text(
              "Black Wallet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff17324D),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Lost near CS Department • Posted by Ali Raza",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            // 🔹 Description Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                "This wallet contains important documents including student ID and cards. If found please return.",
                style: TextStyle(height: 1.6, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Extra Info
            _infoRow("Category", "Personal Item"),
            _infoRow("Date Posted", "12 May 2026"),
            _infoRow("Status", "Pending Review"),

            const SizedBox(height: 30),

            // 🔹 Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post Approved")),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Approve"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post Rejected")),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff17324D),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
