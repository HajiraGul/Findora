import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,

      child: Scaffold(
        backgroundColor: const Color(0xffF5FAFF),

        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,

          // ✅ Added this
          systemOverlayStyle: SystemUiOverlayStyle.dark,

          title: const Text(
            "My Posts",
            style: TextStyle(
              color: Color(0xff17324D),
              fontWeight: FontWeight.w700,
            ),
          ),

          iconTheme: const IconThemeData(color: Color(0xff17324D)),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),

            child: ListView(
              children: [
                _postCard(
                  title: "Black Wallet",
                  location: "Near CS Department",
                  status: "Lost",
                  color: Colors.red,
                  icon: Icons.account_balance_wallet_rounded,
                ),

                const SizedBox(height: 18),

                _postCard(
                  title: "iPhone 13",
                  location: "Library Block",
                  status: "Found",
                  color: Colors.green,
                  icon: Icons.phone_iphone_rounded,
                ),

                const SizedBox(height: 18),

                _postCard(
                  title: "Student ID Card",
                  location: "Cafeteria Area",
                  status: "Resolved",
                  color: Colors.blue,
                  icon: Icons.badge_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _postCard({
    required String title,
    required String location,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xffF2F9FF)],
        ),

        borderRadius: BorderRadius.circular(28),

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
          Container(
            height: 62,
            width: 62,

            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),

            child: Icon(icon, color: color, size: 30),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff17324D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(location, style: const TextStyle(color: Colors.black54)),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
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
          ),

          PopupMenuButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            itemBuilder: (context) => const [
              PopupMenuItem(value: "edit", child: Text("Edit")),

              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }
}
