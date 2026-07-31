import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({super.key, required this.activeRoute});

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    final theme = Theme.of(context);
    final isActive = activeRoute == routeName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        selected: isActive,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, routeName);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 36, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MedReminder\nAdmin Portal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Navigation list
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  routeName: AppRoutes.adminDashboard,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_alt_outlined,
                  title: 'User Management',
                  routeName: AppRoutes.adminUserList,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.medication_outlined,
                  title: 'Medications',
                  routeName: AppRoutes.adminMedicineList,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Compliance Reports',
                  routeName: AppRoutes.adminReports,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.campaign_outlined,
                  title: 'Announcements',
                  routeName: AppRoutes.adminAnnouncements,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile Settings',
                  routeName: AppRoutes.adminProfile,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'System Settings',
                  routeName: AppRoutes.adminSettings,
                ),
              ],
            ),
          ),
          // Logout Section
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                final auth = context.read<AuthService>();
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout Confirmation'),
                    content: const Text('Are you sure you want to log out of the admin panel?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await auth.logout();
                  navigator.pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper screen layout that displays the sidebar and the main content responsively.
class AdminLayout extends StatelessWidget {
  final Widget body;
  final String activeRoute;
  final String title;

  const AdminLayout({
    super.key,
    required this.body,
    required this.activeRoute,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(activeRoute: activeRoute),
            ),
      body: Row(
        children: [
          if (isDesktop) AdminSidebar(activeRoute: activeRoute),
          Expanded(
            child: SafeArea(
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
