import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'items_near_me_screen.dart';
import 'map_view_screen.dart';

class LocationHubScreen extends StatefulWidget {
  const LocationHubScreen({super.key});

  @override
  State<LocationHubScreen> createState() => _LocationHubScreenState();
}

class _LocationHubScreenState extends State<LocationHubScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF8FAFC),
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'Location',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF17324D)),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                child: Row(
                  children: [
                    Expanded(child: _chip('Map', Icons.map_outlined, 0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _chip('Near Me', Icons.near_me_outlined, 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: const [
                    MapViewScreen(embedded: true),
                    ItemsNearMeScreen(embedded: true),
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
              color: Colors.blue.withValues(alpha: selected ? 0.18 : 0.06),
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
