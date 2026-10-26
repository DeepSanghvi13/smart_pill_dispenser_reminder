import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/mysql_api_service.dart';
import '../../../widgets/admin_sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final MySQLApiService _api = MySQLApiService();
  Map<String, dynamic> _stats = const {};
  String? _error;
  String? _sourceMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn || !auth.isAdmin) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (_) => false);
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _sourceMessage = null;
    });
    final response = await _api.adminGetDashboardStats();
    if (!mounted) return;
    if (response['ok'] == true) {
      setState(() {
        _stats = Map<String, dynamic>.from(response['stats'] as Map? ?? {});
        _sourceMessage = response['source'] == 'local'
            ? response['message'] as String?
            : null;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response['message'] as String? ??
            'Unable to load dashboard statistics.';
      });
    }
  }

  int _number(String key) => (_stats[key] as num?)?.toInt() ?? 0;

  int _roleCount(String role) {
    final users = _stats['users'] as List<dynamic>? ?? const [];
    for (final item in users) {
      final row = item as Map;
      if (row['role'] == role) return (row['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Admin Dashboard',
      activeRoute: AppRoutes.adminDashboard,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'System overview',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                          onPressed: _loadStats,
                          icon: const Icon(Icons.refresh)),
                    ],
                  ),
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error!,
                                style: TextStyle(color: Colors.red.shade900)),
                            const SizedBox(height: 8),
                            FilledButton(
                                onPressed: _loadStats,
                                child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ),
                  if (_sourceMessage != null)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_sourceMessage!,
                            style: TextStyle(color: Colors.orange.shade900)),
                      ),
                    ),
                  GridView.count(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    childAspectRatio: 1.8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _metric(
                          'Total users',
                          _roleCount('patient') +
                              _roleCount('caretaker') +
                              _roleCount('doctor') +
                              _roleCount('pharmacy') +
                              _roleCount('admin'),
                          Icons.people),
                      _metric('Active users', _number('activeUsers'),
                          Icons.verified_user),
                      _metric('Patients', _roleCount('patient'),
                          Icons.personal_injury),
                      _metric('Caretakers', _roleCount('caretaker'),
                          Icons.supervised_user_circle),
                      _metric('Doctors', _roleCount('doctor'),
                          Icons.medical_services),
                      _metric(
                          'Medicines', _number('medicines'), Icons.medication),
                      _metric('Prescriptions', _number('prescriptions'),
                          Icons.description),
                      _metric('Orders', _number('orders'), Icons.shopping_cart),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _metric(String title, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, overflow: TextOverflow.ellipsis),
                  Text('$value',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
