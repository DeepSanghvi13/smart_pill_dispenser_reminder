import 'package:flutter/material.dart';
import '../../widgets/settings_tile.dart';
import '../reminders/reminder_troubleshooting_screen.dart';


class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SettingsTile(icon: Icons.settings, title: 'App Settings'),
      const SettingsTile(icon: Icons.security, title: 'Create Account', subtitle: 'Sign up to backup your data'),
      SettingsTile(
        icon: Icons.notifications,
        title: 'Reminders Troubleshooting',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderTroubleshootingScreen())),
      ),
      const SettingsTile(icon: Icons.help, title: 'Help Center'),
    ]);
  }
}