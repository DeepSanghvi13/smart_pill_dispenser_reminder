import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/routes/app_routes.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _cardTile(
          icon: Icons.security,
          title: 'Create Account',
          subtitle: 'Sign up to backup your data',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.createProfile);
          },
        ),
        _cardTile(
          icon: Icons.notifications_active,
          title: 'Reminders Troubleshooting',
          subtitle: 'Fix reminder issues',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.reminderTroubleshooting);
          },
        ),
        _cardTile(
          icon: Icons.alarm,
          title: 'Manage Reminders',
          subtitle: 'Add, edit, delete and toggle reminders',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.reminders);
          },
        ),
        _cardTile(
          icon: Icons.settings,
          title: 'App Settings',
          subtitle: 'Customize your app',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.appSettings);
          },
        ),
        _cardTile(
          icon: Icons.local_hospital,
          title: 'Doctor/Hospital Review',
          subtitle: 'Send medication concerns for professional review',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.professionalReview);
          },
        ),
        _cardTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Get help and support',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.helpCenter);
          },
        ),
        _cardTile(
          icon: Icons.share,
          title: 'Share Medisafe',
          subtitle: 'Invite friends and family',
          onTap: () {
              Navigator.pushNamed(context, AppRoutes.shareMedisafe);
          },
        ),
      ],
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
