import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/claim_controller.dart';
import '../models/claim_model.dart';

class ClaimStatusScreen extends StatefulWidget {
  const ClaimStatusScreen({super.key});

  @override
  State<ClaimStatusScreen> createState() => _ClaimStatusScreenState();
}

class _ClaimStatusScreenState extends State<ClaimStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ClaimController _ctrl;
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _ctrl = Get.find<ClaimController>();
    _ctrl.fetchMyClaims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ClaimModel> get _filteredClaims {
    final all = _ctrl.claims;
    if (_selectedTab == 'All') return all.toList();
    if (_selectedTab == 'Pending') {
      return all.where((c) => c.status == ClaimStatus.pending).toList();
    }
    if (_selectedTab == 'Approved') {
      return all.where((c) => c.status == ClaimStatus.approved).toList();
    }
    return all.where((c) => c.status == ClaimStatus.rejected).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Obx(() => _buildStatsRow()),
          _buildTabBar(),
          Expanded(child: Obx(() => _buildClaimList())),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Claims',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Track all your claim requests',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final all = _ctrl.claims;
    final pending = all.where((c) => c.status == ClaimStatus.pending).length;
    final approved = all.where((c) => c.status == ClaimStatus.approved).length;
    final rejected = all.where((c) => c.status == ClaimStatus.rejected).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statCard(
            all.length.toString(),
            'Total',
            Icons.list_alt_rounded,
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 10),
          _statCard(
            pending.toString(),
            'Pending',
            Icons.schedule_rounded,
            const Color(0xFFD97706),
            const Color(0xFFFEF3C7),
          ),
          const SizedBox(width: 10),
          _statCard(
            approved.toString(),
            'Approved',
            Icons.check_circle_outline,
            const Color(0xFF16A34A),
            const Color(0xFFDCFCE7),
          ),
          const SizedBox(width: 10),
          _statCard(
            rejected.toString(),
            'Rejected',
            Icons.cancel_outlined,
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String count,
    String label,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['All', 'Pending', 'Approved', 'Rejected'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (i) => setState(() => _selectedTab = tabs[i]),
          indicator: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.all(4),
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
    );
  }

  Widget _buildClaimList() {
    if (_ctrl.isLoading.value && _ctrl.claims.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final claims = _filteredClaims;
    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No claims here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: claims.length,
      itemBuilder: (_, i) => _buildClaimCard(claims[i]),
    );
  }

  Widget _buildClaimCard(ClaimModel claim) {
    final statusConfig = _statusConfig(claim.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusConfig['bg'] as Color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusConfig['icon'] as IconData,
                    color: statusConfig['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.itemTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        claim.itemCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (statusConfig['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusConfig['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusConfig['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusConfig['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeline(claim),
                if (claim.adminNote != null) ...[
                  const SizedBox(height: 14),
                  _buildAdminNote(claim),
                ],
                const SizedBox(height: 14),
                _buildAnswerPreview(claim),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted ${claim.submittedAt}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showClaimDetail(context, claim),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ClaimModel claim) {
    final steps = ['Submitted', 'Under Review', 'Decision Made'];
    final activeStep = claim.status == ClaimStatus.pending ? 1 : 2;

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isActive = i <= activeStep;
        final isLast = i == steps.length - 1;
        final statusColor = claim.status == ClaimStatus.approved
            ? const Color(0xFF16A34A)
            : claim.status == ClaimStatus.rejected
            ? const Color(0xFFEF4444)
            : const Color(0xFF2563EB);

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (i == activeStep && i == 2
                                  ? statusColor
                                  : const Color(0xFF2563EB))
                            : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        border: isActive
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        i == 0
                            ? Icons.send_rounded
                            : i == 1
                            ? Icons.manage_search_rounded
                            : (claim.status == ClaimStatus.approved
                                  ? Icons.check_rounded
                                  : claim.status == ClaimStatus.rejected
                                  ? Icons.close_rounded
                                  : Icons.hourglass_empty_rounded),
                        color: isActive
                            ? Colors.white
                            : const Color(0xFFCBD5E1),
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? const Color(0xFF374151)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: i < activeStep
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdminNote(ClaimModel claim) {
    final isApproved = claim.status == ClaimStatus.approved;
    final color = isApproved
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);
    final bg = isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isApproved ? Icons.check_circle_outline : Icons.info_outline,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Note',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  claim.adminNote!,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerPreview(ClaimModel claim) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your answers',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          ...claim.answers
              .take(2)
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 5,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF374151),
                            ),
                            children: [
                              TextSpan(
                                text: '${a.question.split('?').first}? ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: a.answer),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (claim.answers.length > 2)
            Text(
              '+${claim.answers.length - 2} more answers',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  void _showClaimDetail(BuildContext context, ClaimModel claim) {
    final statusConfig = _statusConfig(claim.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Claim Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (statusConfig['bg'] as Color),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusConfig['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusConfig['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Claim ID: #${claim.id.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Answers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...claim.answers.map(
                      (a) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.question,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.answer,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (claim.adminNote != null) ...[
                      const SizedBox(height: 8),
                      _buildAdminNote(claim),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _statusConfig(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.pending:
        return {
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
          'icon': Icons.schedule_rounded,
          'label': 'Pending',
        };
      case ClaimStatus.approved:
        return {
          'color': const Color(0xFF16A34A),
          'bg': const Color(0xFFF0FDF4),
          'icon': Icons.check_circle_outline_rounded,
          'label': 'Approved',
        };
      case ClaimStatus.rejected:
        return {
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEF2F2),
          'icon': Icons.cancel_outlined,
          'label': 'Rejected',
        };
    }
  }
}
