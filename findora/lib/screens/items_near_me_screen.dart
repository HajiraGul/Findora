import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import '../services/location_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

// Fallback coordinates — IIU Islamabad (used when device location is unavailable)
const double _defaultLat = 33.7215;
const double _defaultLng = 73.0433;

class ItemsNearMeScreen extends StatefulWidget {
  final bool embedded;

  const ItemsNearMeScreen({super.key, this.embedded = false});

  @override
  State<ItemsNearMeScreen> createState() => _ItemsNearMeScreenState();
}

class _ItemsNearMeScreenState extends State<ItemsNearMeScreen> {
  double _radiusKm = 1.0;
  String _sortBy = 'Distance';
  late final ItemController _ctrl;

  static const _locationService = LocationService();
  double _lat = _defaultLat;
  double _lng = _defaultLng;
  bool _usingApprox = true; // true until we get a real device fix
  bool _locating = true; // true while resolving location for the first time
  String? _locationNotice;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ItemController>();
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (mounted) setState(() => _locating = true);
    final result = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (result.isOk) {
          _lat = result.latitude!;
          _lng = result.longitude!;
          _usingApprox = false;
          _locationNotice = null;
        } else {
          _usingApprox = true;
          _locationNotice = _noticeFor(result.status);
        }
      });
    }
    await _loadNearby();
    if (mounted) setState(() => _locating = false);
  }

  String _noticeFor(LocationStatus status) {
    switch (status) {
      case LocationStatus.serviceDisabled:
        return 'Location services are off — showing an approximate area.';
      case LocationStatus.deniedForever:
      case LocationStatus.denied:
        return 'Location permission denied — showing an approximate area.';
      default:
        return 'Couldn\'t get your location — showing an approximate area.';
    }
  }

  Future<void> _loadNearby() {
    return _ctrl.fetchNearby(
      lat: _lat,
      lng: _lng,
      radiusKm: _radiusKm,
      sort: _sortBy == 'Newest' ? 'newest' : 'distance',
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (!widget.embedded) _buildHeader(context),
        _buildLocationNotice(),
        _buildRadiusSlider(),
        Obx(() => _buildSortRow()),
        Expanded(child: Obx(() => _buildList())),
      ],
    );

    if (widget.embedded) {
      return Container(color: const Color(0xFFF8FAFC), child: content);
    }

    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: content);
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
                          'Items Near Me',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _usingApprox
                              ? 'Approximate location'
                              : 'Based on your current location',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Live',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                final count = _ctrl.nearbyItems.length;
                final lostCount = _ctrl.nearbyItems
                    .where((i) => i.status == ItemStatus.lost)
                    .length;
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Search Radius',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_radiusKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
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
              Text(
                '0.2 km',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
              Text(
                '5.0 km',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
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
          Text(
            '$count items found',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          const Text(
            'Sort: ',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          GestureDetector(
            onTap: () {
              setState(
                () => _sortBy = _sortBy == 'Distance' ? 'Newest' : 'Distance',
              );
              _loadNearby();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortBy,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.swap_vert_rounded,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationNotice() {
    if (!_usingApprox || _locationNotice == null || _locating) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationNotice!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _initLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    // Read observables up-front so Obx always registers them — never let `||`
    // short-circuit past these, or GetX throws "improper use of a GetX".
    final loading = _ctrl.nearbyLoading.value;
    final items = _ctrl.nearbyItems;
    if (_locating || (loading && items.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_locating) ...[
              const SizedBox(height: 16),
              Text(
                'Finding items near you…',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.near_me_disabled_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No items in this radius',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try increasing the search radius',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _loadNearby(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final dist = item.distanceKm;
          return Stack(
            children: [
              ItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                ),
              ),
              if (dist != null)
                Positioned(
                  bottom: 28,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${dist.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
