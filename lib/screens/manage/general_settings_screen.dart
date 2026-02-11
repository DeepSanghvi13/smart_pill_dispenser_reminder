import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

import 'morning_reminder_screen.dart';
import 'evening_reminder_screen.dart';
import 'weekly_summary_screen.dart';
import 'weekend_mode_screen.dart';

enum ThemeModeOption {
  system,
  light,
  dark,
}

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState
    extends State<GeneralSettingsScreen> {
  ThemeModeOption _themeMode = ThemeModeOption.system;

  bool sound = true;
  bool vibrate = true;
  bool ledLight = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
      ),
      body: ListView(
        children: [
          _sectionTitle('Reminders'),

          ListTile(
            title: const Text('Medication Reminders'),
            subtitle: const Text(
              'Snooze times, max alarms, shake to take',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          ListTile(
            title: const Text('Morning Reminder'),
            subtitle: const Text(
              'Remind to bring your meds with you in the morning',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const MorningReminderScreen(),
                ),
              );
            },
          ),

          ListTile(
            title: const Text('Evening Reminder'),
            subtitle: const Text(
              'Show you the meds you have missed today',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const EveningReminderScreen(),
                ),
              );
            },
          ),

          ListTile(
            title: const Text('Weekly Summary'),
            subtitle: const Text(
              'Show you your weekly status',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const WeeklySummaryScreen(),
                ),
              );
            },
          ),

          ListTile(
            title: const Text('Weekend Mode'),
            subtitle: const Text(
              "Set a different schedule for your weekend's morning meds",
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const WeekendModeScreen(),
                ),
              );
            },
          ),

          const Divider(),

          _sectionTitle('Dark Mode'),

          ListTile(
            title: const Text('Dark Mode State'),
            subtitle: const Text(
              'Set dark or light application theme',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDarkModeDialog(context),
          ),

          const Divider(),

          _sectionTitle('Notifications'),

          SwitchListTile(
            title: const Text('Sound'),
            value: sound,
            onChanged: (val) {
              setState(() => sound = val);
            },
          ),

          SwitchListTile(
            title: const Text('Vibrate'),
            value: vibrate,
            onChanged: (val) {
              setState(() => vibrate = val);
            },
          ),

          SwitchListTile(
            title: const Text('LED Light'),
            value: ledLight,
            onChanged: (val) {
              setState(() => ledLight = val);
            },
          ),
        ],
      ),
    );
  }

  // ===== DARK MODE DIALOG =====
  void _showDarkModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dark Mode State'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Follow system'),
                value: ThemeMode.light,
                groupValue: themeNotifier.value,
                onChanged: (value) {
                  themeNotifier.value = value!;
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeNotifier.value,
                onChanged: (value) {
                  themeNotifier.value = value!;
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeNotifier.value,
                onChanged: (value) {
                  themeNotifier.value = value!;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }


  // ===== SECTION TITLE =====
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
