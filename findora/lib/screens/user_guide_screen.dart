import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static const List<_GuideStep> _steps = [
    _GuideStep(
      Icons.search_rounded,
      "Report a lost item",
      "Tap “Report Lost”, add a photo, a clear description and where you last "
      "saw it. Findora starts looking for matches straight away.",
    ),
    _GuideStep(
      Icons.add_a_photo_outlined,
      "Post something you found",
      "Found an item? Tap “Report Found”, upload a photo and note where you "
      "found it. Keep unique details private so only the real owner can claim.",
    ),
    _GuideStep(
      Icons.auto_awesome_rounded,
      "Get smart match suggestions",
      "Our matching engine compares lost and found posts and notifies you when "
      "something looks like yours.",
    ),
    _GuideStep(
      Icons.verified_user_outlined,
      "Claim and verify ownership",
      "Open the item and tap “Claim”. Answer the verification questions and add "
      "proof so the finder can confirm it’s really yours.",
    ),
    _GuideStep(
      Icons.chat_bubble_outline_rounded,
      "Chat securely",
      "Once a claim is in progress, use the in-app chat to arrange a safe "
      "handover. Keep all messages inside Findora.",
    ),
    _GuideStep(
      Icons.handshake_outlined,
      "Meet safely & close the loop",
      "Meet in a public place, confirm proof, then mark the item as returned so "
      "it stops appearing in search.",
    ),
  ];

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
            "User Guide",
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "How Findora Works",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        "Six simple steps to reunite people with their "
                        "belongings.",
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                for (int i = 0; i < _steps.length; i++)
                  _stepTile(i + 1, _steps[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepTile(int number, _GuideStep step) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 50,
                width: 50,

                decoration: BoxDecoration(
                  color: const Color(0xffEAF5FF),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(step.icon, color: const Color(0xff0A5EB0)),
              ),

              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  height: 22,
                  width: 22,
                  alignment: Alignment.center,

                  decoration: const BoxDecoration(
                    color: Color(0xff0A84FF),
                    shape: BoxShape.circle,
                  ),

                  child: Text(
                    "$number",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xff17324D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  step.body,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String body;

  const _GuideStep(this.icon, this.title, this.body);
}
