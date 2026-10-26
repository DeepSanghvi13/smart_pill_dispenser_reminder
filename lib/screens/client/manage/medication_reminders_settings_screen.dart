import 'package:flutter/material.dart';
import '../../../services/hive_service.dart';

class MedicationRemindersSettingsScreen extends StatefulWidget {
  const MedicationRemindersSettingsScreen({super.key});

  @override
  State<MedicationRemindersSettingsScreen> createState() =>
      _MedicationRemindersSettingsScreenState();
}

class _MedicationRemindersSettingsScreenState
    extends State<MedicationRemindersSettingsScreen> {
  int maxReminders = 4;
  int snoozeMinutes = 10;
  bool showMedNames = false;
  bool shakeToTake = false;
  String reminderText = "Hi, it's time for your medication.";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = HiveService().settingsBox;
      final savedMax = box.get('med_settings_max_reminders') as int?;
      final savedSnooze = box.get('med_settings_snooze_minutes') as int?;
      final savedShowNames = box.get('med_settings_show_names') as bool?;
      final savedShake = box.get('med_settings_shake_to_take') as bool?;
      final savedText = box.get('med_settings_reminder_text') as String?;

      setState(() {
        if (savedMax != null) maxReminders = savedMax;
        if (savedSnooze != null) snoozeMinutes = savedSnooze;
        if (savedShowNames != null) showMedNames = savedShowNames;
        if (savedShake != null) shakeToTake = savedShake;
        if (savedText != null && savedText.trim().isNotEmpty) {
          reminderText = savedText;
        }
      });
    } catch (_) {}
  }

  Future<void> _persistValue(String key, dynamic value) async {
    try {
      final box = HiveService().settingsBox;
      await box.put(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _valueTile(
            title: 'Max reminders per medication',
            value: '$maxReminders reminders',
            onTap: () => _selectMaxReminders(context),
          ),

          _valueTile(
            title: 'Snooze duration',
            value: '$snoozeMinutes minutes',
            onTap: () => _selectSnoozeDuration(context),
          ),

          _checkboxTile(
            title: 'Show meds names',
            subtitle: 'See your meds names when receiving a reminder',
            value: showMedNames,
            onChanged: (val) {
              setState(() => showMedNames = val);
              _persistValue('med_settings_show_names', val);
            },
          ),

          _valueTile(
            title: 'Reminder text',
            value: reminderText,
            onTap: () => _editReminderText(context),
          ),

          _checkboxTile(
            title: 'Shake to Take',
            subtitle: 'Shake the phone (on reminder screen) to mark all meds as taken',
            value: shakeToTake,
            onChanged: (val) {
              setState(() => shakeToTake = val);
              _persistValue('med_settings_shake_to_take', val);
            },
          ),
        ],
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _valueTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _checkboxTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: (val) => onChanged(val!),
      activeColor: const Color(0xFF0D4F8B),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  // ---------- ACTIONS ----------

  void _selectMaxReminders(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Max reminders per medication'),
        children: List.generate(
          6,
          (index) => SimpleDialogOption(
            child: Text('${index + 1} reminders'),
            onPressed: () => Navigator.pop(context, index + 1),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => maxReminders = result);
      await _persistValue('med_settings_max_reminders', result);
    }
  }

  void _selectSnoozeDuration(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Snooze duration'),
        children: [5, 10, 15, 30].map((min) {
          return SimpleDialogOption(
            child: Text('$min minutes'),
            onPressed: () => Navigator.pop(context, min),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      setState(() => snoozeMinutes = result);
      await _persistValue('med_settings_snooze_minutes', result);
    }
  }

  void _editReminderText(BuildContext context) async {
    final controller = TextEditingController(text: reminderText);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reminder text'),
        content: TextField(
          controller: controller,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => reminderText = result);
      await _persistValue('med_settings_reminder_text', result);
    }
  }
}
