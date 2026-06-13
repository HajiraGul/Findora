import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import '../services/location_service.dart';
import 'item_detail_screen.dart';

// Fallback centre — IIU Islamabad.
const LatLng _defaultCenter = LatLng(33.7215, 73.0433);

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  String _filter = 'All';
  ItemModel? _selectedItem;
  late final ItemController _ctrl;
  Worker? _itemsWatcher;

  final MapController _mapController = MapController();
  static const _locationService = LocationService();
  bool _mapReady = false;
  bool _autoFitted = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ItemController>();
    // Rebuild pins + stats (and fit the camera) when live items arrive.
    _itemsWatcher = ever(_ctrl.items, (_) {
      if (!mounted) return;
      setState(() {});
      _maybeAutoFit();
    });
  }

  @override
  void dispose() {
    _itemsWatcher?.dispose();
    super.dispose();
  }

  List<ItemModel> get _filteredItems {
    final all = _ctrl.items;
    if (_filter == 'Lost') {
      return all.where((i) => i.status == ItemStatus.lost).toList();
    }
    if (_filter == 'Found') {
      return all.where((i) => i.status == ItemStatus.found).toList();
    }
    return all.toList();
  }

  // Items that carry real coordinates (skip un-geocoded 0,0 placeholders).
  List<ItemModel> get _mappableItems => _filteredItems
      .where((i) => !(i.latitude == 0 && i.longitude == 0))
      .toList();

  // ── Camera ─────────────────────────────────────────────────────────────────

  void _maybeAutoFit() {
    if (_autoFitted) return;
    final fitted = _fitToItems();
    if (fitted) _autoFitted = true;
  }

  bool _fitToItems() {
    if (!_mapReady) return false;
    final points = _mappableItems
        .map((i) => LatLng(i.latitude, i.longitude))
        .toList();
    if (points.isEmpty) return false;

    if (points.length == 1) {
      _mapController.move(points.first, 14);
    } else {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(60, 140, 60, 180),
          maxZoom: 16,
        ),
      );
    }
    return true;
  }

  Future<void> _recenterOnMe() async {
    setState(() => _locating = true);
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (result.isOk && _mapReady) {
      _mapController.move(LatLng(result.latitude!, result.longitude!), 15);
    } else if (!result.isOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Couldn\'t get your current location'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
                _buildMap(),
                Positioned(left: 12, bottom: 8, child: _buildAttribution()),
                Positioned(top: 16, left: 0, right: 0, child: _buildFilterRow()),
                Positioned(top: 70, right: 16, child: _buildLegend()),
                if (_selectedItem != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildItemSheet(context, _selectedItem!),
                  )
                else
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

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 12,
        minZoom: 3,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;
          _maybeAutoFit();
        },
        onTap: (_, __) {
          if (_selectedItem != null) setState(() => _selectedItem = null);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.findora.app',
          maxZoom: 19,
        ),
        // Shaded radius around each item so the lost/found areas stand out
        // beneath the pins.
        CircleLayer(circles: _buildAreaCircles()),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  // Translucent radius around each item — highlights where lost/found items
  // cluster. Red = lost, green = found; radius is in metres so it scales with
  // zoom and overlapping circles merge into a single highlighted area.
  List<CircleMarker> _buildAreaCircles() {
    return _mappableItems.map((item) {
      final isLost = item.status == ItemStatus.lost;
      final color = isLost ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
      return CircleMarker(
        point: LatLng(item.latitude, item.longitude),
        radius: 130,
        useRadiusInMeter: true,
        color: color.withValues(alpha: 0.15),
        borderColor: color.withValues(alpha: 0.55),
        borderStrokeWidth: 1.5,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    const tail = 7.0; // height of the pointer below the badge
    return _mappableItems.map((item) {
      final isLost = item.status == ItemStatus.lost;
      final color = isLost ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
      final selected = _selectedItem?.id == item.id;
      final badgeSize = selected ? 46.0 : 38.0;

      return Marker(
        point: LatLng(item.latitude, item.longitude),
        width: badgeSize,
        height: badgeSize + tail,
        // Anchor the pointer's tip on the coordinate so the icon sits above
        // the highlighted area, pointing down into it.
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => setState(() => _selectedItem = item),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Pointer first, so the badge draws over its top edge.
              Positioned(
                bottom: 0,
                child: CustomPaint(
                  size: const Size(14, tail + 4),
                  painter: _PinPointerPainter(color),
                ),
              ),
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: selected ? 3 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: selected ? 12 : 8,
                      spreadRadius: selected ? 2 : 1,
                    ),
                  ],
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  color: Colors.white,
                  size: selected ? 22 : 18,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAttribution() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '© OpenStreetMap',
        style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                      'Lost & found items around you',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _locating ? null : _recenterOnMe,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
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

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['All', 'Lost', 'Found'].map((f) {
          final isSelected = _filter == f;
          final Color color = f == 'Lost'
              ? const Color(0xFFEF4444)
              : f == 'Found'
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF2563EB);
          return GestureDetector(
            onTap: () {
              setState(() {
                _filter = f;
                _selectedItem = null;
              });
              _fitToItems();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
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

  Widget _buildMapStats() {
    final lostCount =
        _filteredItems.where((i) => i.status == ItemStatus.lost).length;
    final foundCount =
        _filteredItems.where((i) => i.status == ItemStatus.found).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(lostCount.toString(), 'Lost Items', const Color(0xFFEF4444)),
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
    final statusColor =
        isLost ? const Color(0xFFEF4444) : const Color(0xFF16A34A);

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
              color: Colors.black.withValues(alpha: 0.12),
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

// Downward triangle drawn beneath a marker badge so it reads as a map pin
// whose tip points at the item's exact coordinate.
class _PinPointerPainter extends CustomPainter {
  const _PinPointerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinPointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
