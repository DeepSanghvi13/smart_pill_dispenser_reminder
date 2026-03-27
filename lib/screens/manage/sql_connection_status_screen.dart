import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/sync_provider.dart';
import '../../screens/manage/sql_category_entries_screen.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/mysql_api_service.dart';
import '../../widgets/sql_status_card.dart';

class SqlConnectionStatusScreen extends StatefulWidget {
  const SqlConnectionStatusScreen({super.key});

  @override
  State<SqlConnectionStatusScreen> createState() =>
      _SqlConnectionStatusScreenState();
}

class _SqlConnectionStatusScreenState extends State<SqlConnectionStatusScreen> {
  static const String _keyPendingSync = 'pending_mysql_sync';
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  bool _isChecking = true;
  bool _isRefreshing = false;
  bool _apiConnected = false;
  bool _localDbReady = false;
  bool _pendingSync = false;
  int? _latencyMs;
  DateTime? _lastCheckedAt;
  DateTime? _lastHeartbeatAt;
  String _activeEndpoint = 'Unknown';
  Timer? _heartbeatTimer;

  Map<String, int> _counts = <String, int>{};
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _authLogs = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _medicines = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reminders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _alarmLogs = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _caretakers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _dependents = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _settings = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _refreshStatus(silent: true, fromHeartbeat: true);
    });
  }

  Future<void> _refreshStatus({
    bool silent = false,
    bool fromHeartbeat = false,
  }) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    if (!silent && mounted) {
      setState(() => _isChecking = true);
    }

    final stopwatch = Stopwatch()..start();
    final api = MySQLApiService();
    final apiConnected = await api.checkServerConnection();
    stopwatch.stop();

    if (apiConnected) {
      await _loadEntries(api);
    }

    bool localDbReady;
    try {
      await DatabaseService().database;
      localDbReady = true;
    } catch (_) {
      localDbReady = false;
    }

    final prefs = await SharedPreferences.getInstance();
    final pendingSync = prefs.getBool(_keyPendingSync) ?? false;

    if (!mounted) return;

    setState(() {
      _apiConnected = apiConnected;
      _localDbReady = localDbReady;
      _pendingSync = pendingSync;
      _activeEndpoint = api.currentBaseUrl;
      _latencyMs = stopwatch.elapsedMilliseconds;
      _lastCheckedAt = DateTime.now();
      if (fromHeartbeat) {
        _lastHeartbeatAt = DateTime.now();
      }
      _isChecking = false;
    });

    _isRefreshing = false;
  }

  Future<void> _loadEntries(MySQLApiService api) async {
    final data = await api.getAdminSqlEntries();
    if (data == null || !mounted) return;

    final countsMap =
        data['counts'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    int countFor(String key) => (countsMap[key] as int?) ?? 0;

    List<Map<String, dynamic>> parseList(String key) {
      final raw = data[key] as List<dynamic>? ?? const <dynamic>[];
      return raw.whereType<Map<String, dynamic>>().toList();
    }

    setState(() {
      _counts = <String, int>{
        'users': countFor('users'),
        'authLogs': countFor('authLogs'),
        'medicines': countFor('medicines'),
        'reminders': countFor('reminders'),
        'alarmLogs': countFor('alarmLogs'),
        'caretakers': countFor('caretakers'),
        'dependents': countFor('dependents'),
        'settings': countFor('settings'),
      };
      _users = parseList('users');
      _authLogs = parseList('authLogs');
      _medicines = parseList('medicines');
      _reminders = parseList('reminders');
      _alarmLogs = parseList('alarmLogs');
      _caretakers = parseList('caretakers');
      _dependents = parseList('dependents');
      _settings = parseList('settings');
    });
  }

  Widget _buildCountsTile(String title, int value, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        '$value',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openCategoryPage({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> rows,
    required List<String> columns,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SqlCategoryEntriesScreen(
          title: title,
          icon: icon,
          rows: rows,
          columns: columns,
        ),
      ),
    );
  }

  Widget _buildCategoryPageTile({
    required String title,
    required IconData icon,
    required int count,
    required List<Map<String, dynamic>> rows,
    required List<String> columns,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('$count records. Tap to search, sort, and filter.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openCategoryPage(
          title: title,
          icon: icon,
          rows: rows,
          columns: columns,
        ),
      ),
    );
  }

  Future<void> _retryPendingSync() async {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required before sync retry.')),
      );
      return;
    }

    final syncProvider = context.read<SyncProvider>();
    final success = await syncProvider.retryPendingSync(userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pending SQL sync completed.'
              : 'Retry failed. SQL server still unreachable.',
        ),
      ),
    );

    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final apiColor = _apiConnected ? Colors.green : Colors.red;
    final localColor = _localDbReady ? Colors.green : Colors.red;
    final pendingColor = _pendingSync ? Colors.orange : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SQL'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.favorite, color: Colors.green),
          ),
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _isRefreshing ? null : _refreshStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            SqlStatusCard(
              icon: Icons.favorite_outline,
              title: 'Heartbeat Reload',
              status: 'Auto every ${_heartbeatInterval.inSeconds}s',
              subtitle: _lastHeartbeatAt == null
                  ? 'Waiting for first heartbeat tick...'
                  : 'Last heartbeat at ${_lastHeartbeatAt!.toLocal()}',
              color: Colors.teal,
            ),
            SqlStatusCard(
              icon: Icons.swipe_down_outlined,
              title: 'Manual Refresh',
              status: 'Pull down to refresh',
              subtitle: 'Use pull-to-refresh gesture for manual checks.',
              color: Colors.indigo,
            ),
            SqlStatusCard(
              icon: Icons.cloud_done_outlined,
              title: 'Remote SQL API',
              status: _apiConnected ? 'Connected' : 'Disconnected',
              subtitle: 'Endpoint: $_activeEndpoint',
              color: apiColor,
            ),
            SqlStatusCard(
              icon: Icons.storage_outlined,
              title: 'Local Database',
              status: _localDbReady ? 'Ready' : 'Unavailable',
              subtitle: 'Local storage availability for offline mode',
              color: localColor,
            ),
            SqlStatusCard(
              icon: Icons.sync_problem,
              title: 'Pending Sync Queue',
              status: _pendingSync ? 'Pending' : 'Clear',
              subtitle: _pendingSync
                  ? 'Some local changes are waiting for SQL sync.'
                  : 'No pending SQL sync tasks.',
              color: pendingColor,
              trailing: _pendingSync
                  ? ElevatedButton.icon(
                      onPressed: _retryPendingSync,
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Retry'),
                    )
                  : null,
            ),
            SqlStatusCard(
              icon: Icons.speed_outlined,
              title: 'Last Check Latency',
              status: _latencyMs == null ? '-' : '$_latencyMs ms',
              subtitle: _lastCheckedAt == null
                  ? null
                  : 'Checked at ${_lastCheckedAt!.toLocal()}',
              color: Colors.blue,
            ),
            const SizedBox(height: 6),
            const ListTile(
              leading: Icon(Icons.table_view_outlined),
              title: Text(
                'MySQL Admin Entries (Live)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Includes login and registration records.'),
            ),
            _buildCountsTile('Users', _counts['users'] ?? 0, Icons.people),
            _buildCountsTile(
                'Login/Registration Logs', _counts['authLogs'] ?? 0, Icons.key),
            _buildCountsTile(
                'Medicines', _counts['medicines'] ?? 0, Icons.medication),
            _buildCountsTile(
                'Reminders', _counts['reminders'] ?? 0, Icons.alarm),
            _buildCountsTile(
                'Alarm Logs', _counts['alarmLogs'] ?? 0, Icons.history),
            _buildCountsTile(
                'Caretakers', _counts['caretakers'] ?? 0, Icons.groups),
            _buildCountsTile('Dependents', _counts['dependents'] ?? 0,
                Icons.family_restroom),
            _buildCountsTile(
                'Settings', _counts['settings'] ?? 0, Icons.settings),
            _buildCategoryPageTile(
              title: 'Users',
              icon: Icons.people,
              count: _counts['users'] ?? 0,
              rows: _users,
              columns: const ['id', 'email', 'isAdmin', 'createdAt'],
            ),
            _buildCategoryPageTile(
              title: 'Login & Registration Logs',
              icon: Icons.key,
              count: _counts['authLogs'] ?? 0,
              rows: _authLogs,
              columns: const [
                'id',
                'email',
                'eventType',
                'status',
                'source',
                'createdAt'
              ],
            ),
            _buildCategoryPageTile(
              title: 'Medicines',
              icon: Icons.medication,
              count: _counts['medicines'] ?? 0,
              rows: _medicines,
              columns: const ['id', 'userId', 'name', 'dosage', 'time'],
            ),
            _buildCategoryPageTile(
              title: 'Reminders',
              icon: Icons.alarm,
              count: _counts['reminders'] ?? 0,
              rows: _reminders,
              columns: const [
                'id',
                'userId',
                'medicineName',
                'time',
                'isActive'
              ],
            ),
            _buildCategoryPageTile(
              title: 'Alarm Logs',
              icon: Icons.history,
              count: _counts['alarmLogs'] ?? 0,
              rows: _alarmLogs,
              columns: const [
                'id',
                'userId',
                'medicineName',
                'status',
                'scheduledTime'
              ],
            ),
            _buildCategoryPageTile(
              title: 'Caretakers',
              icon: Icons.groups,
              count: _counts['caretakers'] ?? 0,
              rows: _caretakers,
              columns: const [
                'id',
                'userId',
                'firstName',
                'lastName',
                'email',
                'relationship'
              ],
            ),
            _buildCategoryPageTile(
              title: 'Dependents',
              icon: Icons.family_restroom,
              count: _counts['dependents'] ?? 0,
              rows: _dependents,
              columns: const [
                'id',
                'userId',
                'firstName',
                'lastName',
                'gender',
                'birthDate'
              ],
            ),
            _buildCategoryPageTile(
              title: 'Settings',
              icon: Icons.settings,
              count: _counts['settings'] ?? 0,
              rows: _settings,
              columns: const ['id', 'userId', 'keyName', 'value', 'updatedAt'],
            ),
          ],
        ),
      ),
    );
  }
}
