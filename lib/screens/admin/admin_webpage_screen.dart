import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_pill_reminder/models/alarm_log.dart';
import 'package:smart_pill_reminder/models/caretaker.dart';
import 'package:smart_pill_reminder/models/medicine.dart';
import 'package:smart_pill_reminder/models/reminder.dart';
import 'package:smart_pill_reminder/models/user_profile.dart';
import 'package:smart_pill_reminder/screens/auth/login_screen.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
import 'package:smart_pill_reminder/services/database_service.dart';

class AdminWebpageScreen extends StatefulWidget {
  const AdminWebpageScreen({super.key});

  @override
  State<AdminWebpageScreen> createState() => _AdminWebpageScreenState();
}

class _AdminWebpageScreenState extends State<AdminWebpageScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  int _selectedIndex = 0;
  bool _isLoading = true;
  String _systemStatus = 'Checking...';

  List<Medicine> _medicines = <Medicine>[];
  List<Reminder> _reminders = <Reminder>[];
  List<AlarmLog> _todayAlarms = <AlarmLog>[];
  List<AlarmLog> _missedAlarms = <AlarmLog>[];
  List<Caretaker> _caretakers = <Caretaker>[];
  UserProfile? _userProfile;
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];

  final List<_HelpArticle> _articles = <_HelpArticle>[];
  final List<_SupportTicket> _tickets = <_SupportTicket>[];

  Map<String, String> _appSettings = {
    'app_name': 'Smart Pill Dispenser',
    'app_version': '1.0.0',
    'database_type': 'SQLite',
    'admin_email': 'admin@medisafe.com',
    'support_email': 'support@medisafe.com',
    'support_phone': '+91-878-009-5396',
    'help_center_url': 'medisafe.com/help',
  };

  Map<String, bool> _notificationSettings = {
    'reminder_notifications': true,
    'success_messages': true,
    'error_alerts': true,
    'email_notifications': false,
  };

  bool _settingsDirty = false;

  static const List<_AdminSection> _sections = <_AdminSection>[
    _AdminSection('Dashboard', Icons.dashboard_outlined),
    _AdminSection('Users', Icons.people),
    _AdminSection('Medicines', Icons.medication),
    _AdminSection('Help Articles', Icons.article_outlined),
    _AdminSection('Support Tickets', Icons.support_agent_outlined),
    _AdminSection('System Settings', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _seedSampleData();
    _loadAllData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _seedSampleData() {
    _articles
      ..clear()
      ..addAll(<_HelpArticle>[
        _HelpArticle('How to add a medicine', 'Getting Started', 'Use the + button and enter medicine details.'),
        _HelpArticle('Setting up reminders', 'Features', 'Create time-based reminders for each medicine.'),
        _HelpArticle('Managing caretakers', 'Family Mode', 'Add family members to receive missed-dose alerts.'),
      ]);

    _tickets
      ..clear()
      ..addAll(<_SupportTicket>[
        _SupportTicket('#2401', 'Alarm not ringing at scheduled time', 'High', 'Open'),
        _SupportTicket('#2402', 'Medicine list not syncing', 'High', 'In Progress'),
        _SupportTicket('#2403', 'Notification permission issue', 'Medium', 'Open'),
      ]);
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final medicines = await _dbService.getAllMedicines();
      final reminders = await _dbService.getAllReminders();
      final todayAlarms = await _dbService.getTodayAlarmLogs();
      final missedAlarms = await _dbService.getTodayMissedAlarms();
      final caretakers = await _dbService.getAllCaretakers();
      final userProfile = await _dbService.getUserProfileData();
      final allSettings = await _dbService.getAllSettings();
      final users = await _dbService.getAllUsers();

      setState(() {
        _medicines = medicines;
        _reminders = reminders;
        _todayAlarms = todayAlarms;
        _missedAlarms = missedAlarms;
        _caretakers = caretakers;
        _userProfile = userProfile;
        _users = users;

        _appSettings = {..._appSettings, ...allSettings};
        _notificationSettings = {
          'reminder_notifications': (allSettings['reminder_notifications'] ?? 'true') == 'true',
          'success_messages': (allSettings['success_messages'] ?? 'true') == 'true',
          'error_alerts': (allSettings['error_alerts'] ?? 'true') == 'true',
          'email_notifications': (allSettings['email_notifications'] ?? 'false') == 'true',
        };
        _settingsDirty = false;
        _systemStatus = 'Online';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _systemStatus = 'Error';
        _isLoading = false;
      });
    }
  }

  int get _appUsersCount {
    final primary = _userProfile == null ? 0 : 1;
    return primary + _caretakers.length + 1; // +1 admin
  }

  int get _activeReminderCount => _reminders.where((r) => r.isActive).length;

  @override
  Widget build(BuildContext context) {
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
                    'Admin: ${authService.currentUser ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAllData,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  authService.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          .map((s) => NavigationRailDestination(icon: Icon(s.icon), label: Text(s.title)))
          .toList(),
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
        return _buildUsers();
      case 2:
        return _buildMedicines();
      case 3:
        return _buildArticles();
      case 4:
        return _buildTickets();
      case 5:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final taken = _todayAlarms.where((a) => a.status == 'taken').length;
    final adherence = _todayAlarms.isEmpty ? 0.0 : (taken / _todayAlarms.length) * 100;

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
                    _StatCard(title: 'Total Medicines', value: '${_medicines.length}', color: Colors.blue, icon: Icons.medication),
                    _StatCard(title: 'Today\'s Reminders', value: '$_activeReminderCount', color: Colors.green, icon: Icons.notifications_active),
                    _StatCard(title: 'App Users', value: '$_appUsersCount', color: Colors.orange, icon: Icons.people),
                    _StatCard(title: 'System Status', value: _systemStatus, color: Colors.purple, icon: Icons.health_and_safety),
                    _StatCard(title: 'Adherence', value: '${adherence.toStringAsFixed(1)}%', color: Colors.teal, icon: Icons.trending_up),
                    _StatCard(title: 'Missed Alarms', value: '${_missedAlarms.length}', color: Colors.red, icon: Icons.warning_amber),
                  ],
                ),
                const SizedBox(height: 16),
                _panel(
                  title: 'Recent System Activity',
                  child: Column(
                    children: [
                      _ActivityRow('Database Status', 'Connected (${_appSettings['database_type']})', 'OK'),
                      _ActivityRow('Medicines Synced', '${_medicines.length} records available', DateFormat('HH:mm').format(DateTime.now())),
                      _ActivityRow('Reminders Active', '$_activeReminderCount active reminders', 'LIVE'),
                      _ActivityRow('Support Queue', '${_tickets.where((t) => t.status != 'Resolved').length} open tickets', 'OPEN'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUsers() {
    return _sectionWrapper(
      title: 'Users',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appUsersCount == 0
              ? const Text('No users found.')
              : _panel(
                  title: 'All Users ($_appUsersCount)',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(Text('1')),
                            DataCell(Text('Admin')),
                            DataCell(Text(_userProfile?.fullName ?? 'N/A')),
                            DataCell(Text(_userProfile?.email ?? 'N/A')),
                            DataCell(Text(_userProfile?.phoneNumber ?? 'N/A')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editUser(_userProfile!),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteUser(_userProfile!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ..._caretakers.map(
                          (c) => DataRow(
                            cells: [
                              DataCell(Text('${c.id}')),
                              DataCell(Text('Caretaker')),
                              DataCell(Text(c.fullName)),
                              DataCell(Text(c.email)),
                              DataCell(Text(c.phoneNumber)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editUser(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteUser(c),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._users.map(
                          (u) => DataRow(
                            cells: [
                              DataCell(Text('${u['id']}')),
                              DataCell(Text('User')),
                              DataCell(Text('N/A')),
                              DataCell(Text(u['email'])),
                              DataCell(Text('N/A')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editUser(u),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteUser(u),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _deleteUser(dynamic user) async {
    try {
      if (user is UserProfile) {
        // Delete user profile
        await _dbService.saveUserProfile(UserProfile(
          firstName: '',
          lastName: '',
          email: '',
        ));
      } else if (user is Caretaker && user.id != null) {
        // Delete caretaker
        await _dbService.deleteCaretaker(user.id!);
      } else if (user is Map<String, dynamic> && user['id'] != null) {
        // Delete user from users table
        await _dbService.deleteUser(user['id']);
      }
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
    }
  }

  void _editUser(dynamic user) {
    String name = '';
    String email = '';

    if (user is UserProfile) {
      name = user.fullName;
      email = user.email ?? '';
    } else if (user is Caretaker) {
      name = user.fullName;
      email = user.email;
    } else if (user is Map<String, dynamic>) {
      name = 'N/A';
      email = user['email'] ?? '';
    }

    _titleController.text = name;
    _bodyController.text = email;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                if (user is UserProfile) {
                  // Update user profile
                  final updatedProfile = UserProfile(
                    firstName: _titleController.text.split(' ').first,
                    lastName: _titleController.text.split(' ').skip(1).join(' '),
                    email: _bodyController.text,
                  );
                  await _dbService.saveUserProfile(updatedProfile);
                } else if (user is Caretaker && user.id != null) {
                  // Update caretaker
                  final updatedCaretaker = Caretaker(
                    firstName: _titleController.text.split(' ').first,
                    lastName: _titleController.text.split(' ').skip(1).join(' '),
                    phoneNumber: user.phoneNumber,
                    email: _bodyController.text,
                    relationship: user.relationship,
                    notifyViaSMS: user.notifyViaSMS,
                    notifyViaEmail: user.notifyViaEmail,
                    notifyViaNotification: user.notifyViaNotification,
                    isActive: user.isActive,
                  );
                  await _dbService.updateCaretaker(user.id!, updatedCaretaker);
                } else if (user is Map<String, dynamic> && user['id'] != null) {
                  // Update user in users table
                  await _dbService.updateUser(user['id'], email: _bodyController.text);
                }
                await _loadAllData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
                Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
              }
            },
            child: const Text('Update'),
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
              ? const Text('No medicines found.')
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
                        DataColumn(label: Text('Actions')),
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
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteMedicine(m),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
    );
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    await _dbService.deleteMedicine(medicine.id!);
    await _loadAllData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${medicine.name} deleted')));
  }

  Widget _buildArticles() {
    return _sectionWrapper(
      title: 'Help Center Articles',
      action: ElevatedButton.icon(
        onPressed: _showAddArticle,
        icon: const Icon(Icons.add),
        label: const Text('New Article'),
      ),
      child: _panel(
        title: 'Published Articles (${_articles.length})',
        child: Column(
          children: _articles
              .map(
                (a) => _articleRow(
                  a.title,
                  a.category,
                  a.description,
                  onEdit: () => _editArticle(a),
                  onDelete: () => _deleteArticle(a),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTickets() {
    return _sectionWrapper(
      title: 'Support Tickets',
      action: ElevatedButton.icon(
        onPressed: _addNewTicket,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      child: _panel(
        title: 'Tickets (${_tickets.length})',
        child: Column(
          children: _tickets
              .map(
                (t) => _ticketRowWithActions(
                  t.id,
                  t.issue,
                  t.priority,
                  t.status,
                  onStatusChange: () => _changeTicketStatus(t),
                  onDelete: () => _deleteTicket(t),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return _sectionWrapper(
      title: 'System Settings',
      action: ElevatedButton.icon(
        onPressed: _settingsDirty ? _saveSettings : null,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      child: Column(
        children: [
          _panel(
            title: 'Application Settings',
            child: Column(
              children: [
                _editableSettingRow('App Name', 'app_name'),
                _editableSettingRow('App Version', 'app_version'),
                _editableSettingRow('Database Type', 'database_type', readOnly: true),
                _editableSettingRow('Admin Email', 'admin_email'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Notification Settings',
            child: Column(
              children: [
                _toggleSetting('Reminder Notifications', 'reminder_notifications'),
                _toggleSetting('Success Messages', 'success_messages'),
                _toggleSetting('Error Alerts', 'error_alerts'),
                _toggleSetting('Email Notifications', 'email_notifications'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Support Settings',
            child: Column(
              children: [
                _editableSettingRow('Support Email', 'support_email'),
                _editableSettingRow('Support Phone', 'support_phone'),
                _editableSettingRow('Help Center URL', 'help_center_url'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    for (final entry in _appSettings.entries) {
      await _dbService.saveSetting(entry.key, entry.value);
    }
    for (final entry in _notificationSettings.entries) {
      await _dbService.saveSetting(entry.key, entry.value.toString());
    }
    if (!mounted) return;
    setState(() => _settingsDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Widget _editableSettingRow(String label, String key, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: TextFormField(
              initialValue: _appSettings[key] ?? '',
              readOnly: readOnly,
              onChanged: readOnly
                  ? null
                  : (val) {
                      _appSettings[key] = val;
                      if (!_settingsDirty) {
                        setState(() => _settingsDirty = true);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleSetting(String label, String key) {
    final value = _notificationSettings[key] ?? false;
    return SwitchListTile(
      value: value,
      title: Text(label),
      onChanged: (v) {
        setState(() {
          _notificationSettings[key] = v;
          _settingsDirty = true;
        });
      },
    );
  }

  void _showAddArticle() {
    _titleController.clear();
    _bodyController.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _bodyController, decoration: const InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = _titleController.text.trim();
              final body = _bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) return;
              setState(() {
                _articles.insert(0, _HelpArticle(title, 'Custom', body));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editArticle(_HelpArticle article) {
    _titleController.text = article.title;
    _bodyController.text = article.description;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            TextField(controller: _bodyController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final i = _articles.indexOf(article);
              if (i != -1) {
                setState(() {
                  _articles[i] = _HelpArticle(
                    _titleController.text.trim(),
                    article.category,
                    _bodyController.text.trim(),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteArticle(_HelpArticle article) {
    setState(() => _articles.remove(article));
  }

  void _addNewTicket() {
    final issueController = TextEditingController();
    String priority = 'Medium';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: issueController, decoration: const InputDecoration(labelText: 'Issue')),
              DropdownButton<String>(
                value: priority,
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (v) => setDialogState(() => priority = v ?? 'Medium'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (issueController.text.trim().isEmpty) return;
                setState(() {
                  _tickets.add(
                    _SupportTicket(
                      '#${2400 + _tickets.length + 1}',
                      issueController.text.trim(),
                      priority,
                      'Open',
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _changeTicketStatus(_SupportTicket ticket) {
    final statusOrder = ['Open', 'In Progress', 'Resolved'];
    final index = statusOrder.indexOf(ticket.status);
    final next = statusOrder[(index + 1) % statusOrder.length];
    final i = _tickets.indexOf(ticket);
    if (i != -1) {
      setState(() => _tickets[i] = _SupportTicket(ticket.id, ticket.issue, ticket.priority, next));
    }
  }

  void _deleteTicket(_SupportTicket ticket) {
    setState(() => _tickets.remove(ticket));
  }

  Widget _sectionWrapper({required String title, required Widget child, Widget? action}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D4F8B)),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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

  Widget _articleRow(
    String title,
    String category,
    String description, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.article),
      title: Text(title),
      subtitle: Text('$category - $description'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget _ticketRowWithActions(
    String id,
    String issue,
    String priority,
    String status, {
    VoidCallback? onStatusChange,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$id - $issue'),
      subtitle: Text('Priority: $priority'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onStatusChange, child: Text(status)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
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

class _HelpArticle {
  final String title;
  final String category;
  final String description;
  const _HelpArticle(this.title, this.category, this.description);
}

class _SupportTicket {
  final String id;
  final String issue;
  final String priority;
  final String status;
  const _SupportTicket(this.id, this.issue, this.priority, this.status);
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
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

