import 'package:flutter/material.dart';
import 'claim_details_screen.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  String selectedFilter = "All";

  final List<Map<String, dynamic>> claims = [
    {
      "title": "Black Wallet",
      "claimId": "#CLM-1021",
      "date": "12 May 2026",
      "status": "Pending",
      "statusColor": Colors.orange,
      "progress": .35,
    },
    {
      "title": "Student ID Card",
      "claimId": "#CLM-1018",
      "date": "08 May 2026",
      "status": "Approved",
      "statusColor": Colors.green,
      "progress": 1.0,
    },
    {
      "title": "Mobile Phone",
      "claimId": "#CLM-1012",
      "date": "01 May 2026",
      "status": "Rejected",
      "statusColor": Colors.red,
      "progress": .70,
    },
    {
      "title": "Laptop Bag",
      "claimId": "#CLM-1009",
      "date": "28 April 2026",
      "status": "Pending",
      "statusColor": Colors.orange,
      "progress": .45,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ Filter Logic
    final filteredClaims = selectedFilter == "All"
        ? claims
        : claims.where((claim) => claim["status"] == selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),

      // ✅ FIX ADDED
      extendBodyBehindAppBar: false,

      appBar: AppBar(
        elevation: 0,

        // ✅ FIX ADDED
        backgroundColor: const Color(0xffF5FAFF),

        surfaceTintColor: Colors.transparent,

        title: const Text(
          "My Claims",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),

        iconTheme: const IconThemeData(color: Color(0xff17324D)),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Filter Chips
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),

                          child: ClaimCard(
                            title: claim["title"],
                            claimId: claim["claimId"],
                            date: claim["date"],
                            status: claim["status"],
                            statusColor: claim["statusColor"],
                            progress: claim["progress"],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Filter Chip Widget
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
}

class ClaimCard extends StatelessWidget {
  final String title;
  final String claimId;
  final String date;
  final String status;
  final Color statusColor;
  final double progress;

  const ClaimCard({
    super.key,
    required this.title,
    required this.claimId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xffF3FAFF)],
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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff17324D),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      claimId,

                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13.5,
                      ),
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
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            "Submitted on $date",

            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(30),

            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xff0A84FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClaimDetailsScreen(
                      title: title,
                      claimId: claimId,
                      date: date,
                      status: status,
                      statusColor: statusColor,
                    ),
                  ),
                );
              },

              child: const Text(
                "View Details",

                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
