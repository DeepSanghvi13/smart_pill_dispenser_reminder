import 'package:flutter/material.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _section('Settings'),
          _item(Icons.settings, 'General Settings'),
          _item(Icons.place, 'My Places'),

          _section('Account'),
          _item(Icons.verified, 'Verification Code'),
          _item(Icons.key, 'Open Account',
              subtitle: 'Create a free Medisafe account'),
          _item(Icons.login, 'Login',
              subtitle: 'Login with an existing account'),
          _item(Icons.lock, 'Passcode',
              subtitle: 'Use a passcode to enter the app'),
          _item(Icons.delete, 'Delete This Account',
              subtitle: 'Permanently delete account and information',
              color: Colors.red),

          _section('Premium Settings'),
          _item(Icons.workspace_premium, 'Subscribe to Medisafe'),

          _section('General'),
          _item(Icons.share, 'Help Us and Share Medisafe'),
          _item(Icons.star, 'Rate Medisafe'),
          _item(Icons.mail, 'Send Feedback'),
          _item(Icons.info, 'About'),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _item(
      IconData icon,
      String title, {
        String? subtitle,
        Color color = Colors.grey,
      }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
