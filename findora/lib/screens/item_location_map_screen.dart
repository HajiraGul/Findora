import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/item_model.dart';

// Full-screen interactive map focused on a single item's last-seen location.
// Opened from the item detail screen when the user taps the map preview.
class ItemLocationMapScreen extends StatefulWidget {
  final ItemModel item;

  const ItemLocationMapScreen({super.key, required this.item});

  @override
  State<ItemLocationMapScreen> createState() => _ItemLocationMapScreenState();
}

class _ItemLocationMapScreenState extends State<ItemLocationMapScreen> {
  final MapController _mapController = MapController();

  LatLng get _point => LatLng(widget.item.latitude, widget.item.longitude);

  @override
  Widget build(BuildContext context) {
    final isLost = widget.item.status == ItemStatus.lost;
    final color = isLost ? const Color(0xFFEF4444) : const Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              children: [
                _buildMap(color),
                Positioned(left: 12, bottom: 8, child: _buildAttribution()),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildRecenterButton(),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildInfoCard(color, isLost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(Color color) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _point,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.findora.app',
          maxZoom: 19,
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: _point,
              radius: 130,
              useRadiusInMeter: true,
              color: color.withValues(alpha: 0.15),
              borderColor: color.withValues(alpha: 0.55),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        MarkerLayer(markers: [_buildMarker(color)]),
      ],
    );
  }

  Marker _buildMarker(Color color) {
    const tail = 7.0;
    const badgeSize = 46.0;
    return Marker(
      point: _point,
      width: badgeSize,
      height: badgeSize + tail,
      alignment: Alignment.topCenter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
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
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _categoryIcon(widget.item.category),
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: () => _mapController.move(_point, 15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.center_focus_strong_rounded,
          color: Color(0xFF2563EB),
          size: 20,
        ),
      ),
    );
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Seen Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color color, bool isLost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _categoryIcon(widget.item.category),
              color: color,
              size: 24,
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
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isLost ? 'LOST' : 'FOUND',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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

// Downward triangle drawn beneath a marker badge so it reads as a map pin.
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
