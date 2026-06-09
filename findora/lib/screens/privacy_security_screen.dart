import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool twoFactor = true;
  bool biometric = false;
  final _authController = Get.find<AuthController>();

  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = _authController.user.value;
    twoFactor = user?.twoFactor ?? false;
    biometric = user?.biometric ?? false;
  }

  @override
  void dispose() {
    oldPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveSecuritySettings() async {
    if (newPassController.text.isNotEmpty ||
        oldPassController.text.isNotEmpty ||
        confirmPassController.text.isNotEmpty) {
      if (newPassController.text != confirmPassController.text) {
        _showError('Passwords do not match');
        return;
      }

      try {
        await _authController.updatePassword(
          currentPassword: oldPassController.text,
          newPassword: newPassController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated. Please sign in again.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Get.offAllNamed(AppRoutes.login);
      } catch (error) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }

    await _savePreferenceToggles();
  }

  Future<void> _savePreferenceToggles() async {
    try {
      await _authController.updatePreferences(
        twoFactor: twoFactor,
        biometric: biometric,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Security Settings Updated"),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
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
            "Privacy & Security",
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
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                    ),

                    borderRadius: BorderRadius.circular(28),
                  ),

                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,

                        child: Icon(
                          Icons.lock_rounded,
                          color: Color(0xff0A5EB0),
                          size: 28,
                        ),
                      ),

                      SizedBox(width: 16),

                      Expanded(
                        child: Text(
                          "Your account is protected with advanced security settings.",

                          style: TextStyle(
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _field("Current Password", oldPassController),
                _field("New Password", newPassController),
                _field("Confirm Password", confirmPassController),

                const SizedBox(height: 12),

                _switchTile(
                  title: "Two-Factor Authentication",
                  subtitle: "Extra protection for login",
                  value: twoFactor,

                  onChanged: (v) {
                    setState(() => twoFactor = v);
                  },
                ),

                _switchTile(
                  title: "Biometric Login",
                  subtitle: "Fingerprint / Face unlock",
                  value: biometric,

                  onChanged: (v) {
                    setState(() => biometric = v);
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xff0A84FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    onPressed: _saveSecuritySettings,
                    child: Obx(
                      () => _authController.profileLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save Security Settings",
                              style: TextStyle(fontWeight: FontWeight.w600),
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
        obscureText: true,

        decoration: InputDecoration(labelText: title, border: InputBorder.none),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xff17324D),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeColor: const Color(0xff0A84FF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
