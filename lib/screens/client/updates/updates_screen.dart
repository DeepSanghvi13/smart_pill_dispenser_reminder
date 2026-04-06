import 'package:flutter/material.dart';

import '../../../models/reminder.dart';
import '../../../services/database_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = true;
  int _medicineCount = 0;
  int _reminderCount = 0;
  int _activeReminderCount = 0;
  String? _nextReminder;
  DateTime? _lastUpdatedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final medicines = await _dbService.getAllMedicines();
      final reminders = await _dbService.getAllReminders();

      final active = reminders.where((r) => r.isActive).toList();
      final next = _findNextReminder(active);

      if (!mounted) return;
      setState(() {
        _medicineCount = medicines.length;
        _reminderCount = reminders.length;
        _activeReminderCount = active.length;
        _nextReminder = next;
        _lastUpdatedAt = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load updates right now.';
        _isLoading = false;
      });
    }
  }

  String? _findNextReminder(List<Reminder> reminders) {
    DateTime? nearest;
    Reminder? nearestReminder;
    final now = DateTime.now();

    for (final reminder in reminders) {
      final timeParts = reminder.time.split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      final target = candidate.isBefore(now)
          ? candidate.add(const Duration(days: 1))
          : candidate;

      if (nearest == null || target.isBefore(nearest)) {
        nearest = target;
        nearestReminder = reminder;
      }
    }

    if (nearestReminder == null || nearest == null) return null;
    final hh = nearest.hour.toString().padLeft(2, '0');
    final mm = nearest.minute.toString().padLeft(2, '0');
    return '${nearestReminder.medicineName} at $hh:$mm';
  }

  String _formattedLastUpdated() {
    final value = _lastUpdatedAt;
    if (value == null) return 'Not refreshed yet';
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return 'Updated today at $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUpdates,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Latest Updates',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            _formattedLastUpdated(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            if (_error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(_error!),
                  subtitle: const Text('Pull down to try again.'),
                ),
              ),
            _StatCard(
              icon: Icons.medication_outlined,
              title: 'Medicines',
              value: _medicineCount.toString(),
              subtitle: 'Total medicines currently added',
            ),
            const SizedBox(height: 10),
            _StatCard(
              icon: Icons.alarm,
              title: 'Reminders',
              value: '$_activeReminderCount / $_reminderCount',
              subtitle: 'Active reminders / total reminders',
            ),
            const SizedBox(height: 10),
            _StatCard(
              icon: Icons.schedule,
              title: 'Next Reminder',
              value: _nextReminder ?? 'No active reminders',
              subtitle: 'Based on your current reminder schedule',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Helpful Tips',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '• Keep at least one active reminder for each medicine.'),
                    SizedBox(height: 4),
                    Text(
                        '• Add expiry dates to receive timely refill planning alerts.'),
                    SizedBox(height: 4),
                    Text(
                        '• Use pull-to-refresh here to sync your latest data snapshot.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D4F8B)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
