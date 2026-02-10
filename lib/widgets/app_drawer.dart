import 'package:flutter/material.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: const [
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Guest'),
              subtitle: Text('Create Profile'),
            ),
            Divider(),
            ListTile(leading: Icon(Icons.add_circle), title: Text('Add Dependent')),
            ListTile(leading: Icon(Icons.group), title: Text('Invite Medfriend')),
            ListTile(leading: Icon(Icons.verified), title: Text('Verification Code')),
            ListTile(leading: Icon(Icons.login), title: Text('Login')),
          ],
        ),
      ),
    );
  }
}