import 'package:flutter/material.dart';

class HelpArticlesScreen extends StatelessWidget {
  const HelpArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Articles'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('How to add a medicine'),
            subtitle: Text('Steps to add and manage medicines'),
          ),
          Divider(),
          ListTile(
            title: Text('How reminders work'),
            subtitle: Text('Understand reminder notifications'),
          ),
          Divider(),
          ListTile(
            title: Text('Edit or delete medicines'),
            subtitle: Text('Manage your medicine list'),
          ),
          Divider(),
          ListTile(
            title: Text('Profile and account help'),
            subtitle: Text('Manage your profile and account'),
          ),
        ],
      ),
    );
  }
}
