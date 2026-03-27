import 'package:flutter/material.dart';

class EveningReminderScreen extends StatefulWidget {
  const EveningReminderScreen({super.key});

  @override
  State<EveningReminderScreen> createState() => _EveningReminderScreenState();
}

class _EveningReminderScreenState extends State<EveningReminderScreen> {
  bool enabled = true;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);

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
      appBar: AppBar(title: const Text('Evening Reminder')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use evening reminder'),
            subtitle: const Text('You have missed meds today'),
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
