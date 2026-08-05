import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pill_reminder/routes/app_routes.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
import 'package:smart_pill_reminder/services/database_service.dart';
import 'package:smart_pill_reminder/models/user_profile.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<AuthService>().currentUser ?? 'guest';

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header with Profile Info
          FutureBuilder<UserProfile?>(
            future: DatabaseService().getUserProfileData(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final name = profile?.fullName ?? email.split('@').first;
              final picPath = profile?.profilePicture;

              return DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: picPath != null && picPath.isNotEmpty
                          ? FileImage(File(picPath))
                          : null,
                      child: picPath == null
                          ? Icon(Icons.person, size: 30, color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Drawer Menu Tiles
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushNamed(context, AppRoutes.createProfile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('My Photos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.myPhotos);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Pushes Settings Screen (index 3 of HomeScreen bottom nav or navigates to manage route)
              Navigator.pushNamed(context, AppRoutes.manage);
            },
          ),
          const Divider(),
          const Spacer(),
          const Divider(),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Logout', style: TextStyle(color: Colors.orange)),
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext); // Close dialog
                        await context.read<AuthService>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context, rootNavigator: true)
                            .pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
