import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      "How do I report a lost item?",
      "Open the home screen and tap “Report Lost”. Add a clear photo, a short "
      "description, the category and the place you last saw it. The more detail "
      "you add, the easier it is for finders to match it.",
    ),
    _FaqItem(
      "How do I post an item I found?",
      "Tap “Report Found” from the home screen, upload a photo and describe "
      "where and when you found it. Avoid sharing unique identifiers publicly so "
      "the real owner can prove ownership.",
    ),
    _FaqItem(
      "How do I claim an item?",
      "Open the item you believe is yours and tap “Claim”. Answer the "
      "verification questions and add any proof of ownership. The person who "
      "posted it will review your claim before it’s approved.",
    ),
    _FaqItem(
      "How is ownership verified?",
      "When you claim an item, you’ll be asked details only the true owner "
      "would know (marks, contents, serial numbers). The finder reviews these "
      "answers and approves or rejects the claim.",
    ),
    _FaqItem(
      "How do I chat with the other person?",
      "Once a claim is in progress, a secure in-app chat opens so you can "
      "arrange a safe handover. Keep all conversation inside Findora for your "
      "own protection.",
    ),
    _FaqItem(
      "Will I be notified about matches?",
      "Yes. Findora automatically suggests possible matches and sends you a "
      "notification when a found item looks like your lost one. Make sure "
      "notifications are enabled in Settings.",
    ),
    _FaqItem(
      "How do I stay safe during a handover?",
      "Always meet in a public place during daytime, bring a friend if "
      "possible, and confirm proof of ownership before handing anything over. "
      "Never share financial details.",
    ),
    _FaqItem(
      "How do I edit or delete my post?",
      "Go to “My Posts”, open the item and use the edit or delete option. "
      "Resolved items can be marked as returned so they stop appearing in "
      "search results.",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? _faqs
        : _faqs
              .where(
                (f) =>
                    f.question.toLowerCase().contains(_query) ||
                    f.answer.toLowerCase().contains(_query),
              )
              .toList();

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
            "FAQs",
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
                          Icons.quiz_rounded,
                          color: Color(0xff0A5EB0),
                          size: 28,
                        ),
                      ),

                      SizedBox(width: 16),

                      Expanded(
                        child: Text(
                          "Quick answers to the most common questions about Findora.",

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

                const SizedBox(height: 20),

                Container(
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
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),

                    decoration: const InputDecoration(
                      hintText: "Search questions...",
                      icon: Icon(
                        Icons.search_rounded,
                        color: Color(0xff0A5EB0),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.blue.withOpacity(.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No matching questions found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...results.map(_faqTile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _faqTile(_FaqItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

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

      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),

        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: const Color(0xff0A5EB0),
          collapsedIconColor: const Color(0xff0A5EB0),

          leading: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xffEAF5FF),
            child: Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: Color(0xff0A5EB0),
            ),
          ),

          title: Text(
            item.question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xff17324D),
              fontSize: 15,
            ),
          ),

          children: [
            Text(
              item.answer,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
