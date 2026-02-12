import 'package:flutter/material.dart';

import 'app_settings_screen.dart';
import 'reminder_troubleshooting_screen.dart';
import 'create_profile_screen.dart';
import 'share_medisafe_screen.dart';
import 'help_center_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _cardTile(
            icon: Icons.security,
            title: 'Create Account',
            subtitle: 'Sign up to backup your data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateProfileScreen(), // ❌ no const
                ),
              );
            },
          ),

          _cardTile(
            icon: Icons.notifications_active,
            title: 'Reminders Troubleshooting',
            subtitle: 'Fix reminder issues',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReminderTroubleshootingScreen(), // ❌ no const
                ),
              );
            },
          ),

          _cardTile(
            icon: Icons.settings,
            title: 'App Settings',
            subtitle: 'Customize your app',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppSettingsScreen(), // ❌ no const
                ),
              );
            },
          ),

          _cardTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelpCenterScreen(),
                ),
              );
            },
          ),

          _cardTile(
            icon: Icons.share,
            title: 'Share Medisafe',
            subtitle: 'Invite friends and family',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShareMedisafeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- CARD TILE ----------
  Widget _cardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D4F8B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
