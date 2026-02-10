import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      onTap: onTap,

      // 🔹 IMPORTANT COLOR FIX
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.update),
          label: 'Updates',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication),
          label: 'Medications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts),
          label: 'Manage',
        ),
      ],
    );
  }
}
