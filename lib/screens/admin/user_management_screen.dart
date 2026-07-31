import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../models/user.dart';
import '../../../models/user_profile.dart';
import '../../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;

  bool _isLoading = true;
  List<User> _users = [];
  List<UserProfile> _profiles = [];
  List<Map<String, dynamic>> _connections = [];

  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uBox = HiveService().usersBox;
      final pBox = HiveService().profilesBox;
      final cBox = HiveService().connectionsBox;

      setState(() {
        _users = uBox.values.toList();
        _profiles = pBox.values.toList();
        _connections = cBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _selectedRoleFilter == 'All' ||
          user.role.toLowerCase() == _selectedRoleFilter.toLowerCase();
          
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'patient';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge)),
                  items: const [
                    DropdownMenuItem(value: 'patient', child: Text('Patient')),
                    DropdownMenuItem(value: 'caretaker', child: Text('Caretaker')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final auth = context.read<AuthService>();
                final err = await auth.adminCreateUser(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  passwordController.text.trim(),
                  selectedRole,
                );

                if (err != null) {
                  if (!mounted || !ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  await _db.adminLogActivity('User Account Created: ${emailController.text.trim()} ($selectedRole)');
                  if (!mounted || !ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.fullName);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit User Details: ${user.email}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge)),
                items: const [
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                  DropdownMenuItem(value: 'caretaker', child: Text('Caretaker')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedRole = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = user.copyWith(
                  fullName: nameController.text.trim(),
                  role: selectedRole,
                  updatedBy: context.read<AuthService>().currentUser ?? 'admin',
                  updatedAt: DateTime.now(),
                );
                await HiveService().usersBox.put(user.email, updated);
                await _db.adminLogActivity('Updated Details for User: ${user.email}');
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(User user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for ${user.email}'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_open)),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim().length < 8) {
                  if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters.')),
                );
                return;
              }
              final auth = context.read<AuthService>();
              await auth.adminResetPassword(user.email, passwordController.text.trim());
              await _db.adminLogActivity('Password Reset for User: ${user.email}');
                if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully.')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showUserInspectionSheet(User user) {
    final profile = _profiles.firstWhere((p) => p.email == user.email, orElse: () => UserProfile(email: user.email, fullName: user.fullName));
    final userMeds = HiveService().medicinesBox.values.where((m) => m.userId == user.email || m.patientId == user.email).toList();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            const Text('Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _infoRow('Age', profile.age?.toString() ?? 'N/A'),
            _infoRow('Gender', profile.gender ?? 'N/A'),
            _infoRow('Phone', profile.mobileNumber ?? 'N/A'),
            _infoRow('Emergency Contact', profile.emergencyContact ?? 'N/A'),
            _infoRow('Blood Group', profile.bloodGroup ?? 'N/A'),
            _infoRow('Height / Weight', '${profile.height ?? 'N/A'} / ${profile.weight ?? 'N/A'}'),
            _infoRow('Medical Conditions', profile.medicalConditions ?? 'None declared'),
            _infoRow('Created At', DateFormat('yyyy-MM-dd HH:mm').format(user.createdAt)),
            _infoRow('Account Status', user.isActive ? 'Active' : 'Suspended'),

            const Divider(height: 32),
            Text("User's Scheduled Medicines (${userMeds.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (userMeds.isEmpty)
              const Text('No medications listed for this user.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            else
              ...userMeds.map((med) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.medication, color: Colors.teal),
                      title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${med.dosage} • ${med.frequency} at ${med.time}'),
                      trailing: Text(
                        med.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: med.status == 'taken' ? Colors.green : (med.status == 'skipped' ? Colors.red : Colors.orange),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddConnectionDialog() {
    final patients = _users.where((u) => u.role == 'patient').toList();
    final caretakers = _users.where((u) => u.role == 'caretaker').toList();

    if (patients.isEmpty || caretakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Must have at least one Patient and one Caretaker registered.')),
      );
      return;
    }

    String selectedPatient = patients[0].email;
    String selectedCaretaker = caretakers[0].email;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Connect Caretaker & Patient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCaretaker,
                decoration: const InputDecoration(labelText: 'Caretaker', prefixIcon: Icon(Icons.supervised_user_circle)),
                items: caretakers.map((u) => DropdownMenuItem(value: u.email, child: Text(u.fullName))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedCaretaker = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPatient,
                decoration: const InputDecoration(labelText: 'Patient', prefixIcon: Icon(Icons.person)),
                items: patients.map((u) => DropdownMenuItem(value: u.email, child: Text(u.fullName))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedPatient = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted || !ctx.mounted) return;
                final auth = context.read<AuthService>();
                await auth.adminLinkCaretakerAndPatient(selectedPatient, selectedCaretaker);
                await _db.adminLogActivity('Established Link: $selectedCaretaker to $selectedPatient');
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Link Accounts'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'User Management',
      activeRoute: AppRoutes.adminUserList,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.people), text: 'System Users'),
                    Tab(icon: Icon(Icons.link), text: 'Caretaker Connections'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Panel 1: User details table
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search by user name or email...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _searchQuery = val);
                                  },
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    DropdownButton<String>(
                                      value: _selectedRoleFilter,
                                      items: const [
                                        DropdownMenuItem(value: 'All', child: Text('All Roles')),
                                        DropdownMenuItem(value: 'Patient', child: Text('Patients')),
                                        DropdownMenuItem(value: 'Caretaker', child: Text('Caretakers')),
                                        DropdownMenuItem(value: 'Admin', child: Text('Admins')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedRoleFilter = val);
                                        }
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _showAddUserDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add User'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _filteredUsers.map((user) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(user.fullName)),
                                        DataCell(Text(user.email)),
                                        DataCell(Text(user.role.toUpperCase())),
                                        DataCell(
                                          Switch(
                                            value: user.isActive,
                                            onChanged: (val) async {
                                              final auth = context.read<AuthService>();
                                              await auth.adminToggleUserStatus(user.email, val);
                                              await _db.adminLogActivity(
                                                val ? 'Activated user ${user.email}' : 'Suspended user ${user.email}',
                                              );
                                              _loadData();
                                            },
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility, color: Colors.blue),
                                                onPressed: () => _showUserInspectionSheet(user),
                                                tooltip: 'Inspect Details',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.indigo),
                                                onPressed: () => _showEditUserDialog(user),
                                                tooltip: 'Edit Profile',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.lock_reset, color: Colors.orange),
                                                onPressed: () => _showResetPasswordDialog(user),
                                                tooltip: 'Reset Password',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Delete User'),
                                                      content: Text('Are you sure you want to permanently delete user ${user.email}? This action wipes all medicine logs and connection data.'),
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
                                                    if (!context.mounted) return;
                                                    final auth = context.read<AuthService>();
                                                    await auth.adminDeleteUser(user.email);
                                                    await _db.adminLogActivity('Permanently Deleted User: ${user.email}');
                                                    if (!mounted) return;
                                                    _loadData();
                                                  }
                                                },
                                                tooltip: 'Delete User',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Panel 2: Connections table
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Caretaker-Patient Connections',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showAddConnectionDialog,
                                  icon: const Icon(Icons.link),
                                  label: const Text('Link Caretaker & Patient'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _connections.isEmpty
                                ? const Center(child: Text('No active links declared.'))
                                : ListView.separated(
                                    itemCount: _connections.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (ctx, index) {
                                      final conn = _connections[index];
                                      final patientEmail = conn['patientId'] ?? '';
                                      final caretakerEmail = conn['caretakerId'] ?? '';
                                      final code = conn['connectionCode'] ?? '';

                                      final patientName = _users.firstWhere((u) => u.email == patientEmail, orElse: () => User(fullName: patientEmail, email: patientEmail, password: '')).fullName;
                                      final caretakerName = _users.firstWhere((u) => u.email == caretakerEmail, orElse: () => User(fullName: caretakerEmail, email: caretakerEmail, password: '')).fullName;

                                      return ListTile(
                                        leading: const CircleAvatar(
                                          child: Icon(Icons.group),
                                        ),
                                        title: Text('Patient: $patientName ↔ Caretaker: $caretakerName'),
                                        subtitle: Text('Emails: $patientEmail | $caretakerEmail\nLink Code: $code'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.link_off, color: Colors.red),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Unlink Connection'),
                                                content: const Text('Are you sure you want to sever the monitoring link between this Caretaker and Patient?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Unlink', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              if (!mounted || !ctx.mounted) return;
                                              final auth = context.read<AuthService>();
                                              await auth.adminUnlinkCaretakerAndPatient(conn['connectionId']);
                                              await _db.adminLogActivity('Severed monitoring link between $caretakerEmail and $patientEmail');
                                              if (!mounted) return;
                                              _loadData();
                                            }
                                          },
                                          tooltip: 'Break Monitoring Connection',
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
