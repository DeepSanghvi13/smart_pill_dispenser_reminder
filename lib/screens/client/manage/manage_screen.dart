import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_controller.dart';
import '../../../services/hive_service.dart';
import '../../../models/user_profile.dart';
import '../../../services/database_service.dart';
import 'create_profile_screen.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  void _loadNotificationSetting() {
    final email = context.read<AuthService>().currentUser ?? 'guest';
    final settings = HiveService().settingsBox;
    setState(() {
      _notificationsEnabled = settings.get('${email}_notifications_enabled', defaultValue: true) as bool;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final email = context.read<AuthService>().currentUser ?? 'guest';
    final settings = HiveService().settingsBox;
    await settings.put('${email}_notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is extremely important to us. PillDispenser stores all of your personal details, profile picture, medication logs, and notification reminders directly on your local device. We do not transmit or upload your health records or personal identifiers to any remote servers.\n\nYour data remains securely on your device unless you choose to wipe the application data or delete your account, which completely clears all stored variables from local sandbox storage.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Frequently Asked Questions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Q: How do I mark a medicine as taken?\nA: Simply press the checkmark button next to any medication card on the Home Screen.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Q: Are my medications private?\nA: Yes, all records are stored in your local Hive database and never shared.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About PillDispenser'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_liquid, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'PillDispenser App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text('Version 3.0.0 (Local Hive Caretaker Build)', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text(
              'Designed to manage your medicine reminder requirements locally and privately with support for Caregivers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthService>().logout();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'WARNING: This action is permanent! It will delete your profile, user settings, connection lists, and cancel all notifications. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthService>().deleteAccount();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account and data deleted successfully.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);
    final auth = context.watch<AuthService>();
    final isCare = auth.isCaretaker;

    final content = ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        final isDarkMode = currentThemeMode == ThemeMode.dark;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Settings Header Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Personalization',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            // Profile view and edit item
            _settingsCardTile(
              icon: Icons.person_outline,
              title: 'My Profile',
              subtitle: 'View and edit your personal medical card',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProfileScreen(isEditing: true),
                  ),
                );
              },
            ),

            // Theme Switcher Tile
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isDarkMode ? 'Enable light UI' : 'Enable dark UI'),
                value: isDarkMode,
                onChanged: (bool value) async {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  themeNotifier.value = newMode;
                  await HiveService().settingsBox.put('theme_mode', newMode.name);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Notification toggle
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                secondary: Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Reminders & Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Toggle push notifications on/off'),
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
            ),
            const SizedBox(height: 16),

            // Connected Caretakers / Connected Patients Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isCare ? 'My Connected Patients' : 'Connected Caregivers',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            if (isCare) ...[
              FutureBuilder<UserProfile?>(
                future: DatabaseService().getUserProfileData(),
                builder: (context, snapshot) {
                  final patients = auth.getConnectedPatients();
                  if (patients.isEmpty) {
                    return _buildEmptyListMessage(
                      'No connected patients yet. Enter connection codes on home screen.'
                    );
                  }
                  return Column(
                    children: patients.map((p) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.link_off, color: Colors.red),
                            tooltip: 'Remove connection',
                            onPressed: () {
                              auth.disconnectPatient(p.email);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              ),
            ] else ...[
              FutureBuilder<UserProfile?>(
                future: DatabaseService().getUserProfileData(),
                builder: (context, snapshot) {
                  final caretakers = auth.getConnectedCaretakers();
                  final connectionCode = snapshot.data?.connectionCode ?? 'N/A';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Patient's own connection code card
                      Card(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Patient Connection Code',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    connectionCode,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const Icon(Icons.share, size: 20, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (caretakers.isEmpty)
                        _buildEmptyListMessage(
                          'No connected caregivers yet. Share the code above to allow a family member to monitor your medicines.'
                        )
                      else
                        ...caretakers.map((c) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
                              title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Relationship: ${c.relationship ?? 'Caregiver'} • ${c.email}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.link_off, color: Colors.red),
                                tooltip: 'Remove connection',
                                onPressed: () {
                                  auth.disconnectCaretaker(c.email);
                                },
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                }
              ),
            ],
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Support & Legal',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            _settingsCardTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we manage your local data privacy',
              onTap: _showPrivacyPolicy,
            ),
            _settingsCardTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              subtitle: 'FAQs and support manuals',
              onTap: _showHelp,
            ),
            _settingsCardTile(
              icon: Icons.info_outline,
              title: 'About PillDispenser',
              subtitle: 'Application version details',
              onTap: _showAbout,
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            _settingsCardTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'End current session',
              iconColor: Colors.orange,
              onTap: _handleLogout,
            ),
            _settingsCardTile(
              icon: Icons.delete_forever,
              title: 'Delete My Account',
              subtitle: 'Permanently wipe all logs & settings',
              iconColor: Colors.red,
              onTap: _handleDeleteAccount,
            ),
          ],
        );
      },
    );

    if (canPop) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: content,
      );
    }
    return content;
  }

  Widget _buildEmptyListMessage(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _settingsCardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
