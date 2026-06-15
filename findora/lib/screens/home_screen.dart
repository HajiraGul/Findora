import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/item_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/item_model.dart';
import '../routes/app_routes.dart';
import '../utils/picked_image_data.dart';
import '../widgets/item_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/bottom_nav_bar.dart';
import 'map_view_screen.dart';
import 'items_near_me_screen.dart';
import 'search_filter_screen.dart';
import 'item_detail_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'post_item_screen.dart';
import 'best_matches_screen.dart';
import 'my_activity_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'account_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final ItemController _itemController;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'Electronics', 'icon': Icons.devices_rounded},
    {'label': 'Documents', 'icon': Icons.description_outlined},
    {'label': 'Keys', 'icon': Icons.key_rounded},
    {'label': 'Bags & Wallets', 'icon': Icons.shopping_bag_outlined},
    {'label': 'Clothing', 'icon': Icons.checkroom_outlined},
    {'label': 'Accessories', 'icon': Icons.watch_outlined},
    {'label': 'Books', 'icon': Icons.menu_book_rounded},
    {'label': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _itemController = Get.find<ItemController>();
    _itemController.fetchItems();
    if (!widget.isGuest) {
      Get.find<NotificationController>().fetch();
    }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = 'All';
            break;
          case 1:
            _selectedStatus = 'Lost';
            break;
          case 2:
            _selectedStatus = 'Found';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ItemModel> get _filteredItems {
    final myId = Get.find<AuthController>().user.value?.id;
    return _itemController.items.where((item) {
      // Hide the user's own posts from the dashboard feed — they manage those
      // under Profile > My Posts, so the feed only shows other people's items.
      if (!widget.isGuest &&
          myId != null &&
          myId.isNotEmpty &&
          item.postedById == myId) {
        return false;
      }
      final matchCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchStatus =
          _selectedStatus == 'All' ||
          (item.status == ItemStatus.lost && _selectedStatus == 'Lost') ||
          (item.status == ItemStatus.found && _selectedStatus == 'Found');
      final matchSearch =
          _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchStatus && matchSearch;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapViewScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ItemsNearMeScreen()),
      );
    } else if (index == 3) {
      if (widget.isGuest) {
        _showGuestBlock('view your best matches');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BestMatchesScreen()),
        );
      }
    } else if (index == 4) {
      if (widget.isGuest) {
        _showGuestBlock('view your posts and claims');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyActivityScreen()),
        );
      }
    } else {
      setState(() => _navIndex = index);
    }
  }

  void _showGuestBlock(String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestBlockSheet(
        action: action,
        onSignIn: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: widget.isGuest ? null : _buildSidebar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabBar(),
          _buildCategoryBar(),
          Expanded(child: _buildItemList()),
        ],
      ),
      floatingActionButton: widget.isGuest ? null : _buildFAB(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        isGuest: widget.isGuest,
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile avatar → opens the sidebar drawer ──────────
              _buildProfileAvatar(),
              const SizedBox(width: 12),
              // ── Left: location + greeting ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'IIU, Islamabad',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isGuest ? 'Welcome' : 'Welcome back',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    widget.isGuest
                        ? const Text(
                            'Browse Items',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          )
                        : Obx(
                            () => Text(
                              _displayName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Right: notification bell + messages ────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _headerBell(),
                  const SizedBox(width: 6),
                  _headerIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      if (widget.isGuest) {
                        _showGuestBlock('view your messages');
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessagesScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bell with an unread-count badge. The badge counts ALL unread notifications
  // (matches now, claim/account events later), so it stays correct as more
  // notification types are added.
  Widget _headerBell() {
    return GestureDetector(
      onTap: () {
        if (widget.isGuest) {
          _showGuestBlock('view notifications');
        } else {
          final notif = Get.find<NotificationController>();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ).then((_) => notif.fetchUnreadCount());
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          if (!widget.isGuest)
            Positioned(
              right: -3,
              top: -3,
              child: Obx(() {
                final count =
                    Get.find<NotificationController>().unreadCount.value;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  // Signed-in user's display name for the header. Reactive (called inside an
  // Obx) so it updates the moment the profile loads.
  String _displayName() {
    final name = Get.find<AuthController>().user.value?.fullName.trim() ?? '';
    return name.isEmpty ? 'Findora User' : name;
  }

  // Circular avatar in the header. Tapping it opens the sidebar (guests are
  // nudged to sign in instead, since they have no profile).
  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () {
        if (widget.isGuest) {
          _showGuestBlock('view your profile');
        } else {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        child: Obx(() {
          final avatar = imageProviderFromStoredValue(
            Get.find<AuthController>().user.value?.avatarUrl ?? '',
          );
          return CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            backgroundImage: avatar,
            child: avatar == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  )
                : null,
          );
        }),
      ),
    );
  }

  // ─── Sidebar (Drawer) ───────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFFF5FAFF),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _sidebarItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  onTap: () => _openFromDrawer(const ProfileScreen()),
                ),
                _sidebarItem(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Account Settings',
                  onTap: () => _openFromDrawer(const AccountSettingsScreen()),
                ),
                _sidebarItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  onTap: () => _openFromDrawer(const MessagesScreen()),
                ),
                _sidebarItem(
                  icon: Icons.lock_rounded,
                  label: 'Privacy & Security',
                  onTap: () => _openFromDrawer(const PrivacySecurityScreen()),
                ),
                _sidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () => _openFromDrawer(const SettingsScreen()),
                ),
                _sidebarItem(
                  icon: Icons.help_rounded,
                  label: 'Help & Support',
                  onTap: () => _openFromDrawer(const HelpSupportScreen()),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildSidebarLogout(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Obx(() {
      final user = Get.find<AuthController>().user.value;
      final name = (user?.fullName.trim().isNotEmpty ?? false)
          ? user!.fullName
          : 'Findora User';
      final email = user?.email ?? '';
      final avatar = imageProviderFromStoredValue(user?.avatarUrl ?? '');

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
                      color: Colors.white.withOpacity(0.7),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: avatar,
                    child: avatar == null
                        ? Text(
                            _initials(name),
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
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
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
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

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: const Color(0xFF64748B)),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF17324D),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSidebarLogout() {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: _confirmLogout,
    );
  }

  // Close the drawer first, then push the destination so the drawer animation
  // doesn't linger behind the new screen.
  void _openFromDrawer(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _confirmLogout() {
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
              await Get.find<AuthController>().logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
        ),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Search items, locations...',
                  style: TextStyle(fontSize: 14, color: Color(0xFFBEC5CF)),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.all(4),
          tabs: const [
            Tab(text: 'All Items'),
            Tab(text: '🔴 Lost'),
            Tab(text: '🟢 Found'),
          ],
        ),
      ),
    );
  }

  // ─── Category Bar ──────────────────────────────────────────────────────────

  Widget _buildCategoryBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            return CategoryChip(
              label: cat['label'],
              icon: cat['icon'],
              isSelected: _selectedCategory == cat['label'],
              onTap: () => setState(() => _selectedCategory = cat['label']),
            );
          },
        ),
      ),
    );
  }

  // ─── Item List ─────────────────────────────────────────────────────────────

  Widget _buildItemList() {
    return Obx(() {
      if (_itemController.isLoading.value && _itemController.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = _filteredItems;
      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No items found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 6),
              Text('Try changing the filters', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => _itemController.fetchItems(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          itemCount: items.length,
          itemBuilder: (_, i) => ItemCard(
            item: items[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(item: items[i], isGuest: widget.isGuest),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostItemScreen()),
        );
      },
      backgroundColor: const Color(0xFF2563EB),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Post Item',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ─── Guest Block Bottom Sheet ──────────────────────────────────────────────────

class _GuestBlockSheet extends StatelessWidget {
  final String action;
  final VoidCallback onSignIn;

  const _GuestBlockSheet({required this.action, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFF2563EB),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign In Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need an account to $action.\nJoin Findora for free today.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue as guest',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
