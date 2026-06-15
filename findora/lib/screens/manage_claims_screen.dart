import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../models/claim_model.dart';
import 'claim_review_screen.dart';

class ManageClaimsScreen extends StatefulWidget {
  final bool embedded;
  const ManageClaimsScreen({super.key, this.embedded = false});

  @override
  State<ManageClaimsScreen> createState() => _ManageClaimsScreenState();
}

class _ManageClaimsScreenState extends State<ManageClaimsScreen> {
  late final AdminController _ctrl;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _ctrl.fetchAllClaims();
  }

  Color _statusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved: return Colors.green;
      case ClaimStatus.rejected: return Colors.red;
      case ClaimStatus.pending:  return Colors.orange;
    }
  }

  String _statusLabel(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved: return 'Approved';
      case ClaimStatus.rejected: return 'Rejected';
      case ClaimStatus.pending:  return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff17324D)),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Manage Claims',
          style: TextStyle(color: Color(0xff17324D), fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Rejected']
                  .map(_filterChip)
                  .toList(),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_ctrl.claimsLoading.value && _ctrl.allClaims.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _selectedFilter == 'All'
                  ? _ctrl.allClaims.toList()
                  : _ctrl.allClaims
                      .where((c) => _statusLabel(c.status) == _selectedFilter)
                      .toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No claims found', style: TextStyle(fontSize: 16, color: Colors.black54)),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _ctrl.fetchAllClaims(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _claimCard(context, filtered[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text) {
    final selected = _selectedFilter == text;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = text),
        child: Chip(
          label: Text(text),
          backgroundColor: selected ? const Color(0xff0A84FF) : Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _claimCard(BuildContext context, ClaimModel claim) {
    final color = _statusColor(claim.status);
    final label = _statusLabel(claim.status);
    final shortId = '#CLM-${claim.id.substring(0, 6).toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.white, Color(0xffF3FAFF)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xffDCEFFF),
                child: Icon(Icons.verified_user_rounded, color: Color(0xff0A5EB0)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.itemTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xff17324D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$shortId • by ${claim.claimantName ?? claim.claimantId}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () async {
                final refreshed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => ClaimReviewScreen(claim: claim)),
                );
                if (refreshed == true) _ctrl.fetchAllClaims();
              },
              child: const Text('Review Claim'),
            ),
          ),
        ],
      ),
    );
  }
}
