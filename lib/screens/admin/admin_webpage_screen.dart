import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_pill_reminder/models/alarm_log.dart';
import 'package:smart_pill_reminder/models/caretaker.dart';
import 'package:smart_pill_reminder/models/medicine.dart';
import 'package:smart_pill_reminder/models/reminder.dart';
<<<<<<< HEAD
import 'package:smart_pill_reminder/screens/client/auth/login_screen.dart';
import 'package:smart_pill_reminder/screens/database/sql_connection_status_screen.dart';
=======
import 'package:smart_pill_reminder/screens/auth/login_screen.dart';
import 'package:smart_pill_reminder/screens/manage/sql_connection_status_screen.dart';
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
import 'package:smart_pill_reminder/services/auth_service.dart';
import 'package:smart_pill_reminder/services/mysql_api_service.dart';

class AdminWebpageScreen extends StatefulWidget {
  const AdminWebpageScreen({super.key});

  @override
  State<AdminWebpageScreen> createState() => _AdminWebpageScreenState();
}

class _AdminWebpageScreenState extends State<AdminWebpageScreen> {
  final MySQLApiService _api = MySQLApiService();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _serverConnected = false;
  String _systemStatus = 'Checking...';

  List<Medicine> _medicines = <Medicine>[];
  List<Reminder> _reminders = <Reminder>[];
  List<AlarmLog> _alarmLogs = <AlarmLog>[];
  List<Caretaker> _caretakers = <Caretaker>[];

  static const List<_AdminSection> _sections = <_AdminSection>[
    _AdminSection('Dashboard', Icons.dashboard_outlined),
    _AdminSection('Medicines', Icons.medication),
    _AdminSection('Reminders', Icons.alarm),
    _AdminSection('Alarm Logs', Icons.history),
    _AdminSection('Caretakers', Icons.supervised_user_circle),
    _AdminSection('System Settings', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser ?? 'demo-user';
      _api.configure(userId: userId);

      final connected = await _api.checkServerConnection();
      if (!connected) {
        if (!mounted) return;
        setState(() {
          _serverConnected = false;
          _systemStatus = 'Offline';
          _isLoading = false;
        });
        return;
      }

      final medicines = await _api.getMedicinesFromServer();
      final reminders = await _api.getRemindersFromServer();
      final alarmLogs = await _api.getAlarmLogsFromServer();
      final caretakers = await _api.getCaretakersFromServer();

      if (!mounted) return;
      setState(() {
        _serverConnected = true;
        _systemStatus = 'Online';
        _medicines = medicines;
        _reminders = reminders;
        _alarmLogs = alarmLogs;
        _caretakers = caretakers;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverConnected = false;
        _systemStatus = 'Error';
        _isLoading = false;
      });
    }
  }

  int get _activeReminderCount => _reminders.where((r) => r.isActive).length;

  int get _todayAlarmCount {
    final now = DateTime.now();
    return _alarmLogs.where((a) {
      return a.scheduledTime.year == now.year &&
          a.scheduledTime.month == now.month &&
          a.scheduledTime.day == now.day;
    }).length;
  }

  int get _todayMissedAlarmCount {
    final now = DateTime.now();
    return _alarmLogs.where((a) {
      final isToday = a.scheduledTime.year == now.year &&
          a.scheduledTime.month == now.month &&
          a.scheduledTime.day == now.day;
      return isToday && a.status.toLowerCase() == 'missed';
    }).length;
  }

  void _openSqlStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SqlConnectionStatusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser ?? 'Unknown';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Pill Dispenser - Admin Panel'),
            backgroundColor: const Color(0xFF0D4F8B),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Admin: $currentUser',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.storage),
                onPressed: _openSqlStatus,
<<<<<<< HEAD
                tooltip: 'Database Status',
=======
                tooltip: 'SQL Status',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAllData,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthService>().logout();
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          drawer: isWide ? null : _buildDrawer(),
          body: Row(
            children: [
              if (isWide) _buildRail(),
              Expanded(child: _buildSectionContent()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      destinations: _sections
          .map((s) => NavigationRailDestination(
              icon: Icon(s.icon), label: Text(s.title)))
          .toList(),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: IconButton(
          onPressed: _openSqlStatus,
          icon: const Icon(Icons.storage),
<<<<<<< HEAD
          tooltip: 'Database Status',
=======
          tooltip: 'SQL Status',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            ..._sections.asMap().entries.map(
                  (entry) => ListTile(
                    leading: Icon(entry.value.icon),
                    title: Text(entry.value.title),
                    selected: _selectedIndex == entry.key,
                    onTap: () {
                      setState(() => _selectedIndex = entry.key);
                      Navigator.pop(context);
                    },
                  ),
                ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('SQL'),
              onTap: () {
                Navigator.pop(context);
                _openSqlStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildMedicines();
      case 2:
        return _buildReminders();
      case 3:
        return _buildAlarmLogs();
      case 4:
        return _buildCaretakers();
      case 5:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return _sectionWrapper(
      title: 'Dashboard',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Total Medicines',
                      value: '${_medicines.length}',
                      color: Colors.blue,
                      icon: Icons.medication,
                    ),
                    _StatCard(
                      title: 'Active Reminders',
                      value: '$_activeReminderCount',
                      color: Colors.green,
                      icon: Icons.notifications_active,
                    ),
                    _StatCard(
                      title: 'Today Alarm Logs',
                      value: '$_todayAlarmCount',
                      color: Colors.orange,
                      icon: Icons.history,
                    ),
                    _StatCard(
                      title: 'Missed Today',
                      value: '$_todayMissedAlarmCount',
                      color: Colors.red,
                      icon: Icons.warning_amber,
                    ),
                    _StatCard(
                      title: 'Caretakers',
                      value: '${_caretakers.length}',
                      color: Colors.purple,
                      icon: Icons.supervised_user_circle,
                    ),
                    _StatCard(
                      title: 'System Status',
                      value: _systemStatus,
                      color: _serverConnected ? Colors.teal : Colors.grey,
                      icon: Icons.health_and_safety,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _panel(
                  title: 'Recent System Activity',
                  child: Column(
                    children: [
                      _ActivityRow(
                        'Database Status',
                        _serverConnected
<<<<<<< HEAD
                            ? 'Connected (MongoDB)'
                            : 'Disconnected (MongoDB)',
=======
                            ? 'Connected (MySQL)'
                            : 'Disconnected (MySQL)',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
                        _serverConnected ? 'OK' : 'OFFLINE',
                      ),
                      _ActivityRow(
                        'Medicines Synced',
<<<<<<< HEAD
                        '${_medicines.length} records in MongoDB',
=======
                        '${_medicines.length} records in MySQL',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
                        DateFormat('HH:mm').format(DateTime.now()),
                      ),
                      _ActivityRow(
                        'Reminders Active',
                        '$_activeReminderCount active reminders',
                        'LIVE',
                      ),
                      _ActivityRow(
                        'Alarm Logs',
                        '${_alarmLogs.length} records available',
<<<<<<< HEAD
                        'MONGODB',
=======
                        'MYSQL',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMedicines() {
    return _sectionWrapper(
      title: 'Medicines',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
<<<<<<< HEAD
              ? const Text('No medicines found on MongoDB server.')
=======
              ? const Text('No medicines found on MySQL server.')
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
              : _panel(
                  title: 'All Medicines (${_medicines.length})',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Dosage')),
                        DataColumn(label: Text('Time')),
                      ],
                      rows: _medicines
                          .map(
                            (m) => DataRow(
                              cells: [
                                DataCell(Text('${m.id ?? '-'}')),
                                DataCell(Text(m.category.emoji)),
                                DataCell(Text(m.name)),
                                DataCell(Text(m.dosage)),
                                DataCell(Text(m.time)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildReminders() {
    return _sectionWrapper(
      title: 'Reminders',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
<<<<<<< HEAD
              ? const Text('No reminders found on MongoDB server.')
=======
              ? const Text('No reminders found on MySQL server.')
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
              : _panel(
                  title: 'All Reminders (${_reminders.length})',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Medicine')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Days')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _reminders
                          .map(
                            (r) => DataRow(
                              cells: [
                                DataCell(Text('${r.id ?? '-'}')),
                                DataCell(Text(r.medicineName)),
                                DataCell(Text(r.time)),
                                DataCell(Text(r.daysOfWeek.join(', '))),
                                DataCell(
                                    Text(r.isActive ? 'Active' : 'Paused')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildAlarmLogs() {
    return _sectionWrapper(
      title: 'Alarm Logs',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarmLogs.isEmpty
<<<<<<< HEAD
              ? const Text('No alarm logs found on MongoDB server.')
=======
              ? const Text('No alarm logs found on MySQL server.')
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
              : _panel(
                  title: 'Alarm Logs (${_alarmLogs.length})',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Medicine')),
                        DataColumn(label: Text('Scheduled')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Snoozes')),
                      ],
                      rows: _alarmLogs
                          .map(
                            (a) => DataRow(
                              cells: [
                                DataCell(Text('${a.id ?? '-'}')),
                                DataCell(Text(a.medicineName)),
                                DataCell(
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(a.scheduledTime),
                                  ),
                                ),
                                DataCell(Text(a.status)),
                                DataCell(Text('${a.snoozeCount}')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildCaretakers() {
    return _sectionWrapper(
      title: 'Caretakers',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _caretakers.isEmpty
<<<<<<< HEAD
              ? const Text('No caretakers found on MongoDB server.')
=======
              ? const Text('No caretakers found on MySQL server.')
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
              : _panel(
                  title: 'Caretakers (${_caretakers.length})',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Relationship')),
                      ],
                      rows: _caretakers
                          .map(
                            (c) => DataRow(
                              cells: [
                                DataCell(Text('${c.id ?? '-'}')),
                                DataCell(Text('${c.firstName} ${c.lastName}')),
                                DataCell(Text(c.phoneNumber)),
                                DataCell(Text(c.email)),
                                DataCell(Text(c.relationship)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSettings() {
    return _sectionWrapper(
      title: 'System Settings',
      child: _panel(
        title: 'Database Configuration',
        child: Column(
          children: const [
<<<<<<< HEAD
            _SettingsRow(label: 'Database Type', value: 'MongoDB'),
            _SettingsRow(
                label: 'Storage Mode', value: 'Server-backed live data'),
            _SettingsRow(
                label: 'Admin Data Source', value: 'MongoDB API endpoints'),
=======
            _SettingsRow(label: 'Database Type', value: 'MySQL'),
            _SettingsRow(
                label: 'Storage Mode', value: 'Server-backed live data'),
            _SettingsRow(
                label: 'Admin Data Source', value: 'MySQL API endpoints'),
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
          ],
        ),
      ),
    );
  }

  Widget _sectionWrapper({required String title, required Widget child}) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D4F8B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AdminSection {
  final String title;
  final IconData icon;
  const _AdminSection(this.title, this.icon);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String detail;
  final String trailing;

  const _ActivityRow(this.title, this.detail, this.trailing);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(detail),
      trailing: Text(trailing),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(label)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
