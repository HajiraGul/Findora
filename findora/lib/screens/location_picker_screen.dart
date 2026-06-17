import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../models/picked_location.dart';
import '../services/location_service.dart';

/// LocationPickerScreen
///
/// A real OpenStreetMap (`flutter_map`) pin-drop interface — no API key or
/// billing required. Tapping the map drops a pin and reverse-geocodes it to a
/// readable address via the on-device `geocoding` plugin.
///
/// Returns: a [PickedLocation] (address + coordinates) to the caller via
/// `Navigator.pop(context, pickedLocation)`.

// Fallback centre — IIU Islamabad (used until the user recenters/searches).
const LatLng _defaultCenter = LatLng(33.7215, 73.0433);

class _LocationSearchResult {
  final String title;
  final String subtitle;
  final LatLng point;

  const _LocationSearchResult({
    required this.title,
    required this.subtitle,
    required this.point,
  });

  factory _LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final displayName = json['display_name']?.toString() ?? 'Selected place';
    final parts = displayName
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0;

    return _LocationSearchResult(
      title: parts.isEmpty ? displayName : parts.first,
      subtitle: parts.length > 1
          ? parts.skip(1).take(3).join(', ')
          : displayName,
      point: LatLng(lat, lon),
    );
  }

  String get address => subtitle.isEmpty ? title : '$title, $subtitle';
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  static const _locationService = LocationService();
  final GetConnect _searchClient = GetConnect();

  LatLng? _pickedPoint;
  String? _selectedAddress;
  bool _resolvingAddress = false; // reverse geocoding in flight
  bool _isConfirming = false;
  bool _isLocating = false; // "use current location" in flight
  bool _isSearching = false; // forward geocoding in flight
  String? _searchError;
  int _searchRun = 0;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  final List<_LocationSearchResult> _searchResults = [];

  // Animation for the pin drop bounce
  late AnimationController _pinAnim;
  late Animation<double> _pinBounce;

  bool get _pinDropped => _pickedPoint != null;

  @override
  void initState() {
    super.initState();
    _pinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pinBounce = CurvedAnimation(parent: _pinAnim, curve: Curves.elasticOut);
    _searchClient.httpClient.timeout = const Duration(seconds: 8);
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pinAnim.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onMapTap(LatLng point) {
    _searchFocus.unfocus();
    setState(() {
      _pickedPoint = point;
      _selectedAddress = null;
      _resolvingAddress = true;
    });
    _pinAnim.forward(from: 0);
    _reverseGeocode(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    String address;
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      address = placemarks.isEmpty
          ? _coordsLabel(point)
          : _formatPlacemark(placemarks.first, point);
    } catch (_) {
      address = _coordsLabel(point);
    }
    if (!mounted) return;
    // Ignore stale results if the pin moved again.
    if (_pickedPoint != point) return;
    setState(() {
      _selectedAddress = address;
      _resolvingAddress = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchError = null;
    });

    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _loadSearchSuggestions(query),
    );
  }

  Future<void> _loadSearchSuggestions(String query) async {
    final run = ++_searchRun;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final response = await _searchClient.get(
        'https://nominatim.openstreetmap.org/search',
        query: {
          'q': query,
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '6',
          'countrycodes': 'pk',
        },
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Findora location picker',
        },
      );
      if (!mounted || run != _searchRun) return;

      final body = response.body;
      if (!response.isOk || body is! List) {
        setState(() => _searchError = 'Couldn\'t load places');
        return;
      }

      setState(() {
        _searchResults
          ..clear()
          ..addAll(
            body
                .whereType<Map>()
                .map(
                  (row) => _LocationSearchResult.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .where(
                  (result) =>
                      result.point.latitude != 0 || result.point.longitude != 0,
                )
                .toList(),
          );
        if (_searchResults.isEmpty) _searchError = 'No matching place found';
      });
    } catch (_) {
      if (!mounted || run != _searchRun) return;
      setState(() => _searchError = 'Couldn\'t load places');
    } finally {
      if (mounted && run == _searchRun) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchFocus.unfocus();
    _searchDebounce?.cancel();
    if (_searchResults.isNotEmpty) {
      _selectSearchResult(_searchResults.first);
      return;
    }

    setState(() => _isSearching = true);
    try {
      await _loadSearchSuggestions(trimmed);
      if (!mounted) return;
      if (_searchResults.isEmpty) {
        _showSnack('No matching place found');
        return;
      }
      _selectSearchResult(_searchResults.first);
    } catch (_) {
      if (mounted) _showSnack('Couldn\'t find that address');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_LocationSearchResult result) {
    _searchController.text = result.title;
    _searchFocus.unfocus();
    _mapController.move(result.point, 16);
    setState(() {
      _pickedPoint = result.point;
      _selectedAddress = result.address;
      _resolvingAddress = false;
      _searchError = null;
      _searchResults.clear();
    });
    _pinAnim.forward(from: 0);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (!result.isOk) {
      _showSnack(_locationError(result.status));
      return;
    }
    final point = LatLng(result.latitude!, result.longitude!);
    _mapController.move(point, 16);
    _onMapTap(point);
  }

  void _confirmLocation() async {
    if (_pickedPoint == null || _selectedAddress == null) return;
    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pop(
      context,
      PickedLocation(
        address: _selectedAddress!,
        latitude: _pickedPoint!.latitude,
        longitude: _pickedPoint!.longitude,
      ),
    );
  }

  void _clearPin() {
    setState(() {
      _pickedPoint = null;
      _selectedAddress = null;
      _resolvingAddress = false;
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatPlacemark(Placemark p, LatLng point) {
    final parts = <String>[];
    for (final value in [
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
    ]) {
      final v = (value ?? '').trim();
      if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
    }
    if (parts.isEmpty) return _coordsLabel(point);
    return parts.take(3).join(', ');
  }

  String _coordsLabel(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

  String _locationError(LocationStatus status) {
    switch (status) {
      case LocationStatus.serviceDisabled:
        return 'Turn on location services to use your current location';
      case LocationStatus.deniedForever:
      case LocationStatus.denied:
        return 'Location permission denied';
      default:
        return 'Couldn\'t get your current location';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Full screen map ──────────────────────────────────────────────
          Positioned.fill(child: _buildMap()),

          // ── Top overlay: header + search ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildSearchSuggestions(),
              ],
            ),
          ),

          // ── Attribution (OSM tile usage policy) ──────────────────────────
          Positioned(
            left: 12,
            bottom: _pinDropped ? 232 : 152,
            child: _buildAttribution(),
          ),

          // ── Floating current-location button ─────────────────────────────
          Positioned(
            right: 16,
            bottom: _pinDropped ? 232 : 152,
            child: _buildCurrentLocationButton(),
          ),

          // ── Bottom sheet ─────────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomSheet()),
        ],
      ),
    );
  }

  // ─── Map ─────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
        onTap: (_, point) => _onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.findora.app',
          maxZoom: 19,
        ),
        if (_pickedPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _pickedPoint!,
                width: 46,
                height: 56,
                alignment: Alignment.topCenter,
                child: AnimatedBuilder(
                  animation: _pinBounce,
                  builder: (_, child) => Transform.scale(
                    scale: _pinBounce.value.clamp(0.0, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                  child: _buildDroppedPin(),
                ),
              ),
            ],
          ),
      ],
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
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1D4ED8).withValues(alpha: 0.97),
            const Color(0xFF2563EB).withValues(alpha: 0.97),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              textInputAction: TextInputAction.search,
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
              onChanged: _onSearchChanged,
              onSubmitted: _searchAddress,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchDebounce?.cancel();
                _searchController.clear();
                setState(() {
                  _isSearching = false;
                  _searchError = null;
                  _searchResults.clear();
                });
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

  Widget _buildSearchSuggestions() {
    final hasQuery = _searchController.text.trim().length >= 2;
    final shouldShow =
        _searchFocus.hasFocus &&
        hasQuery &&
        (_searchResults.isNotEmpty || _searchError != null || _isSearching);
    if (!shouldShow) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _searchResults.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (_isSearching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.search_off_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isSearching
                            ? 'Searching places...'
                            : (_searchError ?? 'No matching place found'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 52,
                  color: Color(0xFFE2E8F0),
                ),
                itemBuilder: (_, index) {
                  final result = _searchResults[index];
                  return InkWell(
                    onTap: () => _selectSearchResult(result),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.place_outlined,
                              size: 17,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ─── Current location button ───────────────────────────────────────────────

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: _isLocating ? null : _useCurrentLocation,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLocating
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(
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
            color: Colors.black.withValues(alpha: 0.12),
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
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (!_pinDropped) _buildPreDropBody() else _buildPostDropBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreDropBody() {
    return Column(
      children: [
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
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLocating ? null : _useCurrentLocation,
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
              side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostDropBody() {
    return Column(
      children: [
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
                    _resolvingAddress
                        ? 'Fetching address...'
                        : (_selectedAddress ?? 'Selected location'),
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
              onTap: _clearPin,
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                _coordsLabel(_pickedPoint!),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
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
            onPressed: _resolvingAddress || _isConfirming
                ? null
                : _confirmLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(
                0xFF2563EB,
              ).withValues(alpha: 0.5),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
    );
  }
}
