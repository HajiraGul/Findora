import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isGuest;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: [
            // index 0 — Home
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            // index 1 — Map
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            // index 2 — Near Me
            const BottomNavigationBarItem(
              icon: Icon(Icons.near_me_outlined),
              activeIcon: Icon(Icons.near_me_rounded),
              label: 'Near Me',
            ),
            // index 3 — BLE Tracker (guests see lock icon)
            BottomNavigationBarItem(
              icon: Icon(
                isGuest
                    ? Icons.bluetooth_disabled_rounded
                    : Icons.bluetooth_searching_rounded,
              ),
              activeIcon: Icon(
                isGuest
                    ? Icons.bluetooth_disabled_rounded
                    : Icons.bluetooth_searching_rounded,
              ),
              label: 'Tracker',
            ),
            // index 4 — Profile (guests see Sign In)
            BottomNavigationBarItem(
              icon: Icon(
                isGuest ? Icons.login_rounded : Icons.person_outline_rounded,
              ),
              activeIcon: Icon(
                isGuest ? Icons.login_rounded : Icons.person_rounded,
              ),
              label: isGuest ? 'Sign In' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
