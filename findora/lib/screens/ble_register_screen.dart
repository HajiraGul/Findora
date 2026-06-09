import 'package:flutter/material.dart';
import '../models/claim_model.dart';
import 'ble_tracking_screen.dart';

class BleRegisterScreen extends StatefulWidget {
  const BleRegisterScreen({super.key});

  @override
  State<BleRegisterScreen> createState() => _BleRegisterScreenState();
}

class _BleRegisterScreenState extends State<BleRegisterScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _tagFound = false;
  String? _foundTagId;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final _itemNameController = TextEditingController();
  String _selectedCategory = 'Bags & Wallets';

  /// 0 = Scan  |  1 = Details  |  2 = Success
  int _currentStep = 0;

  final List<String> _categories = [
    'Bags & Wallets',
    'Electronics',
    'Keys',
    'Clothing',
    'Accessories',
    'Books',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  // ─── BLE Scan simulation ──────────────────────────────────────────────────

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _tagFound = false;
      _foundTagId = null;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _tagFound = true;
      _foundTagId = 'FND-${_generateTagId()}';
    });
  }

  String _generateTagId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      6,
      (i) => chars[(DateTime.now().millisecond + i * 7) % chars.length],
    ).join();
  }

  // ─── Step actions ─────────────────────────────────────────────────────────

  void _goToDetails() => setState(() => _currentStep = 1);

  void _registerTag() {
    if (_itemNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter the item name', isError: true);
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _resetWizard() {
    setState(() {
      _currentStep = 0;
      _tagFound = false;
      _foundTagId = null;
      _itemNameController.clear();
    });
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _currentStep == 0
                  ? _buildScanStep()
                  : _currentStep == 1
                  ? _buildDetailsStep()
                  : _buildSuccessStep(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

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
              // ── Back button ─────────────────────────────────────────────
              // On step 0/1 → pop back to BleTrackingScreen.
              // On step 2 (success) → also pop; user uses the explicit
              //   "View BLE Tracker" button for pushReplacement.
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.bluetooth_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register BLE Tag',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Pair a Bluetooth tag to your item',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step Indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final steps = ['Scan Tag', 'Item Details', 'Registered'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          final isLast = i == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isDone
                              ? Icons.check_rounded
                              : i == 0
                              ? Icons.bluetooth_searching_rounded
                              : i == 1
                              ? Icons.edit_outlined
                              : Icons.verified_rounded,
                          color: isDone || isActive
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 24,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < _currentStep
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Step 0: Scan ─────────────────────────────────────────────────────────

  Widget _buildScanStep() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_isScanning) ...[
                    Container(
                      width: 160 * _pulseAnim.value,
                      height: 160 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 130 * _pulseAnim.value,
                      height: 130 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _tagFound
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _tagFound
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2563EB),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_tagFound
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2563EB))
                                  .withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _tagFound
                          ? Icons.check_circle_outline_rounded
                          : Icons.bluetooth_searching_rounded,
                      size: 52,
                      color: _tagFound
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            _tagFound
                ? 'BLE Tag Found!'
                : _isScanning
                ? 'Scanning for BLE tags...'
                : 'Ready to Scan',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tagFound
                ? 'Tag ID: ${_foundTagId ?? ''}\nTap Continue to set up your item'
                : _isScanning
                ? 'Make sure your BLE tag is nearby\nand powered on'
                : 'Press the button below to start scanning\nfor nearby BLE tags',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          if (_tagFound) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth_connected_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Findora BLE Tag',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          _foundTagId ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF16A34A),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Continue → step 1 ──────────────────────────────────────
            _buildPrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onTap: _goToDetails,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _tagFound = false;
                _foundTagId = null;
              }),
              child: const Text(
                'Scan again',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ] else
            _buildPrimaryButton(
              label: _isScanning ? 'Scanning...' : 'Start Scanning',
              icon: Icons.bluetooth_searching_rounded,
              onTap: _isScanning ? null : _startScan,
              isLoading: _isScanning,
            ),
          const SizedBox(height: 32),
          _buildBleInfoCard(),
        ],
      ),
    );
  }

  // ─── Step 1: Details ──────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF16A34A).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth_connected_rounded,
                  color: Color(0xFF16A34A),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tag ID: $_foundTagId',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Item Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us about the item this tag will be attached to',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Item Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _itemNameController,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'e.g. My Black Backpack',
              hintStyle: const TextStyle(
                color: Color(0xFFBEC5CF),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.label_outline_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.2),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Attachment Tips',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _tipRow('Attach the tag to a non-visible part of the item'),
                _tipRow(
                  'Ensure the tag is firmly attached and won\'t fall off',
                ),
                _tipRow('Replace the battery every 6–12 months for best range'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // ── Register → step 2 ──────────────────────────────────────────
          _buildPrimaryButton(
            label: 'Register Tag',
            icon: Icons.check_rounded,
            onTap: _registerTag,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              // ── Back to scan → step 0 (setState, no Navigator) ─────────
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text(
                'Back to Scan',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Success ──────────────────────────────────────────────────────

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF16A34A),
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tag Registered!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_itemNameController.text} has been paired with tag $_foundTagId',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                _summaryRow(
                  Icons.label_outline_rounded,
                  'Item Name',
                  _itemNameController.text,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _summaryRow(
                  Icons.category_outlined,
                  'Category',
                  _selectedCategory,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _summaryRow(
                  Icons.bluetooth_rounded,
                  'Tag ID',
                  _foundTagId ?? '',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _summaryRow(
                  Icons.battery_charging_full_rounded,
                  'Battery',
                  '100%',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _summaryRow(
                  Icons.wifi_tethering_rounded,
                  'Status',
                  'Active & Tracking',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── "View BLE Tracker" → pushReplacement to BleTrackingScreen ──
          // pushReplacement removes this screen from the stack so pressing
          // back on BleTrackingScreen goes to HomeScreen, not here.
          _buildPrimaryButton(
            label: 'View BLE Tracker',
            icon: Icons.radar_rounded,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BleTrackingScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ── "Register another tag" → reset wizard in place (setState) ──
          TextButton(
            onPressed: _resetWizard,
            child: const Text(
              'Register another tag',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared helper widgets ────────────────────────────────────────────────

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 5, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'How BLE Tracking Works',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow('1.', 'Attach a BLE tag to your valuable item'),
          _infoRow('2.', 'Register the tag in the Findora app'),
          _infoRow('3.', 'If lost, nearby phones detect the BLE signal'),
          _infoRow('4.', 'You receive the last-known location instantly'),
        ],
      ),
    );
  }

  Widget _infoRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1D4ED8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
