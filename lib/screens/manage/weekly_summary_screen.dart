import 'package:flutter/material.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
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
      appBar: AppBar(title: const Text('Weekly Summary')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Weekly Summary'),
            subtitle: const Text('Receive my weekly summary'),
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
