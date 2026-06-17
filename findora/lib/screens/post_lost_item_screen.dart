import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/item_controller.dart';
import '../models/picked_location.dart';
import 'location_picker_screen.dart';
import '../utils/picked_image_data.dart';

class PostLostItemScreen extends StatefulWidget {
  const PostLostItemScreen({super.key});

  @override
  State<PostLostItemScreen> createState() => _PostLostItemScreenState();
}

class _PostLostItemScreenState extends State<PostLostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rewardController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  String? _selectedColor;
  bool _offerReward = false;
  bool _isLoading = false;
  String? _pickedLocation;
  double? _pickedLat;
  double? _pickedLng;
  final _imagePicker = ImagePicker();
  final List<PickedImageData> _photos = [];

  static const _categories = [
    ('Electronics', Icons.phone_iphone_rounded, Color(0xFF0891B2)),
    ('Accessories', Icons.watch_rounded, Color(0xFF7C3AED)),
    ('Bags', Icons.backpack_outlined, Color(0xFF059669)),
    ('Keys', Icons.key_rounded, Color(0xFFDC2626)),
    ('Jewelry', Icons.diamond_outlined, Color(0xFFD97706)),
    ('Documents', Icons.badge_outlined, Color(0xFF2563EB)),
    ('Clothing', Icons.checkroom_outlined, Color(0xFFDB2777)),
    ('Other', Icons.category_outlined, Color(0xFF64748B)),
  ];
  static const _colors = [
    ('Black', Color(0xFF111827)),
    ('White', Color(0xFFFFFFFF)),
    ('Blue', Color(0xFF2563EB)),
    ('Red', Color(0xFFEF4444)),
    ('Brown', Color(0xFF92400E)),
    ('Silver', Color(0xFFCBD5E1)),
    ('Yellow', Color(0xFFF59E0B)),
    ('Green', Color(0xFF16A34A)),
    ('Other', Color(0xFFA78BFA)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _rewardController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _pickLocation() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _pickedLocation = result.address;
        _pickedLat = result.latitude;
        _pickedLng = result.longitude;
        _locationController.text = result.address;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= 4) {
      _showSnackBar('Maximum 4 photos allowed', isError: true);
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (file == null) return;

      final picked = await PickedImageData.fromXFile(file);
      if (!mounted) return;
      setState(() => _photos.add(picked));
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') || msg.contains('denied')) {
        _showSnackBar(
          'Permission denied. Please allow access in Settings.',
          isError: true,
        );
      } else {
        _showSnackBar('Unable to pick image', isError: true);
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    () => _pickPhoto(ImageSource.gallery),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    () => _pickPhoto(ImageSource.camera),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }
    if (_selectedColor == null) {
      _showSnackBar('Please select the item color', isError: true);
      return;
    }
    if (_pickedLocation == null) {
      _showSnackBar('Please set the last seen location', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ctrl = Get.find<ItemController>();
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'status': 'lost',
        'color': _selectedColor,
        'location': {
          'address': _pickedLocation,
          if (_pickedLat != null) 'latitude': _pickedLat,
          if (_pickedLng != null) 'longitude': _pickedLng,
        },
        if (_offerReward && _rewardController.text.isNotEmpty)
          'reward': {
            'enabled': true,
            'amount': double.tryParse(_rewardController.text) ?? 0,
          },
        if (_photos.isNotEmpty)
          'images': _photos.map((p) => p.dataUrl).toList(),
      };
      final ok = await ctrl.createItem(payload);
      if (!mounted) return;
      if (ok) {
        _showSuccessDialog();
      } else {
        _showSnackBar('Failed to post item. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Report Posted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your lost item report for "${_titleController.text}" has been posted. The community will help you find it.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Item Details'),
                    const SizedBox(height: 12),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildCategoryPicker(),
                    const SizedBox(height: 16),
                    _buildColorPicker(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Last Seen Location'),
                    const SizedBox(height: 12),
                    _buildLocationPicker(),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Photos'),
                    const SizedBox(height: 4),
                    const Text(
                      'Add up to 4 photos to help identify your item',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    _buildPhotoGrid(),
                    const SizedBox(height: 24),
                    _buildRewardSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Your post will be reviewed and visible to the community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
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
  }

  Widget _buildHeader() {
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LOST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Post Lost Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Step 2 of 2 — Fill in details',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
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

  Widget _buildTitleField() {
    return _FormCard(
      child: TextFormField(
        controller: _titleController,
        decoration: _inputDecoration(
          label: 'Item Title',
          hint: 'e.g. Black Leather Wallet',
          icon: Icons.label_outline_rounded,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Title is required';
          if (v.trim().length < 3) return 'Title too short';
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat.$1;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? cat.$3.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cat.$3 : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.$2,
                      size: 16,
                      color: isSelected ? cat.$3 : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? cat.$3 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return _FormCard(
      child: TextFormField(
        controller: _descController,
        maxLines: 4,
        decoration: _inputDecoration(
          label: 'Description',
          hint:
              'Describe the item in detail — color, brand, size, unique markings...',
          icon: Icons.notes_rounded,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Description is required';
          if (v.trim().length < 20)
            return 'Please provide more detail (min 20 chars)';
          return null;
        },
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((entry) {
            final name = entry.$1;
            final color = entry.$2;
            final isSelected = _selectedColor == name;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF1F1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pickedLocation != null
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: _pickedLocation != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _pickedLocation != null
                    ? const Color(0xFF2563EB).withOpacity(0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: _pickedLocation != null
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedLocation != null
                        ? 'Location Set'
                        : 'Tap to set location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _pickedLocation != null
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (_pickedLocation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _pickedLocation!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Drop a pin on the map where you last had this item',
                      style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              _pickedLocation != null
                  ? Icons.edit_location_alt_outlined
                  : Icons.add_location_alt_outlined,
              color: const Color(0xFF2563EB),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              // Add photo button (hidden once 4 photos are added)
              if (_photos.length < 4)
                GestureDetector(
                  onTap: _showPhotoSourceSheet,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Existing photos
              ..._photos.asMap().entries.map(
                (e) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(e.value.bytes, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removePhoto(e.key),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_photos.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Photos help the community identify your item faster',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _offerReward
              ? const Color(0xFFFCD34D)
              : const Color(0xFFE2E8F0),
          width: _offerReward ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Toggle row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _offerReward
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: _offerReward
                        ? const Color(0xFFD97706)
                        : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer a Reward',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Optional — increases chances of recovery',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _offerReward,
                  onChanged: (v) => setState(() => _offerReward = v),
                  activeColor: const Color(0xFFD97706),
                  activeTrackColor: const Color(0xFFFDE68A),
                ),
              ],
            ),
          ),

          // Reward amount field
          if (_offerReward) ...[
            const Divider(height: 1, color: Color(0xFFFDE68A)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: TextFormField(
                controller: _rewardController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: 'Reward Amount (PKR)',
                  hint: 'e.g. 2000',
                  icon: Icons.attach_money_rounded,
                ).copyWith(filled: true, fillColor: const Color(0xFFFFFBEB)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          disabledBackgroundColor: const Color(0xFFDC2626).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: const Color(0xFFDC2626).withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.publish_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Post Lost Item Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Shared Helpers ────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
    labelStyle: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
