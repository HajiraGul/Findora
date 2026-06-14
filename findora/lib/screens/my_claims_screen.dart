import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/claim_controller.dart';
import '../models/claim_model.dart';
import 'chat_screen.dart';
import 'claim_details_screen.dart';

class MyClaimsScreen extends StatefulWidget {
  /// When embedded (e.g. inside the "My Items" tabbed screen) the screen renders
  /// just its filter chips + list body, without its own Scaffold/AppBar.
  final bool embedded;
  const MyClaimsScreen({super.key, this.embedded = false});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  String selectedFilter = 'All';
  late final ClaimController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ClaimController>();
    _ctrl.fetchMyClaims();
  }

  Color _statusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.rejected:
        return Colors.red;
      case ClaimStatus.pending:
        return Colors.orange;
    }
  }

  double _statusProgress(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return 1.0;
      case ClaimStatus.rejected:
        return 0.7;
      case ClaimStatus.pending:
        return 0.35;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();

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

      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final all = _ctrl.claims;
      final filteredClaims = selectedFilter == 'All'
          ? all.toList()
          : all
              .where((c) => c.status.name.capitalize == selectedFilter)
              .toList();

      return Column(
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
            child: _ctrl.isLoading.value && filteredClaims.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredClaims.isEmpty
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
                              title: claim.itemTitle,
                              claimId: '#CLM-${claim.id.substring(0, 6).toUpperCase()}',
                              date: claim.formattedDate,
                              status: claim.status.name[0].toUpperCase() +
                                  claim.status.name.substring(1),
                              statusColor: _statusColor(claim.status),
                              progress: _statusProgress(claim.status),
                              onChat: claim.status == ClaimStatus.approved
                                  ? () => _openChat(claim)
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    });
  }

  Future<void> _openChat(ClaimModel claim) async {
    final chat =
        await Get.find<ChatController>().openChatByClaimId(claim.id);
    if (!mounted) return;

    if (chat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chat is not available yet. Please wait for the admin to unlock it.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: chat)),
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
  final VoidCallback? onChat;

  const ClaimCard({
    super.key,
    required this.title,
    required this.claimId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.progress,
    this.onChat,
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

          if (onChat != null) ...[
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff0A84FF),
                  side: const BorderSide(color: Color(0xff0A84FF)),
                  padding: const EdgeInsets.symmetric(vertical: 15),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),

                label: const Text(
                  "Chat",

                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
