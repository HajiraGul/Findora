import 'package:flutter/material.dart';
import 'guest_item_detail_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class LostItem {
  final String id;
  final String title;
  final String category;
  final String location;
  final String timeAgo;
  final String description;
  final IconData icon;
  final Color categoryColor;
  final bool isResolved;
  final double lat;
  final double lng;

  const LostItem({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.timeAgo,
    required this.description,
    required this.icon,
    required this.categoryColor,
    this.isResolved = false,
    required this.lat,
    required this.lng,
  });
}

final List<LostItem> kDemoItems = [
  LostItem(
    id: '1',
    title: 'Black Leather Wallet',
    category: 'Accessories',
    location: 'F-10 Markaz, Islamabad',
    timeAgo: '2 hours ago',
    description:
        'Lost my black leather wallet near F-10 Markaz. Contains NIC card, bank cards and some cash. Please contact if found.',
    icon: Icons.account_balance_wallet_outlined,
    categoryColor: Color(0xFF7C3AED),
    lat: 33.6844,
    lng: 73.0479,
  ),
  LostItem(
    id: '2',
    title: 'iPhone 14 Pro (Black)',
    category: 'Electronics',
    location: 'Centaurus Mall, Islamabad',
    timeAgo: '5 hours ago',
    description:
        'Lost iPhone 14 Pro in black colour at Centaurus Mall food court. Has a transparent case with stickers.',
    icon: Icons.phone_iphone_rounded,
    categoryColor: Color(0xFF0891B2),
    lat: 33.7215,
    lng: 73.0433,
  ),
  LostItem(
    id: '3',
    title: 'Blue Backpack',
    category: 'Bags',
    location: 'NUST University, H-12',
    timeAgo: '1 day ago',
    description:
        'Navy blue backpack with laptop inside left in the cafeteria. Has name tag "Ali Khan" stitched on it.',
    icon: Icons.backpack_outlined,
    categoryColor: Color(0xFF059669),
    lat: 33.6426,
    lng: 72.9912,
    isResolved: true,
  ),
  LostItem(
    id: '4',
    title: 'Car Keys (Toyota)',
    category: 'Keys',
    location: 'Jinnah Super Market, F-7',
    timeAgo: '3 hours ago',
    description:
        'Toyota Corolla car keys with a red keychain lost near Jinnah Super Market parking area.',
    icon: Icons.car_rental_outlined,
    categoryColor: Color(0xFFDC2626),
    lat: 33.7156,
    lng: 73.0551,
  ),
  LostItem(
    id: '5',
    title: 'Gold Bracelet',
    category: 'Jewelry',
    location: 'Giga Mall, DHA Phase 2',
    timeAgo: '6 hours ago',
    description:
        'Gold bracelet with a heart charm. Lost somewhere in Giga Mall. Sentimental value, reward offered.',
    icon: Icons.diamond_outlined,
    categoryColor: Color(0xFFD97706),
    lat: 33.5357,
    lng: 73.1157,
  ),
  LostItem(
    id: '6',
    title: 'Student ID Card',
    category: 'Documents',
    location: 'COMSATS University, Park Road',
    timeAgo: '2 days ago',
    description:
        'COMSATS University student ID card lost on campus. Belongs to Fatima Malik, SP21-BCS-001.',
    icon: Icons.badge_outlined,
    categoryColor: Color(0xFF2563EB),
    lat: 33.5357,
    lng: 73.1157,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showMapView = false;
  late AnimationController _fabAnimController;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Accessories',
    'Bags',
    'Keys',
    'Jewelry',
    'Documents',
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  List<LostItem> get _filteredItems {
    return kDemoItems.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showGuestPrompt(String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestPromptSheet(action: action),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildViewToggle(),
          Expanded(child: _showMapView ? _buildMapView() : _buildListView()),
        ],
      ),
      floatingActionButton: _buildGuestFAB(),
    );
  }

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
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              // Logo
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Findora',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Lost & Found Community',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Guest badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Guest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sign in button
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.login_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search lost items, locations...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final isSelected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text(
            '${_filteredItems.length} items found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _ToggleBtn(
                  icon: Icons.list_rounded,
                  active: !_showMapView,
                  onTap: () => setState(() => _showMapView = false),
                ),
                _ToggleBtn(
                  icon: Icons.map_outlined,
                  active: _showMapView,
                  onTap: () => setState(() => _showMapView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No items found',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search or category',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemCard(
        item: items[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuestItemDetailScreen(item: items[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    // Simplified map placeholder with pins
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE8F0F7),
          child: CustomPaint(
            painter: _MapGridPainter(),
            child: Stack(
              children: [
                // Map label
                const Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Islamabad, Pakistan',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Pins
                ..._filteredItems.asMap().entries.map((e) {
                  final positions = [
                    const Offset(0.45, 0.35),
                    const Offset(0.55, 0.28),
                    const Offset(0.38, 0.55),
                    const Offset(0.52, 0.45),
                    const Offset(0.65, 0.62),
                    const Offset(0.42, 0.42),
                  ];
                  final pos = positions[e.key % positions.length];
                  return Positioned(
                    left: MediaQuery.of(context).size.width * pos.dx - 18,
                    top: (MediaQuery.of(context).size.height * 0.5) * pos.dy,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GuestItemDetailScreen(item: e.value),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: e.value.isResolved
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              e.value.title.length > 12
                                  ? '${e.value.title.substring(0, 12)}…'
                                  : e.value.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 8,
                            color: e.value.isResolved
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF2563EB),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: e.value.isResolved
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Legend
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MapLegendItem(color: const Color(0xFF2563EB), label: 'Active'),
              const SizedBox(height: 4),
              _MapLegendItem(color: const Color(0xFF16A34A), label: 'Resolved'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // "Post Item" hint chip
        GestureDetector(
          onTap: () => _showGuestPrompt('post a lost item'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sign in to post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: () => _showGuestPrompt('post a lost item'),
          backgroundColor: const Color(0xFF2563EB),
          elevation: 4,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ],
    );
  }
}

// ─── Item Card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final LostItem item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.categoryColor, size: 26),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isResolved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Found',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle Button ─────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }
}

// ─── Map Legend ────────────────────────────────────────────────────────────────

class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _MapLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Map Grid Painter ──────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDD9E5)
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Some "roads"
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Guest Prompt Sheet ────────────────────────────────────────────────────────

class _GuestPromptSheet extends StatelessWidget {
  final String action;
  const _GuestPromptSheet({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
            'You need an account to $action.\nJoin Findora for free and help your community.',
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
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  color: Color(0xFF2563EB),
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
              'Continue browsing as guest',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
