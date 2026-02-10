import 'package:flutter/material.dart';


class ReminderTroubleshootingScreen extends StatelessWidget {
  const ReminderTroubleshootingScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Troubleshooting')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Step 4: Adjust advanced battery settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Ensure you get your notifications on time by adjusting these battery settings.'),
          SizedBox(height: 20),
          ElevatedButton(onPressed: null, child: Text('Take this action')),
        ]),
      ),
    );
  }
}