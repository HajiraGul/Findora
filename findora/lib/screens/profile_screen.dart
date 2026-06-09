import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/picked_image_data.dart';
import 'my_posts_screen.dart';
import 'my_claims_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  AuthController get _authController => Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,

      child: Scaffold(
        backgroundColor: const Color(0xffF5FAFF),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Column(
              children: [
                // 🔹 Back Button
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),

                      onTap: () {
                        Navigator.pop(context);
                      },

                      child: Container(
                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: Color(0xff17324D),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Obx(() => _profileHeader()),

                const SizedBox(height: 22),

                _statsSection(),

                const SizedBox(height: 24),

                _actionButtons(context),

                const SizedBox(height: 24),

                _aboutCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final user = _authController.user.value;
    final displayName = user?.fullName ?? 'Findora User';
    final subtitle = user?.cityOrUniversity ?? 'Findora Community';
    final avatarUrl = user?.avatarUrl ?? '';
    final avatarImage = imageProviderFromStoredValue(avatarUrl);

    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff0A84FF), Color(0xff0066D6)],
        ),

        borderRadius: BorderRadius.circular(30),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.18),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,

            children: [
              Container(
                padding: const EdgeInsets.all(4),

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),

                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(
                          Icons.person,
                          size: 52,
                          color: Color(0xff0A5EB0),
                        )
                      : null,
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xff0A5EB0),
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _statsSection() {
    return Row(
      children: [
        Expanded(child: _statCard("24", "Posts")),

        const SizedBox(width: 12),

        Expanded(child: _statCard("11", "Claims")),

        const SizedBox(width: 12),

        Expanded(child: _statCard("7", "Matches")),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        children: [
          Text(
            value,

            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xff0A5EB0),
            ),
          ),

          const SizedBox(height: 6),

          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
              );
            },

            child: _actionCard(Icons.inventory_2_rounded, "My Posts"),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyClaimsScreen()),
              );
            },

            child: _actionCard(Icons.verified_user_rounded, "My Claims"),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffEAF5FF), Colors.white],
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xff0A5EB0)),

          const SizedBox(height: 10),

          Text(
            title,

            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff17324D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "About",

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff17324D),
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Software Engineering student passionate about building secure and helpful digital solutions for campus communities.",

            style: TextStyle(height: 1.6, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
