import 'package:flutter/material.dart';
import '../screens/dependents/add_dependent_screen.dart';
import '../screens/medfriends/invite_medfriend_screen.dart';
import '../screens/auth/login_screen.dart';
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

    ListTile(
    leading: const Icon(Icons.login),
    title: const Text('Login'),
    onTap: () {
    Navigator.pop(context);
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => const LoginScreen(),
    ),
    );
    },
    ),
          ],
        ),
      ),
    );
  }
}
