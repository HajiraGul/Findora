import 'package:flutter/material.dart';
import '../widgets/premium_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: "Notifications"),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            _notificationCard(
              context,
              icon: Icons.check_circle_rounded,
              iconColor: Colors.green,
              title: "New Match Found",
              subtitle:
                  "A black wallet reported near CS Department matches your post.",
              time: "2 min ago",
              unread: true,
            ),
            const SizedBox(height: 16),
            _notificationCard(
              context,
              icon: Icons.verified_rounded,
              iconColor: Colors.blue,
              title: "Claim Approved",
              subtitle:
                  "Your submitted ownership proof has been approved successfully.",
              time: "20 min ago",
              unread: true,
            ),
            const SizedBox(height: 16),
            _notificationCard(
              context,
              icon: Icons.info_rounded,
              iconColor: Colors.orange,
              title: "Reminder",
              subtitle:
                  "Keep notifications enabled to receive instant match alerts.",
              time: "1 hour ago",
              unread: false,
            ),
            const SizedBox(height: 16),
            _notificationCard(
              context,
              icon: Icons.campaign_rounded,
              iconColor: Colors.purple,
              title: "Campus Announcement",
              subtitle:
                  "Lost items desk timings updated for the upcoming semester.",
              time: "Yesterday",
              unread: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool unread,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        _showNotificationDetail(context, title, subtitle, time);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xffF2F9FF)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff17324D),
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          height: 10,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xff0A84FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(height: 1.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(time, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showNotificationDetail(
    BuildContext context,
    String title,
    String subtitle,
    String time,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff17324D),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: const TextStyle(height: 1.6, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Text(time, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: const Color(0xff0A84FF),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Mark as Read"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }
}
