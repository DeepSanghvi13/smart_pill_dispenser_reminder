import 'package:flutter/material.dart';

class WeekendModeScreen extends StatefulWidget {
  const WeekendModeScreen({super.key});

  @override
  State<WeekendModeScreen> createState() => _WeekendModeScreenState();
}

class _WeekendModeScreenState extends State<WeekendModeScreen> {
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
      appBar: AppBar(title: const Text('Weekend Mode')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use weekend reminder'),
            subtitle: const Text(
              'Choose weekend days and earliest morning hour',
            ),
            value: enabled,
            onChanged: (v) => setState(() => enabled = v),
          ),
          ListTile(
            title: const Text('Set your weekend morning hour'),
            subtitle: Text(time.format(context)),
            onTap: enabled ? _pickTime : null,
          ),
          const ListTile(
            title: Text('Set your weekend days'),
            subtitle: Text('none'),
          ),
        ],
      ),
    );
  }
}
