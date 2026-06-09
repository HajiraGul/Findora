import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFF16A34A),
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.error_outline,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFF2563EB),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
