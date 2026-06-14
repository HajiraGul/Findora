import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'my_posts_screen.dart';
import 'my_claims_screen.dart';

/// Combined "My Items" hub that the bottom-nav tab opens. Two chips switch
/// between the user's posts and their claims, reusing each screen's embedded
/// body so there's a single source of truth for both lists.
class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  int _tab = 0; // 0 = My Posts, 1 = My Claims

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xffF5FAFF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xffF5FAFF),
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'My Items',
            style: TextStyle(
              color: Color(0xff17324D),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xff17324D)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _chip('My Posts', Icons.inventory_2_outlined, 0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _chip('My Claims', Icons.verified_user_outlined, 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: const [
                    MyPostsScreen(embedded: true),
                    MyClaimsScreen(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(selected ? 0.18 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
