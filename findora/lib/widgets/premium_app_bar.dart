import 'package:flutter/material.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? action;

  const PremiumAppBar({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xff0A3D62),
        ),
      ),
      actions: [
        if (action != null)
          Padding(padding: const EdgeInsets.only(right: 16), child: action!),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
