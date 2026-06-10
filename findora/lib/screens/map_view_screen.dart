import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import 'item_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  String _filter = 'All';
  String _boundaryLevel = 'ADM2';
  ItemModel? _selectedItem;
  late final ItemController _ctrl;
  Worker? _itemsWatcher;
  late final Future<Map<String, _GeoBoundaryData>> _boundariesFuture;
  Map<String, _GeoBoundaryData>? _boundaries;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ItemController>();
    _boundariesFuture = _loadBoundaries();
    _boundariesFuture.then((boundaries) {
      if (mounted) {
        setState(() => _boundaries = boundaries);
      }
    });
    // Rebuild pins and stats when live items arrive from the API.
    _itemsWatcher = ever(_ctrl.items, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _itemsWatcher?.dispose();
    super.dispose();
  }

  List<ItemModel> get _filteredItems {
    final all = _ctrl.items;
    if (_filter == 'All') return all.toList();
    if (_filter == 'Lost') {
      return all.where((i) => i.status == ItemStatus.lost).toList();
    }
    return all.where((i) => i.status == ItemStatus.found).toList();
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
                _buildGeoMap(),
                // Filter chips
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: _buildFilterRow(),
                ),
                // Legend
                Positioned(top: 70, left: 16, child: _buildBoundarySelector()),
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

  Future<Map<String, _GeoBoundaryData>> _loadBoundaries() async {
    final entries = {
      'ADM1': 'assets/geo/geoBoundaries-PAK-ADM1_simplified.geojson',
      'ADM2': 'assets/geo/geoBoundaries-PAK-ADM2_simplified.geojson',
      'ADM3': 'assets/geo/geoBoundaries-PAK-ADM3_simplified.geojson',
    };

    final loaded = <String, _GeoBoundaryData>{};
    for (final entry in entries.entries) {
      final raw = await rootBundle.loadString(entry.value);
      loaded[entry.key] = _GeoBoundaryData.fromGeoJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }
    return loaded;
  }

  Widget _buildGeoMap() {
    return FutureBuilder<Map<String, _GeoBoundaryData>>(
      future: _boundariesFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data?[_boundaryLevel] ?? _boundaries?[_boundaryLevel];
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE8EFF5),
          child: data == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                    strokeWidth: 2.5,
                  ),
                )
              : CustomPaint(painter: _PakistanBoundaryPainter(data)),
        );
      },
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

  Widget _buildBoundarySelector() {
    const levels = {'ADM1': 'Province', 'ADM2': 'District', 'ADM3': 'Tehsil'};

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: levels.entries.map((entry) {
          final selected = _boundaryLevel == entry.key;
          return GestureDetector(
            onTap: () => setState(() {
              _boundaryLevel = entry.key;
              _selectedItem = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2563EB) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
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
    final size = MediaQuery.of(context).size;
    final mapHeight = size.height - 200.0;
    final bounds =
        _boundaries?[_boundaryLevel]?.bounds ??
        const _LatLngBounds(
          minLat: 23.5,
          maxLat: 37.2,
          minLng: 60.8,
          maxLng: 77.2,
        );

    return _filteredItems.map((item) {
      final point = _projectLatLng(
        latitude: item.latitude,
        longitude: item.longitude,
        bounds: bounds,
        size: Size(size.width, mapHeight),
        padding: const EdgeInsets.fromLTRB(18, 120, 18, 92),
      );

      final isLost = item.status == ItemStatus.lost;
      final pinColor = isLost
          ? const Color(0xFFEF4444)
          : const Color(0xFF16A34A);

      return Positioned(
        left: point.dx - 18,
        top: point.dy,
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

  Offset _projectLatLng({
    required double latitude,
    required double longitude,
    required _LatLngBounds bounds,
    required Size size,
    required EdgeInsets padding,
  }) {
    if (latitude == 0 && longitude == 0) {
      return Offset(size.width / 2, size.height / 2);
    }

    final innerWidth = size.width - padding.horizontal;
    final innerHeight = size.height - padding.vertical;
    final lngSpan = bounds.maxLng - bounds.minLng;
    final latSpan = bounds.maxLat - bounds.minLat;
    final x =
        padding.left + ((longitude - bounds.minLng) / lngSpan) * innerWidth;
    final y =
        padding.top + (1 - (latitude - bounds.minLat) / latSpan) * innerHeight;

    return Offset(
      x.clamp(12.0, size.width - 12.0),
      y.clamp(84.0, size.height - 24.0),
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

class _PakistanBoundaryPainter extends CustomPainter {
  final _GeoBoundaryData data;

  const _PakistanBoundaryPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.45)
      ..strokeWidth = 0.5;
    final fillPaint = Paint()
      ..color = const Color(0xFFDBEAFE)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = data.features.length > 200 ? 0.45 : 0.75;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final padding = EdgeInsets.fromLTRB(
      size.width * 0.08,
      size.height * 0.12,
      size.width * 0.08,
      size.height * 0.1,
    );

    for (final feature in data.features) {
      for (final ring in feature.rings) {
        if (ring.length < 3) continue;
        final path = Path();
        for (var i = 0; i < ring.length; i++) {
          final point = _project(
            latitude: ring[i].latitude,
            longitude: ring[i].longitude,
            bounds: data.bounds,
            size: size,
            padding: padding,
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }
    }

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'Pakistan boundaries',
        style: TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(size.width - labelPainter.width - 18, size.height - 34),
    );

    if (data.features.length <= 10) {
      for (final feature in data.features) {
        final label = feature.name;
        final center = feature.center;
        if (label.isEmpty || center == null) continue;
        final point = _project(
          latitude: center.latitude,
          longitude: center.longitude,
          bounds: data.bounds,
          size: size,
          padding: padding,
        );
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '',
        )..layout(maxWidth: 92);
        painter.paint(canvas, point - Offset(painter.width / 2, 6));
      }
    }
  }

  Offset _project({
    required double latitude,
    required double longitude,
    required _LatLngBounds bounds,
    required Size size,
    required EdgeInsets padding,
  }) {
    final x =
        padding.left +
        ((longitude - bounds.minLng) / (bounds.maxLng - bounds.minLng)) *
            (size.width - padding.horizontal);
    final y =
        padding.top +
        (1 - (latitude - bounds.minLat) / (bounds.maxLat - bounds.minLat)) *
            (size.height - padding.vertical);
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _PakistanBoundaryPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _GeoBoundaryData {
  final List<_GeoBoundaryFeature> features;
  final _LatLngBounds bounds;

  const _GeoBoundaryData({required this.features, required this.bounds});

  factory _GeoBoundaryData.fromGeoJson(Map<String, dynamic> json) {
    final features = <_GeoBoundaryFeature>[];
    var minLat = double.infinity;
    var maxLat = double.negativeInfinity;
    var minLng = double.infinity;
    var maxLng = double.negativeInfinity;

    final rawFeatures = json['features'] as List<dynamic>? ?? [];
    for (final rawFeature in rawFeatures) {
      if (rawFeature is! Map<String, dynamic>) continue;

      final properties =
          rawFeature['properties'] as Map<String, dynamic>? ?? {};
      final name = properties['shapeName']?.toString() ?? '';
      final geometry = rawFeature['geometry'] as Map<String, dynamic>? ?? {};
      final geometryType = geometry['type']?.toString();
      final coordinates = geometry['coordinates'];
      final rings = <List<_GeoPoint>>[];

      void addRing(List<dynamic> rawRing) {
        final ring = <_GeoPoint>[];
        for (final rawPoint in rawRing) {
          if (rawPoint is! List || rawPoint.length < 2) continue;
          final longitude = (rawPoint[0] as num).toDouble();
          final latitude = (rawPoint[1] as num).toDouble();
          minLat = latitude < minLat ? latitude : minLat;
          maxLat = latitude > maxLat ? latitude : maxLat;
          minLng = longitude < minLng ? longitude : minLng;
          maxLng = longitude > maxLng ? longitude : maxLng;
          ring.add(_GeoPoint(latitude: latitude, longitude: longitude));
        }
        if (ring.isNotEmpty) rings.add(ring);
      }

      if (geometryType == 'Polygon' && coordinates is List) {
        for (final rawRing in coordinates) {
          if (rawRing is List) addRing(rawRing);
        }
      } else if (geometryType == 'MultiPolygon' && coordinates is List) {
        for (final polygon in coordinates) {
          if (polygon is! List) continue;
          for (final rawRing in polygon) {
            if (rawRing is List) addRing(rawRing);
          }
        }
      }

      if (rings.isNotEmpty) {
        features.add(_GeoBoundaryFeature(name: name, rings: rings));
      }
    }

    return _GeoBoundaryData(
      features: features,
      bounds: _LatLngBounds(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      ),
    );
  }
}

class _GeoBoundaryFeature {
  final String name;
  final List<List<_GeoPoint>> rings;

  const _GeoBoundaryFeature({required this.name, required this.rings});

  _GeoPoint? get center {
    var latitude = 0.0;
    var longitude = 0.0;
    var count = 0;

    for (final ring in rings) {
      for (final point in ring) {
        latitude += point.latitude;
        longitude += point.longitude;
        count++;
      }
    }

    if (count == 0) return null;
    return _GeoPoint(latitude: latitude / count, longitude: longitude / count);
  }
}

class _GeoPoint {
  final double latitude;
  final double longitude;

  const _GeoPoint({required this.latitude, required this.longitude});
}

class _LatLngBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _LatLngBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}
