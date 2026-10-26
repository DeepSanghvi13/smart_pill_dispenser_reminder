import 'package:flutter/material.dart';
import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';

class WeekendModeScreen extends StatefulWidget {
  const WeekendModeScreen({super.key});

  @override
  State<WeekendModeScreen> createState() => _WeekendModeScreenState();
}

class _WeekendModeScreenState extends State<WeekendModeScreen> {
  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  List<String> selectedDays = ['Saturday', 'Sunday'];

  final List<String> allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = HiveService().settingsBox;
      final savedEnabled = box.get('weekend_mode_enabled') as bool?;
      final savedHour = box.get('weekend_mode_hour') as int?;
      final savedMinute = box.get('weekend_mode_minute') as int?;
      final savedDays = box.get('weekend_mode_days');

      setState(() {
        if (savedEnabled != null) enabled = savedEnabled;
        if (savedHour != null && savedMinute != null) {
          time = TimeOfDay(hour: savedHour, minute: savedMinute);
        }
        if (savedDays is List) {
          selectedDays = savedDays.map((d) => d.toString()).toList();
        }
      });
    } catch (_) {}
  }

  Future<void> _updateEnabled(bool value) async {
    setState(() => enabled = value);
    try {
      final box = HiveService().settingsBox;
      await box.put('weekend_mode_enabled', value);
      await _rescheduleWeekendAlarms();
    } catch (_) {}
  }

  Future<void> _rescheduleWeekendAlarms() async {
    // Cancel prior weekend alarms (ids 500011..500017)
    for (int i = 1; i <= 7; i++) {
      await NotificationService.cancelDailyPreferenceReminder(
        NotificationService.weekendReminderBaseNotificationId + i,
      );
    }

    if (!enabled || selectedDays.isEmpty) return;

    for (final day in selectedDays) {
      final weekdayIndex = allDays.indexOf(day) + 1;
      if (weekdayIndex >= 1 && weekdayIndex <= 7) {
        await NotificationService.scheduleDailyPreferenceReminder(
          id: NotificationService.weekendReminderBaseNotificationId + weekdayIndex,
          title: 'Weekend Morning Medication',
          body: 'Good morning! It is time for your weekend morning medication.',
          hour: time.hour,
          minute: time.minute,
        );
      }
    }
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
        await box.put('weekend_mode_hour', picked.hour);
        await box.put('weekend_mode_minute', picked.minute);
        await _rescheduleWeekendAlarms();
      } catch (_) {}
    }
  }

  Future<void> _selectWeekendDays() async {
    final currentSelection = List<String>.from(selectedDays);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Select Weekend Days'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allDays.map((day) {
                    final isChecked = currentSelection.contains(day);
                    return CheckboxListTile(
                      title: Text(day),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (!currentSelection.contains(day)) {
                              currentSelection.add(day);
                            }
                          } else {
                            currentSelection.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, currentSelection),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => selectedDays = result);
      try {
        final box = HiveService().settingsBox;
        await box.put('weekend_mode_days', result);
        await _rescheduleWeekendAlarms();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysSubtitle = selectedDays.isEmpty ? 'none' : selectedDays.join(', ');

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
            onChanged: _updateEnabled,
          ),
          ListTile(
            title: const Text('Set your weekend morning hour'),
            subtitle: Text(time.format(context)),
            onTap: enabled ? _pickTime : null,
          ),
          ListTile(
            title: const Text('Set your weekend days'),
            subtitle: Text(daysSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: enabled ? _selectWeekendDays : null,
          ),
        ],
      ),
    );
  }
}
