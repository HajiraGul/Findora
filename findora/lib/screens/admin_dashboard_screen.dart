import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import 'manage_claims_screen.dart';
import 'manage_communication_screen.dart';
import 'manage_posts_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminController _ctrl;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _ctrl.fetchStats();
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
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Color(0xff17324D), fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Color(0xff17324D)),
            onPressed: _logoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings_rounded, size: 34, color: Color(0xff0A5EB0)),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Administration Panel',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage posts, claims, users and communications',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stat cards
            Obx(() {
              final s = _ctrl.stats.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _statCard('${s.pendingClaims}', 'Pending Claims')),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('${s.activePosts}', 'Active Posts')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _statCard('${s.totalUsers}', 'Users')),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('${s.totalClaims}', 'Total Claims')),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 28),

            _navTile(context, Icons.inventory_2_outlined, 'Manage Posts', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePostsScreen()));
            }),
            _navTile(context, Icons.verified_user_outlined, 'Manage Claims', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageClaimsScreen()));
            }),
            _navTile(context, Icons.people_alt_outlined, 'Manage Users', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()));
            }),
            _navTile(context, Icons.chat_outlined, 'Manage Communication', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCommunicationScreen()));
            }),
          ],
        ),
      ),
    );
  }

  void _logoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _authController.logout();
              if (!mounted) return;
              Navigator.pop(context);
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xff0A5EB0))),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.white, Color(0xffF4FAFF)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xffEAF5FF),
              child: Icon(icon, color: const Color(0xff0A5EB0)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xff17324D))),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
