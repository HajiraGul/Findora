import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_snackbar.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const _email = "support@findora.app";
  static const _phone = "+92 300 1112233";
  static const _whatsapp = "+92 300 1112233";
  static const _website = "https://findora-nine.vercel.app";
  static const _hours = "Mon – Sat, 9:00 AM – 6:00 PM (PKT)";

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackBar.success(context, "$label copied to clipboard");
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
          systemOverlayStyle: SystemUiOverlayStyle.dark,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xff17324D),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          title: const Text(
            "Contact Us",
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff0A84FF), Color(0xff0066D6)],
                    ),

                    borderRadius: BorderRadius.circular(28),
                  ),

                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,

                        child: Icon(
                          Icons.headset_mic_rounded,
                          size: 34,
                          color: Color(0xff0A5EB0),
                        ),
                      ),

                      SizedBox(height: 14),

                      Text(
                        "Get In Touch",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "Our support team usually replies within 24 hours.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _contactCard(
                  context,
                  icon: Icons.email_outlined,
                  title: "Email",
                  value: _email,
                ),

                _contactCard(
                  context,
                  icon: Icons.phone_outlined,
                  title: "Helpline",
                  value: _phone,
                ),

                _contactCard(
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "WhatsApp",
                  value: _whatsapp,
                ),

                _contactCard(
                  context,
                  icon: Icons.public_rounded,
                  title: "Website",
                  value: _website,
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xffEAF5FF),
                    borderRadius: BorderRadius.circular(22),
                  ),

                  child: const Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Color(0xff0A5EB0),
                      ),

                      SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Support Hours",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xff17324D),
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              _hours,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,

            decoration: BoxDecoration(
              color: const Color(0xffEAF5FF),
              borderRadius: BorderRadius.circular(16),
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
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xff17324D),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: "Copy",
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: Color(0xff0A5EB0),
            ),
            onPressed: () => _copy(context, title, value),
          ),
        ],
      ),
    );
  }
}
