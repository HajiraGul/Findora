import 'package:flutter/material.dart';
import '../models/item_model.dart';
import 'item_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  String _filter = 'All';
  ItemModel? _selectedItem;

  List<ItemModel> get _filteredItems {
    if (_filter == 'All') return dummyItems;
    if (_filter == 'Lost') {
      return dummyItems.where((i) => i.status == ItemStatus.lost).toList();
    }
    return dummyItems.where((i) => i.status == ItemStatus.found).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              children: [
                _buildFakeMap(),
                // Filter chips
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: _buildFilterRow(),
                ),
                // Legend
                Positioned(top: 70, right: 16, child: _buildLegend()),
                // Item pins
                ..._buildPins(context),
                // Bottom sheet when item selected
                if (_selectedItem != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildItemSheet(context, _selectedItem!),
                  ),
                // Dismiss when nothing selected
                if (_selectedItem == null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildMapStats(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
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
                      'Map View',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'IIU Campus, Islamabad',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
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
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFakeMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE8EFF5),
      child: CustomPaint(painter: _DetailedFakeMapPainter()),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['All', 'Lost', 'Found'].map((f) {
          final isSelected = _filter == f;
          Color color = f == 'Lost'
              ? const Color(0xFFEF4444)
              : f == 'Found'
              ? const Color(0xFF16A34A)
              : const Color(0xFF2563EB);
          return GestureDetector(
            onTap: () => setState(() {
              _filter = f;
              _selectedItem = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(0xFFEF4444), 'Lost'),
          const SizedBox(height: 6),
          _legendRow(const Color(0xFF16A34A), 'Found'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  List<Widget> _buildPins(BuildContext context) {
    // Map lat/lng to screen positions (normalized to fake map)
    final size = MediaQuery.of(context).size;
    final mapHeight = size.height - 200.0;

    final minLat = 33.7205;
    final maxLat = 33.7230;
    final minLng = 73.0420;
    final maxLng = 73.0450;

    return _filteredItems.map((item) {
      final x =
          ((item.longitude - minLng) / (maxLng - minLng)) * (size.width - 60) +
          20;
      final y =
          (1 - (item.latitude - minLat) / (maxLat - minLat)) *
              (mapHeight - 160) +
          80;

      final isLost = item.status == ItemStatus.lost;
      final pinColor = isLost
          ? const Color(0xFFEF4444)
          : const Color(0xFF16A34A);

      return Positioned(
        left: x - 18,
        top: y,
        child: GestureDetector(
          onTap: () => setState(() => _selectedItem = item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _selectedItem?.id == item.id ? 40 : 34,
                  height: _selectedItem?.id == item.id ? 40 : 34,
                  decoration: BoxDecoration(
                    color: pinColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: pinColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _categoryIcon(item.category),
                    color: Colors.white,
                    size: _selectedItem?.id == item.id ? 20 : 16,
                  ),
                ),
                Container(width: 2, height: 8, color: pinColor),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: pinColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMapStats() {
    final lostCount = _filteredItems
        .where((i) => i.status == ItemStatus.lost)
        .length;
    final foundCount = _filteredItems
        .where((i) => i.status == ItemStatus.found)
        .length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            lostCount.toString(),
            'Lost Items',
            const Color(0xFFEF4444),
          ),
          Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
          _statItem(
            foundCount.toString(),
            'Found Items',
            const Color(0xFF16A34A),
          ),
          Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
          _statItem(
            _filteredItems.length.toString(),
            'Total',
            const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildItemSheet(BuildContext context, ItemModel item) {
    final isLost = item.status == ItemStatus.lost;
    final statusColor = isLost
        ? const Color(0xFFEF4444)
        : const Color(0xFF16A34A);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(item: item, isGuest: false),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(item.category),
                    color: const Color(0xFF2563EB),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isLost ? 'LOST' : 'FOUND',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedItem = null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ItemDetailScreen(item: item, isGuest: false),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.white,
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
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Documents':
        return Icons.description_outlined;
      case 'Keys':
        return Icons.key_rounded;
      case 'Bags & Wallets':
        return Icons.shopping_bag_outlined;
      case 'Clothing':
        return Icons.checkroom_outlined;
      case 'Accessories':
        return Icons.watch_outlined;
      case 'Books':
        return Icons.menu_book_rounded;
      default:
        return Icons.category_outlined;
    }
  }
}

class _DetailedFakeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = const Color(0xFFD1DCE8);
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14;
    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7;
    final gridPaint = Paint()
      ..color = const Color(0xFFBFCCDB)
      ..strokeWidth = 0.5;

    // Grid
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Building blocks
    final blocks = [
      Rect.fromLTWH(20, 100, 80, 60),
      Rect.fromLTWH(140, 80, 60, 80),
      Rect.fromLTWH(240, 120, 70, 50),
      Rect.fromLTWH(20, 220, 90, 50),
      Rect.fromLTWH(160, 210, 80, 60),
      Rect.fromLTWH(280, 200, 60, 70),
      Rect.fromLTWH(50, 320, 100, 55),
      Rect.fromLTWH(220, 310, 90, 60),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(4)),
        blockPaint,
      );
    }

    // Major roads
    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.45),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, 0),
      Offset(size.width * 0.38, size.height),
      roadPaint,
    );

    // Minor roads
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.65, size.height),
      minorRoadPaint,
    );

    // Green area
    final greenPaint = Paint()..color = const Color(0xFFC8DFC8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.5, 80, 80),
        const Radius.circular(8),
      ),
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
