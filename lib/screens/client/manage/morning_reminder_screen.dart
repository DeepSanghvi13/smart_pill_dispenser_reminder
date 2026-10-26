import 'package:flutter/material.dart';
import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';

class MorningReminderScreen extends StatefulWidget {
  const MorningReminderScreen({super.key});

  @override
  State<MorningReminderScreen> createState() => _MorningReminderScreenState();
}

class _MorningReminderScreenState extends State<MorningReminderScreen> {
  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = HiveService().settingsBox;
      final savedEnabled = box.get('morning_reminder_enabled') as bool?;
      final savedHour = box.get('morning_reminder_hour') as int?;
      final savedMinute = box.get('morning_reminder_minute') as int?;

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
      await box.put('morning_reminder_enabled', value);
      if (value) {
        await NotificationService.scheduleDailyPreferenceReminder(
          id: NotificationService.morningReminderNotificationId,
          title: "'Leave home with meds' Reminder",
          body: "Don't forget to take your prescribed medications with you today!",
          hour: time.hour,
          minute: time.minute,
        );
      } else {
        await NotificationService.cancelDailyPreferenceReminder(
          NotificationService.morningReminderNotificationId,
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
        await box.put('morning_reminder_hour', picked.hour);
        await box.put('morning_reminder_minute', picked.minute);
        if (enabled) {
          await NotificationService.scheduleDailyPreferenceReminder(
            id: NotificationService.morningReminderNotificationId,
            title: "'Leave home with meds' Reminder",
            body: "Don't forget to take your prescribed medications with you today!",
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
      appBar: AppBar(title: const Text('Morning Reminder')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("'Leave home with meds' Reminder"),
            subtitle: const Text(
              'A daily reminder to take your meds with you when you leave home',
            ),
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
