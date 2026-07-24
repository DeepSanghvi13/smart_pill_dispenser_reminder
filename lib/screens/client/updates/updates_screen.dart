import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medicine.dart';
import '../../../services/database_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = true;
  List<Medicine> _medicines = [];
  Medicine? _nextMedicine;
  DateTime? _nextReminderTime;
  int _takenToday = 0;
  int _skippedToday = 0;
  int _pendingToday = 0;
  DateTime? _lastUpdatedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allMedicines = await _dbService.getAllMedicines();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filter today's medicines
      final todayMedicines = allMedicines.where((m) {
        final start = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
        final end = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);
        return !today.isBefore(start) && !today.isAfter(end);
      }).toList();

      int taken = 0;
      int skipped = 0;
      int pending = 0;

      for (final m in todayMedicines) {
        final status = m.getDailyStatus();
        if (status == 'taken') {
          taken++;
        } else if (status == 'skipped') {
          skipped++;
        } else {
          pending++;
        }
      }

      // Find next upcoming medicine
      DateTime? nearestTime;
      Medicine? nearestMed;

      for (final med in todayMedicines) {
        final clean = med.time.trim();
        final formats = [
          DateFormat('h:mm a'),
          DateFormat('hh:mm a'),
          DateFormat('H:mm'),
          DateFormat('HH:mm'),
        ];
        DateTime? parsedTime;
        for (final format in formats) {
          try {
            parsedTime = format.parse(clean);
            break;
          } catch (_) {}
        }

        if (parsedTime == null) {
          final parts = clean.split(':');
          if (parts.length >= 2) {
            try {
              final hour = int.parse(parts[0]);
              final minStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
              final minute = int.parse(minStr);
              parsedTime = DateTime(2000, 1, 1, hour, minute);
            } catch (_) {}
          }
        }

        if (parsedTime == null) continue;

        final candidate = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        final target = candidate.isBefore(now)
            ? candidate.add(const Duration(days: 1))
            : candidate;

        if (nearestTime == null || target.isBefore(nearestTime)) {
          nearestTime = target;
          nearestMed = med;
        }
      }

      if (!mounted) return;
      setState(() {
        _medicines = allMedicines;
        _takenToday = taken;
        _skippedToday = skipped;
        _pendingToday = pending;
        _nextMedicine = nearestMed;
        _nextReminderTime = nearestTime;
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

  String _formattedLastUpdated() {
    final value = _lastUpdatedAt;
    if (value == null) return 'Not refreshed yet';
    return 'Refreshed at ${DateFormat('jm').format(value)}';
  }

  String _getCountdownText() {
    if (_nextReminderTime == null) return '';
    final diff = _nextReminderTime!.difference(DateTime.now());
    if (diff.isNegative) return 'due now';

    if (diff.inHours > 0) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return 'in $hours ${hours == 1 ? 'hr' : 'hrs'} $minutes ${minutes == 1 ? 'min' : 'mins'}';
    } else {
      final minutes = diff.inMinutes;
      return 'in $minutes ${minutes == 1 ? 'min' : 'mins'}';
    }
  }

  Widget _categoryIcon(String type) {
    final cleanType = type.trim().toLowerCase();
    if (cleanType.contains('syrup') || cleanType.contains('liquid')) {
      return const Icon(Icons.medication_liquid, size: 28, color: Colors.teal);
    } else if (cleanType.contains('inject') || cleanType.contains('vaccine')) {
      return const Icon(Icons.vaccines, size: 28, color: Colors.redAccent);
    } else {
      return const Icon(Icons.medication, size: 28, color: Colors.indigo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalToday = _takenToday + _skippedToday + _pendingToday;
    final complianceRate = totalToday > 0 ? (_takenToday / totalToday) : 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUpdates,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Top Dashboard Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Insights',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedLastUpdated(),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUpdates,
                  tooltip: 'Sync Data',
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (_error != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(Icons.warning, color: theme.colorScheme.error),
                    title: Text(_error!),
                    subtitle: const Text('Pull down to refresh'),
                  ),
                ),

              // 1. Compliance Progress Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Schedule",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have taken $_takenToday of $totalToday doses scheduled for today.',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(complianceRate * 100).toStringAsFixed(0)}% Compliance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: CircularProgressIndicator(
                              value: totalToday > 0 ? complianceRate : 0.0,
                              strokeWidth: 10,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              color: theme.colorScheme.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '$_takenToday/$totalToday',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Next Upcoming Dose
              Text(
                'Next Upcoming Dose',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_nextMedicine == null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        'No upcoming doses left for today!',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: _categoryIcon(_nextMedicine!.type),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nextMedicine!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_nextMedicine!.dosage} • ${_nextMedicine!.time}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                              const SizedBox(height: 2),
                              Text(
                                _getCountdownText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 3. Quick Stats Grid
              Text(
                'Medication Performance',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _smallStatCard(
                      context,
                      'Active Medicines',
                      _medicines.length.toString(),
                      Icons.healing_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _smallStatCard(
                      context,
                      'Skipped Doses',
                      _skippedToday.toString(),
                      Icons.cancel_outlined,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Custom Wellness Tip
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Daily Wellness Reminder',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Taking your medicine at the exact scheduled time helps maintain a consistent level of the drug in your body. Set alarms to keep you on schedule and consult your doctor for any changes.',
                        style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _smallStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
