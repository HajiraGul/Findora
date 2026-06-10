import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

// Default coordinates — IIU Islamabad (used until real device location is wired up)
const double _defaultLat = 33.7215;
const double _defaultLng = 73.0433;

class ItemsNearMeScreen extends StatefulWidget {
  const ItemsNearMeScreen({super.key});

  @override
  State<ItemsNearMeScreen> createState() => _ItemsNearMeScreenState();
}

class _ItemsNearMeScreenState extends State<ItemsNearMeScreen> {
  double _radiusKm = 1.0;
  String _sortBy = 'Distance';
  late final ItemController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ItemController>();
    _loadNearby();
  }

  void _loadNearby() {
    _ctrl.fetchNearby(
      lat: _defaultLat,
      lng: _defaultLng,
      radiusKm: _radiusKm,
      sort: _sortBy == 'Newest' ? 'newest' : 'distance',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          _buildRadiusSlider(),
          Obx(() => _buildSortRow()),
          Expanded(child: Obx(() => _buildList())),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items Near Me',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          'Based on your current location',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        const Text('Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                final count = _ctrl.nearbyItems.length;
                final lostCount = _ctrl.nearbyItems.where((i) => i.status == ItemStatus.lost).length;
                return Row(
                  children: [
                    _headerStat('$count', 'Nearby Items'),
                    const SizedBox(width: 16),
                    _headerStat('${_radiusKm.toStringAsFixed(1)} km', 'Radius'),
                    const SizedBox(width: 16),
                    _headerStat('$lostCount', 'Lost'),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              const Text('Search Radius', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${_radiusKm.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF2563EB),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF2563EB),
              overlayColor: const Color(0xFF2563EB).withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _radiusKm,
              min: 0.2,
              max: 5.0,
              divisions: 24,
              onChanged: (v) => setState(() => _radiusKm = v),
              onChangeEnd: (_) => _loadNearby(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.2 km', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text('5.0 km', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    final count = _ctrl.nearbyItems.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Text('$count items found', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          const Spacer(),
          const Text('Sort: ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          GestureDetector(
            onTap: () {
              setState(() => _sortBy = _sortBy == 'Distance' ? 'Newest' : 'Distance');
              _loadNearby();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_sortBy, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_vert_rounded, size: 14, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_ctrl.nearbyLoading.value && _ctrl.nearbyItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ctrl.nearbyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.near_me_disabled_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No items in this radius', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
            const SizedBox(height: 6),
            Text('Try increasing the search radius', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _loadNearby(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        itemCount: _ctrl.nearbyItems.length,
        itemBuilder: (_, i) {
          final item = _ctrl.nearbyItems[i];
          final dist = item.distanceKm;
          return Stack(
            children: [
              ItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                ),
              ),
              if (dist != null)
                Positioned(
                  bottom: 28,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '${dist.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
