import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_snackbar.dart';
import '../utils/picked_image_data.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _authController = Get.find<AuthController>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final uniController = TextEditingController();
  final avatarController = TextEditingController();
  final _imagePicker = ImagePicker();
  PickedImageData? _pickedAvatar;

  @override
  void initState() {
    super.initState();
    final user = _authController.user.value;
    nameController.text = user?.fullName ?? '';
    emailController.text = user?.email ?? '';
    phoneController.text = user?.phone ?? '';
    uniController.text = user?.cityOrUniversity ?? '';
    avatarController.text = user?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    uniController.dispose();
    avatarController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      await _authController.updateProfile(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        cityOrUniversity: uniController.text.trim(),
      );

      final avatarUrl = avatarController.text.trim();
      if (avatarUrl.isNotEmpty) {
        await _authController.updateAvatar(avatarUrl: avatarUrl);
      }

      if (!mounted) return;

      AppSnackBar.success(context, 'Profile updated successfully');
    } catch (error) {
      if (!mounted) return;

      AppSnackBar.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 900,
      );
      if (file == null) return;

      final picked = await PickedImageData.fromXFile(file);
      if (!mounted) return;

      setState(() {
        _pickedAvatar = picked;
        avatarController.text = picked.dataUrl;
      });
      AppSnackBar.success(context, 'Profile photo selected');
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Unable to pick image');
    }
  }

  void _showAvatarSourceSheet() {
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
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,

      child: Scaffold(
        backgroundColor: const Color(0xffF5FAFF),

        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,

          // ✅ Added this
          systemOverlayStyle: SystemUiOverlayStyle.dark,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xff17324D),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          title: const Text(
            "Account Settings",
            style: TextStyle(
              color: Color(0xff17324D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                    ),

                    borderRadius: BorderRadius.circular(28),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                _pickedAvatar?.imageProvider ??
                                imageProviderFromStoredValue(
                                  avatarController.text.trim(),
                                ),
                            child:
                                (_pickedAvatar == null &&
                                    imageProviderFromStoredValue(
                                          avatarController.text.trim(),
                                        ) ==
                                        null)
                                ? const Icon(
                                    Icons.person,
                                    size: 55,
                                    color: Color(0xff0A5EB0),
                                  )
                                : null,
                          ),

                          Positioned(
                            right: 0,
                            bottom: 0,

                            child: GestureDetector(
                              onTap: _showAvatarSourceSheet,
                              child: Container(
                                padding: const EdgeInsets.all(8),

                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Color(0xff0A5EB0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Edit Profile",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _field("Full Name", nameController),
                _field("Email", emailController),
                _field("Phone", phoneController),
                _field("University", uniController),

                const SizedBox(height: 25),

                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xff0A84FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _authController.profileLoading.value
                          ? null
                          : _saveChanges,
                      child: _authController.profileLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String title, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: TextField(
        controller: controller,

        decoration: InputDecoration(labelText: title, border: InputBorder.none),
      ),
    );
  }
}
