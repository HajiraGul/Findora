import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import '../services/location_service.dart';
import 'item_detail_screen.dart';

// Fallback centre — IIU Islamabad.
const LatLng _defaultCenter = LatLng(33.7215, 73.0433);

class MapViewScreen extends StatefulWidget {
  final bool embedded;

  const MapViewScreen({super.key, this.embedded = false});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  String _filter = 'All';
  ItemModel? _selectedItem;
  late final ItemController _ctrl;
  Worker? _itemsWatcher;

  final MapController _mapController = MapController();
  final GetConnect _geoClient = GetConnect();
  static const _locationService = LocationService();
  bool _mapReady = false;
  bool _initialCameraSettled = false;
  bool _fittedToItems = false;
  bool _resolvingMissingCoords = false;
  bool _cameraFitScheduled = false;
  bool _locating = false;
  final Map<String, LatLng> _resolvedPoints = {};
  final Set<String> _unresolvedPointIds = {};

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ItemController>();
    _geoClient.httpClient.timeout = const Duration(seconds: 8);
    // Rebuild pins + stats (and fit the camera) when live items arrive.
    _itemsWatcher = ever(_ctrl.items, (_) {
      if (!mounted) return;
      setState(() {});
      _resolveMissingCoordinates();
      _scheduleCameraSettle(forceFit: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_ctrl.items.isEmpty && !_ctrl.isLoading.value) {
        _ctrl.fetchItems();
      }
      _resolveMissingCoordinates();
      _scheduleCameraSettle(forceFit: true);
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

  // Items that carry real coordinates, plus address-only items that have been
  // resolved locally for display.
  List<ItemModel> get _mappableItems =>
      _filteredItems.where((i) => _pointForItem(i) != null).toList();

  // ── Camera ─────────────────────────────────────────────────────────────────

  void _scheduleCameraSettle({bool forceFit = false}) {
    if (_cameraFitScheduled) return;
    _cameraFitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      _cameraFitScheduled = false;
      _settleInitialCamera(forceFit: forceFit);

      // flutter_map can ignore camera changes if an embedded map is still
      // receiving its final constraints. Retry once after layout settles.
      if (!_fittedToItems && _mappableItems.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (mounted) _settleInitialCamera(forceFit: true);
      }
    });
  }

  Future<void> _settleInitialCamera({bool forceFit = false}) async {
    if (!_mapReady) return;

    if ((forceFit || !_fittedToItems) && _fitToItems()) {
      _fittedToItems = true;
      _initialCameraSettled = true;
      return;
    }

    if (_initialCameraSettled) return;
    _mapController.move(_defaultCenter, 12);
    _initialCameraSettled = true;
  }

  Future<void> _resolveMissingCoordinates() async {
    if (_resolvingMissingCoords) return;
    final missing = _filteredItems
        .where(
          (item) =>
              item.location.trim().isNotEmpty &&
              item.latitude == 0 &&
              item.longitude == 0 &&
              !_resolvedPoints.containsKey(item.id) &&
              !_unresolvedPointIds.contains(item.id),
        )
        .toList();
    if (missing.isEmpty) return;

    _resolvingMissingCoords = true;
    var resolvedAny = false;
    try {
      for (final item in missing) {
        _resolvedPoints[item.id] = _fallbackPointForItem(item);
        resolvedAny = true;
        try {
          final point = await _geocodeItemAddress(item.location);
          if (!mounted) return;
          if (point != null && _isReasonableMapPoint(point)) {
            _resolvedPoints[item.id] = point;
          }
        } catch (_) {
          // Keep the stable fallback point assigned above.
        }
      }
    } finally {
      _resolvingMissingCoords = false;
    }

    if (!mounted || !resolvedAny) return;
    setState(() {});
    _scheduleCameraSettle(forceFit: true);
  }

  Future<LatLng?> _geocodeItemAddress(String address) async {
    try {
      final matches = await locationFromAddress(address);
      if (matches.isNotEmpty) {
        final first = matches.first;
        return LatLng(first.latitude, first.longitude);
      }
    } catch (_) {
      // Fall back to OpenStreetMap below.
    }

    try {
      final response = await _geoClient.get(
        'https://nominatim.openstreetmap.org/search',
        query: {
          'q': address,
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'pk',
        },
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Findora map view',
        },
      );
      final body = response.body;
      if (!response.isOk || body is! List || body.isEmpty) return null;

      final first = body.first;
      if (first is! Map) return null;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  LatLng _fallbackPointForItem(ItemModel item) {
    final seed = '${item.id}:${item.title}:${item.location}'.codeUnits
        .fold<int>(0, (sum, unit) => sum + unit);
    final latOffset = ((seed % 9) - 4) * 0.008;
    final lngOffset = (((seed ~/ 9) % 9) - 4) * 0.008;
    return LatLng(
      _defaultCenter.latitude + latOffset,
      _defaultCenter.longitude + lngOffset,
    );
  }

  bool _fitToItems() {
    if (!_mapReady) return false;
    final points = _mappableItems.map(_pointForItem).nonNulls.toList();
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

  LatLng? _pointForItem(ItemModel item) {
    if (item.latitude != 0 || item.longitude != 0) {
      final point = LatLng(item.latitude, item.longitude);
      if (_isReasonableMapPoint(point)) return point;
      return _resolvedPoints[item.id] ?? _fallbackPointForItem(item);
    }
    return _resolvedPoints[item.id];
  }

  bool _isReasonableMapPoint(LatLng point) {
    return point.latitude >= 23 &&
        point.latitude <= 38 &&
        point.longitude >= 60 &&
        point.longitude <= 78;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        _buildMap(),
        Positioned(left: 12, bottom: 8, child: _buildAttribution()),
        Positioned(top: 16, left: 0, right: 0, child: _buildFilterRow()),
        Positioned(top: 70, right: 16, child: _buildLegend()),
        if (widget.embedded)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _locating ? null : _recenterOnMe,
              child: _buildLocateButton(),
            ),
          ),
        if (_selectedItem != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildItemSheet(context, _selectedItem!),
          )
        else
          Positioned(bottom: 20, left: 20, right: 20, child: _buildMapStats()),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: content),
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
          _mapController.move(_defaultCenter, 12);
          _scheduleCameraSettle(forceFit: true);
        },
        onTap: (_, _) {
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
    return _mappableItems
        .map((item) {
          final point = _pointForItem(item);
          if (point == null) return null;
          final isLost = item.status == ItemStatus.lost;
          final color = isLost
              ? const Color(0xFFEF4444)
              : const Color(0xFF16A34A);
          return CircleMarker(
            point: point,
            radius: 130,
            useRadiusInMeter: true,
            color: color.withValues(alpha: 0.15),
            borderColor: color.withValues(alpha: 0.55),
            borderStrokeWidth: 1.5,
          );
        })
        .nonNulls
        .toList();
  }

  List<Marker> _buildMarkers() {
    const tail = 7.0; // height of the pointer below the badge
    return _mappableItems
        .map((item) {
          final point = _pointForItem(item);
          if (point == null) return null;
          final isLost = item.status == ItemStatus.lost;
          final color = isLost
              ? const Color(0xFFEF4444)
              : const Color(0xFF16A34A);
          final selected = _selectedItem?.id == item.id;
          final badgeSize = selected ? 46.0 : 38.0;

          return Marker(
            point: point,
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
        })
        .nonNulls
        .toList();
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
                child: _buildLocateButton(onGradient: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocateButton({bool onGradient = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: onGradient ? Colors.white.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onGradient
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: _locating
          ? Padding(
              padding: const EdgeInsets.all(11),
              child: CircularProgressIndicator(
                color: onGradient ? Colors.white : const Color(0xFF2563EB),
                strokeWidth: 2,
              ),
            )
          : Icon(
              Icons.my_location_rounded,
              color: onGradient ? Colors.white : const Color(0xFF2563EB),
              size: 18,
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
              _resolveMissingCoordinates().then((_) {
                if (!mounted) return;
                _fittedToItems = false;
                if (_mappableItems.isEmpty) {
                  _mapController.move(_defaultCenter, 12);
                } else {
                  _scheduleCameraSettle(forceFit: true);
                }
              });
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
            color: Colors.black.withValues(alpha: 0.1),
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
