import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';


class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool sound = true;
  bool vibrate = true;
  bool ledLight = true;
  String _selectedTimezone = 'UTC';
  final List<String> _timezones = ['UTC', 'EST', 'CST', 'MST', 'PST', 'GMT', 'CET', 'IST', 'AEST'];

  @override
  void initState() {
    super.initState();
    _loadTimezone();
  }

  Future<void> _loadTimezone() async {
    final auth = context.read<AuthService>();
    final email = auth.currentUser;
    if (email != null) {
      final box = HiveService().usersBox;
      final user = box.get(email);
      if (user != null && user.timezone != null && _timezones.contains(user.timezone)) {
        setState(() {
          _selectedTimezone = user.timezone!;
        });
      }
    }
  }

  Future<void> _updateTimezone(String? newZone) async {
    if (newZone == null) return;
    final auth = context.read<AuthService>();
    final email = auth.currentUser;
    if (email != null) {
      final box = HiveService().usersBox;
      final user = box.get(email);
      if (user != null) {
        final updated = user.copyWith(timezone: newZone);
        await box.put(email, updated);
        setState(() {
          _selectedTimezone = newZone;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Timezone updated to $newZone')),
          );
        }
      }
    }
  }

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
              Navigator.pushNamed(context, AppRoutes.morningReminder);
            },
          ),
          ListTile(
            title: const Text('Evening Reminder'),
            subtitle: const Text(
              'Show you the meds you have missed today',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.eveningReminder);
            },
          ),
          ListTile(
            title: const Text('Weekly Summary'),
            subtitle: const Text(
              'Show you your weekly status',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.weeklySummary);
            },
          ),
          ListTile(
            title: const Text('Weekend Mode'),
            subtitle: const Text(
              "Set a different schedule for your weekend's morning meds",
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.weekendMode);
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
          const Divider(),
          _sectionTitle('Regional Settings'),
          ListTile(
            title: const Text('Timezone'),
            subtitle: const Text('Select your local timezone for notifications'),
            trailing: DropdownButton<String>(
              value: _selectedTimezone,
              items: _timezones.map((tz) {
                return DropdownMenuItem<String>(
                  value: tz,
                  child: Text(tz),
                );
              }).toList(),
              onChanged: _updateTimezone,
              underline: const SizedBox(),
            ),
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
          content: RadioGroup<ThemeMode>(
            groupValue: themeNotifier.value,
            onChanged: (value) {
              if (value != null) {
                themeNotifier.value = value;
              }
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Follow system'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
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



