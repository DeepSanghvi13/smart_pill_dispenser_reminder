import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
import '../screens/dependents/add_dependent_screen.dart';
import '../screens/medfriends/invite_medfriend_screen.dart';
import '../screens/medfriends/caretaker_management_screen.dart';
import '../screens/profile/create_profile_screen.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Create Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(),

            // Add Dependent
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Dependent'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddDependentScreen(),
                  ),
                );
              },
            ),

            // Invite Medfriend
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Invite Medfriend'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InviteMedfriendScreen(),
                  ),
                );
              },
            ),

            // Caretaker Management
            ListTile(
              leading: const Icon(Icons.supervised_user_circle),
              title: const Text('Caretaker Mode'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaretakerManagementScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                authService.logout();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}


