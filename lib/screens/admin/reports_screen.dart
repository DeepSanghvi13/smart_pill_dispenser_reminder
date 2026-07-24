import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../widgets/custom_charts.dart';
import '../../../models/medicine.dart';
import '../../../models/user.dart';
import '../../../models/alarm_log.dart';
import '../../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;

  String _reportScope = 'Daily'; // 'Daily', 'Weekly', 'Monthly'

  // Calculated values
  int _totalMedicines = 0;
  int _takenDoses = 0;
  int _missedDoses = 0;
  int _delayedDoses = 0;
  int _activePatients = 0;
  int _activeCaretakers = 0;
  int _newRegistrations = 0;

  List<Map<String, dynamic>> _savedReports = [];

  @override
  void initState() {
    super.initState();
    _loadReportsAndCalculate();
  }

  Future<void> _loadReportsAndCalculate() async {
    setState(() => _isLoading = true);
    try {
      final reportsBox = HiveService().reportsBox;
      final mBox = HiveService().medicinesBox;
      final uBox = HiveService().usersBox;
      final settingsBox = HiveService().settingsBox;

      // Current values
      final allMeds = mBox.values.toList();
      final allUsers = uBox.values.toList();

      final now = DateTime.now();
      final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      DateTime startDate;
      if (_reportScope == 'Daily') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_reportScope == 'Weekly') {
        startDate = now.subtract(const Duration(days: 7));
      } else {
        startDate = now.subtract(const Duration(days: 30));
      }
      final startToday = DateTime(startDate.year, startDate.month, startDate.day);

      int taken = 0;
      int missed = 0;
      int delayed = 0;

      // Extract all alarm logs for all users
      final allLogs = <AlarmLog>[];
      for (final key in settingsBox.keys) {
        if (key is String && key.startsWith('alarmlogs_')) {
          final raw = settingsBox.get(key);
          if (raw != null) {
            try {
              final List<dynamic> list = jsonDecode(raw as String);
              allLogs.addAll(list.map((item) => AlarmLog.fromMap(Map<String, dynamic>.from(item))));
            } catch (_) {}
          }
        }
      }

      final logsInScope = allLogs.where((l) {
        return !l.scheduledTime.isBefore(startToday) && !l.scheduledTime.isAfter(endToday);
      }).toList();

      final medsInScope = allMeds.where((m) {
        return !m.startDate.isAfter(endToday) && !m.endDate.isBefore(startToday);
      }).toList();

      if (logsInScope.isNotEmpty) {
        for (final log in logsInScope) {
          if (log.status == 'taken') {
            taken++;
          } else if (log.status == 'missed') {
            missed++;
          } else {
            delayed++;
          }
        }
      } else {
        // Fallback: active medicines in scope daily status
        for (final med in medsInScope) {
          if (med.status == 'taken') {
            taken++;
          } else if (med.status == 'skipped') {
            missed++;
          } else {
            delayed++;
          }
        }
      }

      final activePatientsCount = allUsers.where((u) => u.role == 'patient' && u.isActive).length;
      final activeCaretakersCount = allUsers.where((u) => u.role == 'caretaker' && u.isActive).length;

      final newRegCount = allUsers.where((u) => u.createdAt.isAfter(startDate)).length;

      setState(() {
        _totalMedicines = medsInScope.length;
        _takenDoses = taken;
        _missedDoses = missed;
        _delayedDoses = delayed;
        _activePatients = activePatientsCount;
        _activeCaretakers = activeCaretakersCount;
        _newRegistrations = newRegCount;

        _savedReports = reportsBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCurrentReport() async {
    setState(() => _isLoading = true);
    try {
      final reportsBox = HiveService().reportsBox;
      final currentAdmin = context.read<AuthService>().currentUser ?? 'admin';
      final now = DateTime.now();

      final reportId = 'rep_${_reportScope.toLowerCase()}_${now.millisecondsSinceEpoch}';
      final reportData = {
        'reportId': reportId,
        'type': _reportScope,
        'startDate': DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: _reportScope == 'Daily' ? 1 : (_reportScope == 'Weekly' ? 7 : 30)))),
        'endDate': DateFormat('yyyy-MM-dd').format(now),
        'totalMedicines': _totalMedicines,
        'medicinesTaken': _takenDoses,
        'missedMedicines': _missedDoses,
        'delayedMedicines': _delayedDoses,
        'activePatients': _activePatients,
        'activeCaretakers': _activeCaretakers,
        'newRegistrations': _newRegistrations,
        'createdBy': currentAdmin,
        'updatedBy': currentAdmin,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await reportsBox.put(reportId, reportData);
      await _db.adminLogActivity('Generated and archived compliance report: $_reportScope');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $_reportScope report to archive.')),
      );
      await _loadReportsAndCalculate();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return AdminLayout(
      title: 'Compliance Reports',
      activeRoute: AppRoutes.adminReports,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsAndCalculate,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Filter header
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: _reportScope,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'Daily', child: Text('Daily Performance')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly Performance')),
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly Performance')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _reportScope = val;
                            });
                            _loadReportsAndCalculate();
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveCurrentReport,
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Save Report'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Data Display Cards
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    childAspectRatio: 1.8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _smallDataCard('Scheduled Medicines', _totalMedicines.toString(), Colors.blue),
                      _smallDataCard('Taken Doses', _takenDoses.toString(), Colors.green),
                      _smallDataCard('Missed Doses', _missedDoses.toString(), Colors.red),
                      _smallDataCard('New Registrations', _newRegistrations.toString(), Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Charts Row
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Compliance Breakdown',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                CustomBarChart(
                                  values: [
                                    _totalMedicines.toDouble(),
                                    _takenDoses.toDouble(),
                                    _missedDoses.toDouble(),
                                    _delayedDoses.toDouble(),
                                  ],
                                  labels: const ['Scheduled', 'Taken', 'Missed', 'Delayed'],
                                  barColor: Colors.teal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Saved Reports Archive
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved Reports Archive',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          if (_savedReports.isEmpty)
                            const Center(child: Text('No archived reports. Click "Save Report" above.'))
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _savedReports.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (ctx, index) {
                                final report = _savedReports[index];
                                final type = report['type'] ?? 'Daily';
                                final date = report['createdAt'] != null
                                    ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(report['createdAt'] as String))
                                    : 'N/A';
                                
                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file_outlined),
                                  title: Text('$type Compliance Report'),
                                  subtitle: Text(
                                    'Period: ${report['startDate']} to ${report['endDate']} • Generated: $date\nCreated By: ${report['createdBy']}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Taken: ${report['medicinesTaken']} / ${report['totalMedicines']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Missed: ${report['missedMedicines']}',
                                        style: const TextStyle(color: Colors.red, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  onLongPress: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Report'),
                                        content: const Text('Are you sure you want to permanently delete this report from archive?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final rBox = HiveService().reportsBox;
                                      await rBox.delete(report['reportId']);
                                      await _db.adminLogActivity('Deleted archived report: ${report['reportId']}');
                                      _loadReportsAndCalculate();
                                    }
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _smallDataCard(String label, String value, Color color) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
