import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pill_reminder/screens/auth/login_screen.dart';
import 'package:smart_pill_reminder/screens/manage/sql_connection_status_screen.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
import '../screens/dependents/add_dependent_screen.dart';
import '../screens/medfriends/invite_medfriend_screen.dart';
import '../screens/medfriends/caretaker_management_screen.dart';
import '../screens/profile/create_profile_screen.dart';

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class DrawerMenuTile extends StatelessWidget {
  final DrawerMenuItem item;

  const DrawerMenuTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      onTap: item.onTap,
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    final menuItems = <DrawerMenuItem>[
      DrawerMenuItem(
        icon: Icons.person_outline,
        title: 'Create Profile',
        onTap: () => _openScreen(context, const CreateProfileScreen()),
      ),
      DrawerMenuItem(
        icon: Icons.add_circle_outline,
        title: 'Add Dependent',
        onTap: () => _openScreen(context, const AddDependentScreen()),
      ),
      DrawerMenuItem(
        icon: Icons.group_add,
        title: 'Invite Medfriend',
        onTap: () => _openScreen(context, const InviteMedfriendScreen()),
      ),
      DrawerMenuItem(
        icon: Icons.supervised_user_circle,
        title: 'Caretaker Mode',
        onTap: () => _openScreen(context, const CaretakerManagementScreen()),
      ),
      if (isAdmin)
        DrawerMenuItem(
          icon: Icons.storage,
          title: 'SQL',
          onTap: () => _openScreen(context, const SqlConnectionStatusScreen()),
        ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            for (final item in menuItems) DrawerMenuTile(item: item),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                context.read<AuthService>().logout();
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
