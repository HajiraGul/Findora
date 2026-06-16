import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
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
  // Project palette
  static const Color _primary = Color(0xFF2563EB);
  static const Color _ink = Color(0xff17324D);
  static const Color _bg = Color(0xffF5FAFF);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AdminController _ctrl;
  final AuthController _authController = Get.find<AuthController>();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _ctrl.fetchStats();
    _ctrl.fetchAllItems();
    _ctrl.fetchAllClaims();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const ManagePostsScreen(embedded: true),
          const ManageClaimsScreen(embedded: true),
          const ManageUsersScreen(embedded: true),
          const ManageCommunicationScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard tab (overview)
  // ---------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 22),

            // Administration panel card (kept the same)
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
                    child: Icon(Icons.admin_panel_settings_rounded,
                        size: 34, color: Color(0xff0A5EB0)),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Administration Panel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
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

            const SizedBox(height: 26),
            const Text(
              'Overview',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(height: 14),

            // Stat cards (kept the same counts)
            Obx(() {
              final s = _ctrl.stats.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('${s.pendingClaims}',
                              'Pending Claims', Icons.hourglass_bottom_rounded)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('${s.activePosts}', 'Active Posts',
                              Icons.inventory_2_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('${s.totalUsers}', 'Users',
                              Icons.people_alt_rounded)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('${s.totalClaims}', 'Total Claims',
                              Icons.verified_user_rounded)),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 28),
            const Text(
              'Analytics',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(height: 14),

            _buildPostsBreakdown(),
            const SizedBox(height: 14),
            _buildClaimsBreakdown(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header with user profile + welcome back
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Obx(() {
      final user = _authController.user.value;
      final name = (user?.fullName.trim().isNotEmpty ?? false)
          ? user!.fullName
          : 'Administrator';
      final avatarUrl = user?.avatarUrl ?? '';
      final initials = _initials(name);

      return InkWell(
        onTap: _openDrawer,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_primary, Color(0xFF1D4ED8)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xffEAF2FF),
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          initials,
                          style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _circleIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Menu',
                onTap: _openDrawer,
              ),
            ],
          ),
        ),
      );
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Widget _circleIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: _ink, size: 20),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Posts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user_rounded),
              label: 'Claims',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers / reusable widgets
  // ---------------------------------------------------------------------------
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

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0A5EB0))),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Analytics charts
  // ---------------------------------------------------------------------------
  Widget _buildPostsBreakdown() {
    return Obx(() {
      final items = _ctrl.allItems;
      final lost = items.where((i) => i.status == ItemStatus.lost).length;
      final found = items.where((i) => i.status == ItemStatus.found).length;
      final max = [lost, found, 1].reduce((a, b) => a > b ? a : b);

      return _chartCard(
        title: 'Posts Breakdown',
        trailing: '${items.length} total',
        child: items.isEmpty
            ? _emptyChart('No posts yet')
            : Column(
                children: [
                  _barRow('Lost', lost, max, const Color(0xffEF4444)),
                  const SizedBox(height: 14),
                  _barRow('Found', found, max, const Color(0xff16A34A)),
                ],
              ),
      );
    });
  }

  Widget _buildClaimsBreakdown() {
    return Obx(() {
      final claims = _ctrl.allClaims;
      final pending =
          claims.where((c) => c.status == ClaimStatus.pending).length;
      final approved =
          claims.where((c) => c.status == ClaimStatus.approved).length;
      final rejected =
          claims.where((c) => c.status == ClaimStatus.rejected).length;
      final max = [pending, approved, rejected, 1].reduce((a, b) => a > b ? a : b);

      return _chartCard(
        title: 'Claims by Status',
        trailing: '${claims.length} total',
        child: claims.isEmpty
            ? _emptyChart('No claims yet')
            : Column(
                children: [
                  _barRow('Pending', pending, max, const Color(0xffF59E0B)),
                  const SizedBox(height: 14),
                  _barRow('Approved', approved, max, const Color(0xff16A34A)),
                  const SizedBox(height: 14),
                  _barRow('Rejected', rejected, max, const Color(0xffEF4444)),
                ],
              ),
      );
    });
  }

  Widget _chartCard({
    required String title,
    required String trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              Text(trailing,
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _barRow(String label, int count, int max, Color color) {
    final fraction = max == 0 ? 0.0 : count / max;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xffEEF3FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 26,
          child: Text('$count',
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
        ),
      ],
    );
  }

  Widget _emptyChart(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(message,
          style: const TextStyle(color: Colors.black45, fontSize: 13)),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar (drawer) with profile + logout
  // ---------------------------------------------------------------------------
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _bg,
      child: Column(
        children: [
          _buildDrawerHeader(),
          const SizedBox(height: 8),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _drawerItem(Icons.inventory_2_rounded, 'Manage Posts', 1),
          _drawerItem(Icons.verified_user_rounded, 'Manage Claims', 2),
          _drawerItem(Icons.people_alt_rounded, 'Manage Users', 3),
          const Spacer(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: Color(0xffEF4444)),
            title: const Text('Logout',
                style: TextStyle(
                    color: Color(0xffEF4444),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            onTap: () {
              _scaffoldKey.currentState?.closeDrawer();
              _logoutDialog();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Obx(() {
      final user = _authController.user.value;
      final name = (user?.fullName.trim().isNotEmpty ?? false)
          ? user!.fullName
          : 'Administrator';
      final email = user?.email ?? '';
      final avatarUrl = user?.avatarUrl ?? '';

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            _initials(name),
                            style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 22),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13)),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Administrator',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffEAF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: selected ? _primary : const Color(0xff64748B)),
        title: Text(label,
            style: TextStyle(
                color: selected ? _primary : _ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        onTap: () {
          _scaffoldKey.currentState?.closeDrawer();
          _onNavTap(index);
        },
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
