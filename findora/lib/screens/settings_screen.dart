import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import 'account_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool notifications = true;
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final user = _authController.user.value;
    notifications = user?.notifications ?? true;
    darkMode = user?.darkMode ?? false;
  }

  Future<void> _updatePreferences({bool? notifications, bool? darkMode}) async {
    final previousNotifications = this.notifications;
    final previousDarkMode = this.darkMode;

    if (notifications != null) {
      setState(() => this.notifications = notifications);
    }
    if (darkMode != null) {
      setState(() => this.darkMode = darkMode);
    }

    try {
      await _authController.updatePreferences(
        notifications: notifications,
        darkMode: darkMode,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        this.notifications = previousNotifications;
        this.darkMode = previousDarkMode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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

          // ✅ Same fix as MyPostsScreen
          systemOverlayStyle: SystemUiOverlayStyle.dark,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xff17324D),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          title: const Text(
            "Settings",
            style: TextStyle(
              color: Color(0xff17324D),
              fontWeight: FontWeight.w700,
              fontSize: 26,
            ),
          ),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),

            child: ListView(
              children: [
                _tile(
                  icon: Icons.person_outline_rounded,
                  title: "Account Settings",
                  subtitle: "Manage profile information",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),

                _tile(
                  icon: Icons.notifications_none_rounded,
                  title: "Notifications",
                  subtitle: "Control alerts and updates",

                  trailing: Switch(
                    value: notifications,
                    activeColor: const Color(0xff0A84FF),

                    onChanged: (v) => _updatePreferences(notifications: v),
                  ),
                ),

                _tile(
                  icon: Icons.lock_outline_rounded,
                  title: "Privacy & Security",
                  subtitle: "Password and account protection",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacySecurityScreen(),
                      ),
                    );
                  },
                ),

                _tile(
                  icon: Icons.dark_mode_outlined,
                  title: "Dark Mode",
                  subtitle: "Change app appearance",

                  trailing: Switch(
                    value: darkMode,
                    activeColor: const Color(0xff0A84FF),

                    onChanged: (v) => _updatePreferences(darkMode: v),
                  ),
                ),

                _tile(
                  icon: Icons.help_outline_rounded,
                  title: "Help & Support",
                  subtitle: "FAQ and contact support",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  onPressed: _logoutDialog,

                  icon: const Icon(Icons.logout),

                  label: const Text(
                    "Logout",

                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _deleteAccountDialog,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text(
                    "Delete Account",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xffF4FAFF)],
          ),

          borderRadius: BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,

              decoration: BoxDecoration(
                color: const Color(0xffEAF5FF),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Icon(icon, color: const Color(0xff0A5EB0)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xff17324D),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }

  void _logoutDialog() {
    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: const Text("Logout"),

        content: const Text("Are you sure you want to logout?"),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),

            onPressed: () async {
              await _authController.logout();

              if (!mounted) return;

              Navigator.pop(context);
              Get.offAllNamed(AppRoutes.login);
            },

            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _deleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your Findora account. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _authController.deleteAccount();

                if (!mounted) return;

                Navigator.pop(context);
                Get.offAllNamed(AppRoutes.login);
              } catch (error) {
                if (!mounted) return;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
