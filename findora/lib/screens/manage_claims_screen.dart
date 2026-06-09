import 'package:flutter/material.dart';
import 'claim_review_screen.dart';

class ManageClaimsScreen extends StatefulWidget {
  const ManageClaimsScreen({super.key});

  @override
  State<ManageClaimsScreen> createState() => _ManageClaimsScreenState();
}

class _ManageClaimsScreenState extends State<ManageClaimsScreen> {
  String selectedFilter = "All";

  final List<Map<String, dynamic>> claims = [
    {
      "title": "Black Wallet",
      "claimId": "#CLM-1021",
      "user": "Ali Raza",
      "status": "Pending",
      "color": Colors.orange,
    },
    {
      "title": "Student ID Card",
      "claimId": "#CLM-1018",
      "user": "Sara Khan",
      "status": "Approved",
      "color": Colors.green,
    },
    {
      "title": "Mobile Phone",
      "claimId": "#CLM-1012",
      "user": "Hassan Ahmed",
      "status": "Rejected",
      "color": Colors.red,
    },
    {
      "title": "Laptop Bag",
      "claimId": "#CLM-1009",
      "user": "Ahmed Ali",
      "status": "Pending",
      "color": Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ Filtered claims
    final filteredClaims = selectedFilter == "All"
        ? claims
        : claims.where((claim) => claim["status"] == selectedFilter).toList();

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
          "Manage Claims",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Column(
        children: [
          // 🔹 Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

            child: Row(
              children: [
                _filterChip("All"),
                _filterChip("Pending"),
                _filterChip("Approved"),
                _filterChip("Rejected"),
              ],
            ),
          ),

          // 🔹 Claims List
          Expanded(
            child: filteredClaims.isEmpty
                ? const Center(
                    child: Text(
                      "No claims found",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: filteredClaims.length,

                    itemBuilder: (context, index) {
                      final claim = filteredClaims[index];

                      return _claimCard(
                        context,
                        title: claim["title"],
                        claimId: claim["claimId"],
                        user: claim["user"],
                        status: claim["status"],
                        color: claim["color"],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text) {
    final bool selected = selectedFilter == text;

    return Container(
      margin: const EdgeInsets.only(right: 10),

      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = text;
          });
        },

        child: Chip(
          label: Text(text),

          backgroundColor: selected ? const Color(0xff0A84FF) : Colors.white,

          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _claimCard(
    BuildContext context, {
    required String title,
    required String claimId,
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
                  Icons.verified_user_rounded,
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
                      "$claimId • by $user",
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

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A84FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClaimReviewScreen()),
                );
              },

              child: const Text("Review Claim"),
            ),
          ),
        ],
      ),
    );
  }
}
