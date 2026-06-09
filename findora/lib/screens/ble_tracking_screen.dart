import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/claim_model.dart';
import 'ble_register_screen.dart';

class BleTrackingScreen extends StatefulWidget {
  const BleTrackingScreen({super.key});

  @override
  State<BleTrackingScreen> createState() => _BleTrackingScreenState();
}

class _BleTrackingScreenState extends State<BleTrackingScreen>
    with TickerProviderStateMixin {
  late List<BleTag> _tags;
  BleTag? _selectedTag;
  Timer? _signalTimer;
  late AnimationController _radarController;
  late AnimationController _pulseController;
  bool _isScanning = false;
  int _signalStrength = -45;

  @override
  void initState() {
    super.initState();
    _tags = List.from(dummyBleTags);
    _selectedTag = _tags.first;

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _startSignalSimulation();
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startSignalSimulation() {
    _signalTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_selectedTag == null) return;
      final random = Random();
      setState(() {
        _signalStrength = (_signalStrength + (random.nextInt(11) - 5)).clamp(
          -100,
          -30,
        );
      });
    });
  }

  BleProximity get _currentProximity {
    if (_signalStrength > -55) return BleProximity.near;
    if (_signalStrength > -70) return BleProximity.medium;
    if (_signalStrength > -85) return BleProximity.far;
    return BleProximity.outOfRange;
  }

  Map<String, dynamic> _proximityConfig(BleProximity p) {
    switch (p) {
      case BleProximity.near:
        return {
          'label': 'Very Near',
          'sublabel': 'Within 1 meter',
          'color': const Color(0xFF16A34A),
          'bg': const Color(0xFFDCFCE7),
          'icon': Icons.sensors_rounded,
          'rings': 3,
        };
      case BleProximity.medium:
        return {
          'label': 'Nearby',
          'sublabel': '1–5 meters away',
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFDBEAFE),
          'icon': Icons.wifi_tethering_rounded,
          'rings': 2,
        };
      case BleProximity.far:
        return {
          'label': 'Far',
          'sublabel': '5–15 meters away',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
          'icon': Icons.wifi_tethering_off_rounded,
          'rings': 1,
        };
      case BleProximity.outOfRange:
        return {
          'label': 'Out of Range',
          'sublabel': 'Signal lost',
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEF2F2),
          'icon': Icons.signal_wifi_off_rounded,
          'rings': 0,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTagSelector(),
                  if (_selectedTag != null) ...[
                    _buildRadarDisplay(),
                    _buildSignalDetails(),
                    _buildLastSeenMap(),
                    _buildTagList(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ── Back to HomeScreen ──────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
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
                          'BLE Tracker',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Live proximity detection',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // ── Live pulse badge ────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.1 + _pulseController.value * 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0xFF4ADE80),
                                const Color(0xFF86EFAC),
                                _pulseController.value,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FAB → BleRegisterScreen ─────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      // Navigator.push keeps BleTrackingScreen in the back stack so the user
      // can return here normally via the back button in BleRegisterScreen.
      // BleRegisterScreen's success action uses pushReplacement to come back
      // here cleanly without stacking an extra instance.
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BleRegisterScreen()),
      ),
      backgroundColor: const Color(0xFF2563EB),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Add Tag',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─── Tag Selector ────────────────────────────────────────────────────────

  Widget _buildTagSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Text(
                  'Select Tag to Track',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_tags.length} registered',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              itemCount: _tags.length,
              itemBuilder: (_, i) {
                final tag = _tags[i];
                final isSelected = _selectedTag?.id == tag.id;
                final proxConfig = _proximityConfig(tag.proximity);

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTag = tag;
                    _signalStrength = tag.signalStrength;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tag.isActive
                                ? proxConfig['color'] as Color
                                : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tag.itemName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF374151),
                              ),
                            ),
                            Text(
                              tag.tagId,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Radar Display ───────────────────────────────────────────────────────

  Widget _buildRadarDisplay() {
    final proxConfig = _proximityConfig(_currentProximity);
    final rings = proxConfig['rings'] as int;
    final color = proxConfig['color'] as Color;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTag?.itemName ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: proxConfig['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  proxConfig['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Radar visual
          SizedBox(
            width: 200,
            height: 200,
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Static rings
                    for (int r = 3; r >= 1; r--)
                      Container(
                        width: r * 60.0,
                        height: r * 60.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: r <= rings
                                ? color.withOpacity(0.2)
                                : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          color: r <= rings
                              ? color.withOpacity(0.03)
                              : Colors.transparent,
                        ),
                      ),
                    // Radar sweep
                    if (_selectedTag?.isActive == true)
                      Transform.rotate(
                        angle: _radarController.value * 2 * pi,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                color.withOpacity(0.0),
                                color.withOpacity(0.15),
                                color.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.15, 0.3],
                            ),
                          ),
                        ),
                      ),
                    // Center dot
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Item dot position based on proximity
                    if (_currentProximity != BleProximity.outOfRange)
                      Positioned(
                        top: _proximityToPosition(_currentProximity),
                        left: 90,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color.withOpacity(
                                0.7 + _pulseController.value * 0.3,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            proxConfig['sublabel'] as String,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _proximityToPosition(BleProximity p) {
    switch (p) {
      case BleProximity.near:
        return 75;
      case BleProximity.medium:
        return 50;
      case BleProximity.far:
        return 25;
      default:
        return 0;
    }
  }

  // ─── Signal Details ──────────────────────────────────────────────────────

  Widget _buildSignalDetails() {
    final proxConfig = _proximityConfig(_currentProximity);
    final color = proxConfig['color'] as Color;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signal Strength (RSSI)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$_signalStrength dBm',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const Spacer(),
              _buildSignalBars(color),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_signalStrength + 100) / 70,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '-100 dBm (Weak)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
              Text(
                '-30 dBm (Strong)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _signalStat(
                  'Tag ID',
                  _selectedTag?.tagId ?? '',
                  Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _signalStat(
                  'Last Seen',
                  _selectedTag?.lastSeen ?? '',
                  Icons.access_time_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBars(Color color) {
    const bars = 5;
    final activeBars = _currentProximity == BleProximity.near
        ? 5
        : _currentProximity == BleProximity.medium
        ? 3
        : _currentProximity == BleProximity.far
        ? 2
        : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars, (i) {
        final isActive = i < activeBars;
        return Container(
          margin: const EdgeInsets.only(left: 3),
          width: 8,
          height: 10.0 + i * 5,
          decoration: BoxDecoration(
            color: isActive ? color : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _signalStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Last Seen Map ───────────────────────────────────────────────────────

  Widget _buildLastSeenMap() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Last Known Location',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  _selectedTag?.lastSeen ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Container(
              height: 150,
              color: const Color(0xFFE8EFF5),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: _SimpleMapPainter(),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bluetooth_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            _selectedTag?.lastLocation ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tag List ────────────────────────────────────────────────────────────

  Widget _buildTagList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'All Registered Tags',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          ..._tags.asMap().entries.map((entry) {
            final i = entry.key;
            final tag = entry.value;
            final isLast = i == _tags.length - 1;
            final proxConfig = _proximityConfig(tag.proximity);
            final isSelected = _selectedTag?.id == tag.id;

            return GestureDetector(
              onTap: () => setState(() {
                _selectedTag = tag;
                _signalStrength = tag.signalStrength;
              }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  border: !isLast
                      ? const Border(
                          bottom: BorderSide(
                            color: Color(0xFFF1F5F9),
                            width: 1,
                          ),
                        )
                      : null,
                  borderRadius: isLast
                      ? const BorderRadius.vertical(bottom: Radius.circular(16))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (proxConfig['bg'] as Color),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        proxConfig['icon'] as IconData,
                        color: proxConfig['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag.itemName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tag.tagId,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (proxConfig['bg'] as Color),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            proxConfig['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: proxConfig['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tag.lastSeen,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Map Painter ──────────────────────────────────────────────────────────────

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFBFCCDB)
      ..strokeWidth = 0.5;
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;

    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
