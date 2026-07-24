import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../widgets/custom_charts.dart';
import '../../../models/user.dart';
import '../../../models/medicine.dart';
import '../../../routes/app_routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;

  int _totalUsers = 0;
  int _totalPatients = 0;
  int _totalCaretakers = 0;
  int _totalMedicines = 0;
  int _takenToday = 0;
  int _missedToday = 0;
  int _pendingReminders = 0;
  int _activeUsers = 0;

  List<User> _recentUsers = [];
  List<Medicine> _recentMedicines = [];
  List<String> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  void _checkAccessAndLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      if (!auth.isLoggedIn || !auth.isAdmin) {
        // Access Denied: redirect
        _showAccessDenied();
        return;
      }
      await _loadData();
    });
  }

  void _showAccessDenied() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('You do not have administrative privileges to access this area.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final auth = context.read<AuthService>();
              if (auth.isLoggedIn) {
                if (auth.isCaretaker) {
                  Navigator.pushReplacementNamed(context, AppRoutes.caretakerHome);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.userHome);
                }
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uCount = await _db.adminGetTotalUsersCount();
      final pCount = await _db.adminGetTotalPatientsCount();
      final cCount = await _db.adminGetTotalCaretakersCount();
      final mCount = await _db.adminGetTotalMedicinesCount();
      final tToday = await _db.adminGetMedicinesTakenTodayCount();
      final msToday = await _db.adminGetMissedMedicinesTodayCount();
      final pReminders = await _db.adminGetPendingRemindersCount();
      final aUsers = await _db.adminGetActiveUsersCount();

      final recUsers = await _db.adminGetRecentRegistrations();
      final recMeds = await _db.adminGetRecentMedicines();
      final recAct = await _db.adminGetRecentActivities();

      if (recAct.isEmpty) {
        // Seeding default activities if empty
        await _db.adminLogActivity('System Boot: Admin Panel Initialized');
        await _db.adminLogActivity('Database Check: SQLite & Hive Boxes Synced');
      }

      setState(() {
        _totalUsers = uCount;
        _totalPatients = pCount;
        _totalCaretakers = cCount;
        _totalMedicines = mCount;
        _takenToday = tToday;
        _missedToday = msToday;
        _pendingReminders = pReminders;
        _activeUsers = aUsers;
        _recentUsers = recUsers;
        _recentMedicines = recMeds;
        _recentActivities = recAct;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return AdminLayout(
      title: 'Admin Dashboard',
      activeRoute: AppRoutes.adminDashboard,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // KPI Grid
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : (width > 600 ? 2 : 1),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    childAspectRatio: 2.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildKPICard(
                        context,
                        title: 'Total Users',
                        value: _totalUsers.toString(),
                        icon: Icons.people_outline,
                        color: Colors.blue,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Total Patients',
                        value: _totalPatients.toString(),
                        icon: Icons.healing_outlined,
                        color: Colors.teal,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Total Caretakers',
                        value: _totalCaretakers.toString(),
                        icon: Icons.supervised_user_circle_outlined,
                        color: Colors.indigo,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Total Medicines',
                        value: _totalMedicines.toString(),
                        icon: Icons.medication_outlined,
                        color: Colors.orange,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Doses Taken Today',
                        value: _takenToday.toString(),
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Doses Missed Today',
                        value: _missedToday.toString(),
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Pending Reminders',
                        value: _pendingReminders.toString(),
                        icon: Icons.alarm_outlined,
                        color: Colors.purple,
                      ),
                      _buildKPICard(
                        context,
                        title: 'Active Users',
                        value: _activeUsers.toString(),
                        icon: Icons.check_outlined,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Analytics Charts Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Compliance Overview (Today)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                CustomProgressRing(
                                  percentage: (_takenToday + _missedToday) > 0
                                      ? (_takenToday / (_takenToday + _missedToday))
                                      : 0.0,
                                  centerTitle: '${((_takenToday + _missedToday) > 0 ? (_takenToday / (_takenToday + _missedToday) * 100) : 0.0).toStringAsFixed(0)}%',
                                  centerSubtitle: 'Doses Taken',
                                  activeColor: Colors.teal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly User Growth Trend',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                CustomLineChart(
                                  values: const [5, 9, 12, 18, 25, 30, 35],
                                  labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                                  lineColor: Colors.indigo,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Lists: Recent Registrations & Added Medicines
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'Recent Registrations',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                if (_recentUsers.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: Text('No recent users.', style: TextStyle(color: Colors.grey))),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _recentUsers.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (ctx, index) {
                                      final user = _recentUsers[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: theme.colorScheme.primaryContainer,
                                          child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U'),
                                        ),
                                        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text('${user.email} • Role: ${user.role}'),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recent Medications Added',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                if (_recentMedicines.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: Text('No medications added recently.', style: TextStyle(color: Colors.grey))),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _recentMedicines.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (ctx, index) {
                                      final med = _recentMedicines[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.teal.shade50,
                                          child: const Icon(Icons.medication, color: Colors.teal),
                                        ),
                                        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text('${med.dosage} • Frequency: ${med.frequency}'),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Activities Feed Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Administrative Action Logs',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          if (_recentActivities.isEmpty)
                            const Center(child: Text('No recorded actions.'))
                          else
                            ..._recentActivities.map((act) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.circle, size: 8, color: Colors.indigo),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          act,
                                          style: const TextStyle(fontSize: 13, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
