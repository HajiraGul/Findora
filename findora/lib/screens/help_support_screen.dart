import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
            "Help & Support",
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
                  ),

                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,

                        child: Icon(
                          Icons.support_agent,
                          size: 34,
                          color: Color(0xff0A5EB0),
                        ),
                      ),

                      SizedBox(height: 14),

                      Text(
                        "We're Here To Help",

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

                _tile(
                  context,
                  Icons.help_outline,
                  "FAQs",
                  () => _showFAQ(context),
                ),

                _tile(
                  context,
                  Icons.email_outlined,
                  "Email Support",
                  () => _showEmail(context),
                ),

                _tile(
                  context,
                  Icons.phone_outlined,
                  "Call Helpline",
                  () => _showCall(context),
                ),

                _tile(
                  context,
                  Icons.report_problem_outlined,
                  "Report Issue",
                  () => _showReport(context),
                ),

                _tile(
                  context,
                  Icons.chat_outlined,
                  "Live Chat Support",
                  () => _showChat(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),

      child: Container(
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
            CircleAvatar(
              backgroundColor: const Color(0xffEAF5FF),

              child: Icon(icon, color: const Color(0xff0A5EB0)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xff17324D),
                ),
              ),
            ),

            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  static void _showFAQ(BuildContext context) {
    showDialog(
      context: context,

      builder: (_) => const AlertDialog(
        title: Text("FAQs"),

        content: Text(
          "Q: How to claim item?\nA: Open item → claim.\n\nQ: How verify ownership?\nA: Submit proof.",
        ),
      ),
    );
  }

  static void _showEmail(BuildContext context) {
    showDialog(
      context: context,

      builder: (_) => const AlertDialog(
        title: Text("Email Support"),
        content: Text("support@lostfound.com"),
      ),
    );
  }

  static void _showCall(BuildContext context) {
    showDialog(
      context: context,

      builder: (_) => const AlertDialog(
        title: Text("Call Helpline"),
        content: Text("+92 300 1112233"),
      ),
    );
  }

  static void _showReport(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Report Issue"),

        content: TextField(
          controller: controller,
          maxLines: 4,

          decoration: const InputDecoration(
            hintText: "Write your issue...",
            border: OutlineInputBorder(),
          ),
        ),

        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Issue Submitted")));
            },

            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  static void _showChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Connecting to support chat...")),
    );
  }
}
