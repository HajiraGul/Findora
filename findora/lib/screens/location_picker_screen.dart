import 'package:flutter/material.dart';

/// LocationPickerScreen
///
/// A mock map pin-drop interface. In production replace the
/// [_MockMapView] widget body with a real [google_maps_flutter]
/// GoogleMap widget and wire up the onTap / onCameraMove callbacks.
///
/// Returns: a [String] address back to the calling screen via
/// Navigator.pop(context, selectedAddress).

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _pinDropped = false;
  bool _isSearching = false;
  bool _isConfirming = false;
  String? _selectedAddress;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Mock pins on the map  (lat, lng, label)
  final List<_MockPin> _recentPins = [
    _MockPin(0.28, 0.35, 'Jinnah Super Market, F-7'),
    _MockPin(0.52, 0.60, 'F-10 Markaz'),
    _MockPin(0.70, 0.25, 'Blue Area, Islamabad'),
  ];

  _MockPin? _droppedPin;

  // Animation for the pin drop bounce
  late AnimationController _pinAnim;
  late Animation<double> _pinBounce;

  // Mock search suggestions
  final List<String> _allSuggestions = [
    'Jinnah Super Market, F-7, Islamabad',
    'F-10 Markaz, Islamabad',
    'Blue Area, Islamabad',
    'G-9 Markaz, Islamabad',
    'Centaurus Mall, F-8, Islamabad',
    'Islamabad Stock Exchange, Blue Area',
    'PIMS Hospital, G-8, Islamabad',
    'Parade Ground, D-Chowk, Islamabad',
    'Faisal Mosque, E-8, Islamabad',
    'Shakar Parian, Islamabad',
  ];

  List<String> get _filteredSuggestions => _searchQuery.isEmpty
      ? []
      : _allSuggestions
            .where((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

  @override
  void initState() {
    super.initState();
    _pinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pinBounce = CurvedAnimation(parent: _pinAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pinAnim.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onMapTap(Offset localPosition, Size mapSize) {
    final relX = localPosition.dx / mapSize.width;
    final relY = localPosition.dy / mapSize.height;

    setState(() {
      _droppedPin = _MockPin(relY, relX, null);
      _pinDropped = true;
      _selectedAddress = null;
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
    _pinAnim.forward(from: 0);

    // Simulate reverse geocoding
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _selectedAddress = _fakeMockAddress(relX, relY);
        });
      }
    });
  }

  void _selectSuggestion(String address) {
    setState(() {
      _selectedAddress = address;
      _pinDropped = true;
      _isSearching = false;
      _searchController.text = address;
      _searchQuery = '';
      // Place mock pin at pseudo-random spot based on address index
      final idx = _allSuggestions.indexOf(address);
      _droppedPin = _MockPin(
        0.2 + (idx * 0.07) % 0.6,
        0.15 + (idx * 0.09) % 0.7,
        address,
      );
    });
    _searchFocus.unfocus();
    _pinAnim.forward(from: 0);
  }

  void _useCurrentLocation() {
    setState(() {
      _droppedPin = _MockPin(0.45, 0.48, 'Current Location');
      _pinDropped = true;
      _selectedAddress = 'F-7/3, Islamabad (Current Location)';
      _isSearching = false;
    });
    _pinAnim.forward(from: 0);
  }

  void _confirmLocation() async {
    if (_selectedAddress == null) return;
    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pop(context, _selectedAddress);
    }
  }

  String _fakeMockAddress(double x, double y) {
    final streets = [
      'Jinnah Avenue, Blue Area',
      'Srinagar Highway, G-8',
      'Park Road, F-6',
      'Faisal Avenue, G-10',
      'Constitution Avenue, D-5',
    ];
    final i = ((x * 10 + y * 7).round()) % streets.length;
    return streets[i];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Full screen map ──────────────────────────────────────────────
          Positioned.fill(child: _buildMockMap()),

          // ── Top overlay: header + search ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                if (_isSearching && _filteredSuggestions.isNotEmpty)
                  _buildSuggestions(),
              ],
            ),
          ),

          // ── Bottom sheet ─────────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomSheet()),

          // ── Floating current-location button ─────────────────────────────
          Positioned(
            right: 16,
            bottom: _pinDropped ? 210 : 130,
            child: _buildCurrentLocationButton(),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1D4ED8).withOpacity(0.97),
            const Color(0xFF2563EB).withOpacity(0.97),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                      'Pick Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Tap on the map or search an address',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.map_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Map',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  // ─── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: const InputDecoration(
                hintText: 'Search address or place name...',
                hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _isSearching = v.isNotEmpty;
              }),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
                _searchFocus.unfocus();
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Search suggestions ────────────────────────────────────────────────────

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredSuggestions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          itemBuilder: (_, i) {
            final s = _filteredSuggestions[i];
            return ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              title: Text(
                s,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              ),
              onTap: () => _selectSuggestion(s),
            );
          },
        ),
      ),
    );
  }

  // ─── Mock Map ──────────────────────────────────────────────────────────────

  Widget _buildMockMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapUp: (d) => _onMapTap(d.localPosition, mapSize),
          child: Stack(
            children: [
              // Map background tiles (simulated grid)
              CustomPaint(size: mapSize, painter: _MockMapPainter()),

              // Road network overlay
              CustomPaint(size: mapSize, painter: _RoadNetworkPainter()),

              // Static pins (recent)
              ..._recentPins.map(
                (pin) => Positioned(
                  left: pin.relX * mapSize.width - 12,
                  top: pin.relY * mapSize.height - 28,
                  child: _buildStaticPin(pin.label ?? ''),
                ),
              ),

              // Dropped pin with animation
              if (_droppedPin != null)
                AnimatedBuilder(
                  animation: _pinBounce,
                  builder: (_, __) {
                    final scale = _pinBounce.value;
                    return Positioned(
                      left: _droppedPin!.relX * mapSize.width - 20,
                      top: _droppedPin!.relY * mapSize.height - 48 * scale,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomCenter,
                        child: _buildDroppedPin(),
                      ),
                    );
                  },
                ),

              // Tap hint overlay (shown until first tap)
              if (!_pinDropped)
                Positioned(
                  bottom: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tap anywhere on the map to drop a pin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticPin(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Icon(Icons.location_on, color: const Color(0xFF94A3B8), size: 22),
      ],
    );
  }

  Widget _buildDroppedPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.4),
                blurRadius: 14,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
        ),
        // Pin stem
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Shadow circle
        Container(
          width: 10,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // ─── Current location button ───────────────────────────────────────────────

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: _useCurrentLocation,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: Color(0xFF2563EB),
          size: 22,
        ),
      ),
    );
  }

  // ─── Bottom sheet ──────────────────────────────────────────────────────────

  Widget _buildBottomSheet() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            if (!_pinDropped) ...[
              // Pre-drop state
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.touch_app_outlined,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No location selected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Tap on the map or search above',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Use current location shortcut
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  label: const Text(
                    'Use My Current Location',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Post-drop state
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Pinned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedAddress ?? 'Fetching address...',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _pinDropped = false;
                      _droppedPin = null;
                      _selectedAddress = null;
                    }),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Accuracy chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.gps_fixed_rounded,
                          size: 11,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'High Accuracy',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap the map to reposition',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedAddress == null || _isConfirming
                      ? null
                      : _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(
                      0xFF2563EB,
                    ).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Confirm This Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Mock Map Painter ──────────────────────────────────────────────────────────

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base map background
    final bgPaint = Paint()..color = const Color(0xFFE8EEF4);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Land blocks (buildings/blocks)
    final blockPaint = Paint()..color = const Color(0xFFD4DCE6);
    final blocks = [
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.05,
        size.width * 0.18,
        size.height * 0.12,
      ),
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.05,
        size.width * 0.22,
        size.height * 0.10,
      ),
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.03,
        size.width * 0.14,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.68,
        size.height * 0.05,
        size.width * 0.16,
        size.height * 0.11,
      ),
      Rect.fromLTWH(
        size.width * 0.86,
        size.height * 0.04,
        size.width * 0.12,
        size.height * 0.13,
      ),
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.22,
        size.width * 0.20,
        size.height * 0.16,
      ),
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.20,
        size.width * 0.16,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.46,
        size.height * 0.21,
        size.width * 0.18,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.68,
        size.height * 0.20,
        size.width * 0.14,
        size.height * 0.17,
      ),
      Rect.fromLTWH(
        size.width * 0.85,
        size.height * 0.22,
        size.width * 0.13,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.44,
        size.width * 0.22,
        size.height * 0.12,
      ),
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.43,
        size.width * 0.14,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.46,
        size.height * 0.42,
        size.width * 0.20,
        size.height * 0.16,
      ),
      Rect.fromLTWH(
        size.width * 0.70,
        size.height * 0.43,
        size.width * 0.16,
        size.height * 0.13,
      ),
      Rect.fromLTWH(
        size.width * 0.88,
        size.height * 0.42,
        size.width * 0.10,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.64,
        size.width * 0.20,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.63,
        size.width * 0.18,
        size.height * 0.16,
      ),
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.62,
        size.width * 0.16,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.68,
        size.height * 0.63,
        size.width * 0.14,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.86,
        size.height * 0.62,
        size.width * 0.12,
        size.height * 0.16,
      ),
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.84,
        size.width * 0.18,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.83,
        size.width * 0.20,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.82,
        size.width * 0.16,
        size.height * 0.16,
      ),
      Rect.fromLTWH(
        size.width * 0.70,
        size.height * 0.83,
        size.width * 0.14,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.86,
        size.height * 0.82,
        size.width * 0.12,
        size.height * 0.15,
      ),
    ];

    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(3)),
        blockPaint,
      );
    }

    // Green park area
    final parkPaint = Paint()..color = const Color(0xFFCBE5CB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.36,
          size.height * 0.66,
          size.width * 0.10,
          size.height * 0.12,
        ),
        const Radius.circular(6),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Road Network Painter ──────────────────────────────────────────────────────

class _RoadNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final majorRoad = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorRoad = Paint()
      ..color = const Color(0xFFF0F4F8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Horizontal major roads
    for (final y in [0.19, 0.40, 0.61, 0.80]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        majorRoad,
      );
    }

    // Vertical major roads
    for (final x in [0.23, 0.45, 0.67, 0.86]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        majorRoad,
      );
    }

    // Diagonal avenue (main arterial)
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.55);
    canvas.drawPath(path, minorRoad);

    // Minor cross roads
    for (final y in [0.30, 0.53, 0.72]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        minorRoad,
      );
    }
    for (final x in [0.11, 0.34, 0.56, 0.77]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        minorRoad,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Data classes ──────────────────────────────────────────────────────────────

class _MockPin {
  final double relY;
  final double relX;
  final String? label;
  const _MockPin(this.relY, this.relX, this.label);
}
