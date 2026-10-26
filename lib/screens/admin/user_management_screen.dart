import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../services/mysql_api_service.dart';
import '../../../widgets/admin_sidebar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final MySQLApiService _api = MySQLApiService();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _roles = const [
    'All',
    'patient',
    'caretaker',
    'doctor',
    'pharmacy',
    'admin',
  ];

  List<Map<String, dynamic>> _users = [];
  String _role = 'All';
  String? _error;
  String? _sourceMessage;
  bool _loading = true;
  int _page = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
      _sourceMessage = null;
    });
    final response = await _api.adminGetUsers(
      _role == 'All' ? null : _role,
      _searchController.text.trim(),
      _page,
      25,
    );
    if (!mounted) return;
    if (response['ok'] == true) {
      final users = response['users'] as List<dynamic>? ?? const [];
      final pagination = response['pagination'] as Map<String, dynamic>?;
      setState(() {
        _users = users
            .map((user) => Map<String, dynamic>.from(user as Map))
            .toList();
        _totalPages = (pagination?['totalPages'] as num?)?.toInt() ?? 0;
        _sourceMessage = response['source'] == 'local'
            ? response['message'] as String?
            : null;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response['message'] as String? ?? 'Unable to load users.';
      });
    }
  }

  Future<void> _createUser() async {
    final result = await _showUserDialog();
    if (result == null) return;
    final response = await _api.adminCreateUser(
      fullName: result['fullName'] as String,
      email: result['email'] as String,
      password: result['password'] as String,
      role: result['role'] as String,
      phoneNumber: result['phoneNumber'] as String?,
    );
    await _showResult(response, 'User created');
    if (response['ok'] == true) _loadUsers();
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    if (user['id'] is! num) {
      await _showResult({
        'ok': false,
        'message':
            'Local users cannot be edited until the backend is available.'
      }, 'User update failed');
      return;
    }
    final result = await _showUserDialog(user: user);
    if (result == null) return;
    final response = await _api.adminUpdateUser(
      (user['id'] as num).toInt(),
      fullName: result['fullName'] as String,
      role: result['role'] as String,
      phoneNumber: result['phoneNumber'] as String?,
    );
    await _showResult(response, 'User updated');
    if (response['ok'] == true) _loadUsers();
  }

  Future<void> _toggleStatus(Map<String, dynamic> user, bool active) async {
    final id = user['id'];
    if (id is! num) {
      await _showResult({
        'ok': false,
        'message':
            'Local users cannot be changed until the backend is available.'
      }, 'Status update failed');
      return;
    }
    final response = await _api.adminSetUserStatus(
      id.toInt(),
      active ? 'active' : 'inactive',
    );
    if (response['ok'] != true) {
      await _showResult(response, 'Status update failed');
    }
    _loadUsers();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
            'This permanently deletes ${user['email']}. Related records follow database foreign-key policies.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (user['id'] is! num) {
      await _showResult({
        'ok': false,
        'message':
            'Local users cannot be deleted until the backend is available.'
      }, 'User deletion failed');
      return;
    }
    final response = await _api.adminDeleteUser((user['id'] as num).toInt());
    await _showResult(response, 'User deleted');
    if (response['ok'] == true) _loadUsers();
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset password for ${user['email']}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reset')),
        ],
      ),
    );
    controller.dispose();
    if (password == null) return;
    final response = await _api.adminResetUserPassword(
        (user['id'] as num).toInt(), password);
    _showResult(response, 'Password reset');
  }

  Future<void> _showResult(
      Map<String, dynamic> response, String successMessage) async {
    if (!mounted) return;
    final message = response['ok'] == true
        ? successMessage
        : response['message'] as String? ?? 'Request failed.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: response['ok'] == true ? Colors.green : Colors.red,
    ));
  }

  Future<Map<String, dynamic>?> _showUserDialog(
      {Map<String, dynamic>? user}) async {
    final name =
        TextEditingController(text: user?['fullName'] as String? ?? '');
    final email = TextEditingController(text: user?['email'] as String? ?? '');
    final phone =
        TextEditingController(text: user?['phoneNumber'] as String? ?? '');
    final password = TextEditingController();
    String role = user?['role'] as String? ?? 'patient';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Create user' : 'Edit user'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                children: [
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Full name')),
                  TextField(
                    controller: email,
                    enabled: user == null,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (user == null)
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone (optional)'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _roles
                        .where((item) => item != 'All')
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => role = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'fullName': name.text.trim(),
                'email': email.text.trim(),
                'password': password.text,
                'phoneNumber':
                    phone.text.trim().isEmpty ? null : phone.text.trim(),
                'role': role,
              }),
              child: Text(user == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'User Management',
      activeRoute: AppRoutes.adminUserList,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) {
                      _page = 1;
                      _loadUsers();
                    },
                    decoration: InputDecoration(
                      labelText: 'Search name, email, or phone',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh)),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _role,
                  items: _roles
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _role = value;
                      _page = 1;
                    });
                    _loadUsers();
                  },
                ),
                FilledButton.icon(
                  onPressed: _createUser,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create user'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: _loadUsers, child: const Text('Retry')),
                ],
              ),
            ),
          if (_sourceMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_sourceMessage!,
                  style: TextStyle(color: Colors.orange.shade800)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          _error == null
                              ? 'No users found for the current filters.'
                              : 'No local users are available.',
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _users.map((user) {
                              final active = user['status'] == 'active';
                              return DataRow(cells: [
                                DataCell(
                                    Text(user['fullName'] as String? ?? '')),
                                DataCell(Text(user['email'] as String? ?? '')),
                                DataCell(Text((user['role'] as String? ?? '')
                                    .toUpperCase())),
                                DataCell(Switch(
                                    value: active,
                                    onChanged: (value) =>
                                        _toggleStatus(user, value))),
                                DataCell(Row(children: [
                                  IconButton(
                                      onPressed: () => _editUser(user),
                                      icon: const Icon(Icons.edit)),
                                  IconButton(
                                    onPressed: user['id'] is num
                                        ? () => _resetPassword(user)
                                        : null,
                                    icon: const Icon(Icons.lock_reset),
                                  ),
                                  IconButton(
                                    onPressed: user['id'] is num
                                        ? () => _deleteUser(user)
                                        : null,
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                  ),
                                ])),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_page of $_totalPages'),
                  IconButton(
                    onPressed: _page < _totalPages
                        ? () {
                            setState(() => _page++);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
