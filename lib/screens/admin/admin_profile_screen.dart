import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../models/user.dart';
import '../../../models/user_profile.dart';
import '../../../routes/app_routes.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;

  User? _adminUser;
  UserProfile? _adminProfile;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final email = auth.currentUser ?? 'admin@smartpill.com';

      final user = HiveService().usersBox.get(email);
      var profile = HiveService().profilesBox.get(email);

      if (profile == null && user != null) {
        profile = UserProfile(email: email, fullName: user.fullName);
        await HiveService().profilesBox.put(email, profile);
      }

      setState(() {
        _adminUser = user;
        _adminProfile = profile;
        _nameController.text = profile?.fullName ?? user?.fullName ?? '';
        _phoneController.text = profile?.mobileNumber ?? '';
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_adminUser == null) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final email = auth.currentUser ?? 'admin@smartpill.com';
      final now = DateTime.now();

      // Update User FullName
      final updatedUser = _adminUser!.copyWith(
        fullName: _nameController.text.trim(),
        updatedBy: email,
        updatedAt: now,
      );
      await HiveService().usersBox.put(email, updatedUser);

      // Update UserProfile
      final updatedProfile = (_adminProfile ?? UserProfile(email: email, fullName: _nameController.text.trim())).copyWith(
        fullName: _nameController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        updatedBy: email,
        updatedAt: now,
      );
      await HiveService().profilesBox.put(email, updatedProfile);

      await _db.adminLogActivity('Administrator profile information updated');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile information updated successfully.')),
      );
      _loadProfile();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_adminUser == null) return;
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters long.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final email = auth.currentUser ?? 'admin@smartpill.com';

      final updatedUser = _adminUser!.copyWith(
        password: newPassword,
        updatedBy: email,
        updatedAt: DateTime.now(),
      );
      await HiveService().usersBox.put(email, updatedUser);
      _passwordController.clear();

      await _db.adminLogActivity('Administrator account password updated');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      _loadProfile();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminLayout(
      title: 'Admin Profile Settings',
      activeRoute: AppRoutes.adminProfile,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        _adminUser?.fullName.isNotEmpty == true ? _adminUser!.fullName[0].toUpperCase() : 'A',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_adminUser?.fullName ?? 'Administrator', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_adminUser?.email ?? 'admin@smartpill.com', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        const Chip(
                          label: Text('SYSTEM ADMINISTRATOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.amberAccent,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 48),

                // Card 1: Profile Info
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update General Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _updateProfile,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Update Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card 2: Security settings
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change Admin Password',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'New Account Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _updatePassword,
                            icon: const Icon(Icons.security),
                            label: const Text('Change Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
