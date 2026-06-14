import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import 'match_suggestions_screen.dart';
import 'my_claims_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _controller.fetch();
  }

  void _onTap(AppNotification n) {
    _controller.markRead(n.id);
    final itemId = n.itemId;
    if (n.type == 'match' && itemId != null && itemId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchSuggestionsScreen(itemId: itemId),
        ),
      );
    } else if (n.type == 'claim') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyClaimsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0A3D62),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A3D62),
          ),
        ),
        actions: [
          Obx(() {
            final hasUnread = _controller.unreadCount.value > 0;
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton(
              onPressed: _controller.markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            );
          }),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = _controller.notifications;
        if (items.isEmpty) return _emptyState();
        return RefreshIndicator(
          onRefresh: _controller.fetch,
          child: ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _notificationCard(items[i]),
          ),
        );
      }),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.notifications_none_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'You\'re all caught up',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Match alerts and claim updates will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _notificationCard(AppNotification n) {
    final visual = _visualFor(n.type);
    final tappable =
        (n.type == 'match' && (n.itemId?.isNotEmpty ?? false)) ||
        n.type == 'claim';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: tappable ? () => _onTap(n) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: n.isRead ? const Color(0xFFEFF2F6) : const Color(0xFFDBEAFE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: visual.$2.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(visual.$1, color: visual.$2, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                n.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n.timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (tappable)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1)),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _visualFor(String type) {
    switch (type) {
      case 'match':
        return (Icons.auto_awesome_rounded, const Color(0xFF16A34A));
      case 'claim':
        return (Icons.verified_rounded, const Color(0xFF2563EB));
      case 'account':
        return (Icons.shield_outlined, const Color(0xFFD97706));
      default:
        return (Icons.campaign_rounded, const Color(0xFF7C3AED));
    }
  }
}
