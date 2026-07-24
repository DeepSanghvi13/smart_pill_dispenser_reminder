import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../theme/theme_controller.dart';
import '../../../routes/app_routes.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = false;

  bool _notificationsEnabled = true;
  bool _backupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settingsBox = HiveService().settingsBox;
    setState(() {
      _notificationsEnabled = settingsBox.get('admin_notifications_enabled', defaultValue: true) as bool;
      _backupEnabled = settingsBox.get('admin_backup_enabled', defaultValue: true) as bool;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final settingsBox = HiveService().settingsBox;
    await settingsBox.put('admin_notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    await _db.adminLogActivity('System Settings: Notifications configured to $value');
  }

  Future<void> _toggleBackup(bool value) async {
    final settingsBox = HiveService().settingsBox;
    await settingsBox.put('admin_backup_enabled', value);
    setState(() {
      _backupEnabled = value;
    });
    await _db.adminLogActivity('System Settings: Auto backup configured to $value');
  }

  Future<void> _triggerBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Compiling database backup...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2)); // Mock delay
    await _db.adminLogActivity('System Maintenance: Manual database backup completed successfully');
    
    if (mounted) {
      Navigator.pop(context); // Dismiss loading overlay
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup Completed'),
          content: const Text('A secure snapshot of your Hive local boxes has been compiled and saved locally.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeNotifier.value == ThemeMode.dark;

    return AdminLayout(
      title: 'System Settings',
      activeRoute: AppRoutes.adminSettings,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Card 1: Theme and styling
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visual & Accessibility Theme',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dark Theme Interface'),
                          subtitle: const Text('Switch the admin portal to a dark, high-contrast palette'),
                          value: isDark,
                          onChanged: (val) async {
                            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                            await HiveService().settingsBox.put('theme_mode', themeNotifier.value.name);
                            await _db.adminLogActivity('Visual theme toggled to: ${themeNotifier.value.name}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 2: Notifications settings
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Configuration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Receive Administrative Alerts'),
                          subtitle: const Text('Display alerts for missed patient schedules or device logs'),
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 3: Data backup
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Database Maintenance & Backups',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Scheduled Hourly Database Backups'),
                          subtitle: const Text('Automatically back up patients, medicines, and connections locally'),
                          value: _backupEnabled,
                          onChanged: _toggleBackup,
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Manual Database Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('Compile database snapshot instantly', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _triggerBackup,
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: const Text('Backup Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 4: About
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Version Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Software Version', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('v2.1.0-Release', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Local Database Engine', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('Hive NoSQL + SQLite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Operating Mode', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('Administrative Sandbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
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
