import 'package:flutter/material.dart';
import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';

class EveningReminderScreen extends StatefulWidget {
  const EveningReminderScreen({super.key});

  @override
  State<EveningReminderScreen> createState() => _EveningReminderScreenState();
}

class _EveningReminderScreenState extends State<EveningReminderScreen> {
  bool enabled = true;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = HiveService().settingsBox;
      final savedEnabled = box.get('evening_reminder_enabled') as bool?;
      final savedHour = box.get('evening_reminder_hour') as int?;
      final savedMinute = box.get('evening_reminder_minute') as int?;

      setState(() {
        if (savedEnabled != null) enabled = savedEnabled;
        if (savedHour != null && savedMinute != null) {
          time = TimeOfDay(hour: savedHour, minute: savedMinute);
        }
      });
    } catch (_) {}
  }

  Future<void> _updateEnabled(bool value) async {
    setState(() => enabled = value);
    try {
      final box = HiveService().settingsBox;
      await box.put('evening_reminder_enabled', value);
      if (value) {
        await NotificationService.scheduleDailyPreferenceReminder(
          id: NotificationService.eveningReminderNotificationId,
          title: "Evening Medication Check",
          body: "Check your medication log to review any doses missed today.",
          hour: time.hour,
          minute: time.minute,
        );
      } else {
        await NotificationService.cancelDailyPreferenceReminder(
          NotificationService.eveningReminderNotificationId,
        );
      }
    } catch (_) {}
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (picked != null) {
      setState(() => time = picked);
      try {
        final box = HiveService().settingsBox;
        await box.put('evening_reminder_hour', picked.hour);
        await box.put('evening_reminder_minute', picked.minute);
        if (enabled) {
          await NotificationService.scheduleDailyPreferenceReminder(
            id: NotificationService.eveningReminderNotificationId,
            title: "Evening Medication Check",
            body: "Check your medication log to review any doses missed today.",
            hour: picked.hour,
            minute: picked.minute,
          );
        }
      } catch (_) {}
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
            onChanged: _updateEnabled,
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
