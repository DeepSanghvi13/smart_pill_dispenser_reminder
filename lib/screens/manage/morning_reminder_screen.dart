import 'package:flutter/material.dart';

class MorningReminderScreen extends StatefulWidget {
  const MorningReminderScreen({super.key});

  @override
  State<MorningReminderScreen> createState() => _MorningReminderScreenState();
}

class _MorningReminderScreenState extends State<MorningReminderScreen> {
  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (picked != null) {
      setState(() => time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Morning Reminder')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("'Leave home with meds' Reminder"),
            subtitle: const Text(
              'A daily reminder to take your meds with you when you leave home',
            ),
            value: enabled,
            onChanged: (v) => setState(() => enabled = v),
          ),
          ListTile(
            title: const Text('Time'),
            subtitle: Text(time.format(context)),
            onTap: enabled ? _pickTime : null,
          ),
        ],
      ),
    );
  }
}
