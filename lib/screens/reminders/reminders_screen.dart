import 'package:flutter/material.dart';

import '../../models/medicine.dart';
import '../../models/reminder.dart';
import '../../services/database_service.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Medicine> _medicines = const [];
  List<Reminder> _reminders = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final medicines = await _dbService.getAllMedicines();
      final reminders = await _dbService.getAllReminders();
      if (!mounted) return;
      setState(() {
        _medicines = medicines;
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reminders: $e')),
      );
    }
  }

  Future<void> _openReminderForm({Reminder? reminder}) async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Add at least one medicine before creating reminders.')),
      );
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddReminderScreen(
          medicines: _medicines,
          reminder: reminder,
        ),
      ),
    );

    if (changed == true) {
      await _loadData();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    if (reminder.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder'),
        content: Text('Delete reminder for ${reminder.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await _dbService.deleteReminder(reminder.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder deleted')),
    );
    await _loadData();
  }

  Future<void> _toggleReminder(Reminder reminder, bool isActive) async {
    if (reminder.id == null) return;

    await _dbService.toggleReminderStatus(reminder.id!, isActive);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Reminders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const Center(child: Text('No reminders yet. Tap + to add one.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _reminders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                              '${reminder.medicineName} - ${reminder.time}'),
                          subtitle: Text(reminder.daysOfWeek.join(', ')),
                          leading: Switch(
                            value: reminder.isActive,
                            onChanged: (value) =>
                                _toggleReminder(reminder, value),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _openReminderForm(reminder: reminder),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteReminder(reminder),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openReminderForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
