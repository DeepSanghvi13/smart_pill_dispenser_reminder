import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pill_reminder/routes/app_routes.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String routeName;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.routeName,
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
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, item.routeName);
      },
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    final menuItems = <DrawerMenuItem>[
      DrawerMenuItem(
        icon: Icons.person_outline,
        title: 'Create Profile',
        routeName: AppRoutes.createProfile,
      ),
      DrawerMenuItem(
        icon: Icons.add_circle_outline,
        title: 'Add Dependent',
        routeName: AppRoutes.addDependent,
      ),
      DrawerMenuItem(
        icon: Icons.group_add,
        title: 'Invite Medfriend',
        routeName: AppRoutes.inviteMedfriend,
      ),
      DrawerMenuItem(
        icon: Icons.supervised_user_circle,
        title: 'Caretaker Mode',
        routeName: AppRoutes.caretakerManagement,
      ),
      if (isAdmin)
        DrawerMenuItem(
          icon: Icons.storage,
          title: 'Database',
          routeName: AppRoutes.databaseStatus,
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
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  AppRoutes.login,
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
