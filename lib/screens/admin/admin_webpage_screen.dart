import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
import 'package:smart_pill_reminder/services/database_service.dart';
import 'package:smart_pill_reminder/screens/auth/login_screen.dart';
import 'package:smart_pill_reminder/models/medicine.dart';

class AdminWebpageScreen extends StatefulWidget {
  const AdminWebpageScreen({super.key});

  @override
  State<AdminWebpageScreen> createState() => _AdminWebpageScreenState();
}

class _AdminWebpageScreenState extends State<AdminWebpageScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  int _selectedIndex = 0;
  List<Medicine> _medicines = [];
  bool _isLoading = true;

  final List<_AdminSection> _sections = const [
    _AdminSection('Dashboard', Icons.dashboard_outlined),
    _AdminSection('Medicines', Icons.medication),
    _AdminSection('Help Articles', Icons.article_outlined),
    _AdminSection('Support Tickets', Icons.support_agent_outlined),
    _AdminSection('System Settings', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final medicines = await _dbService.getAllMedicines();
      setState(() {
        _medicines = medicines;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medicines: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Pill Dispenser - Admin Panel'),
            backgroundColor: const Color(0xFF0D4F8B),
            elevation: 4,
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
                icon: const Icon(Icons.notifications_none),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ All systems operational')),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () {
                  authService.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: isWide ? null : _buildDrawer(),
          body: Row(
            children: [
              if (isWide) _buildRail(),
              Expanded(
                child: _buildSectionContent(),
              ),
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
      backgroundColor: Colors.grey.shade100,
      destinations: _sections
          .map(
            (section) => NavigationRailDestination(
              icon: Icon(section.icon),
              label: Text(section.title, style: const TextStyle(fontSize: 11)),
            ),
          )
          .toList(),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Container(
              color: const Color(0xFF0D4F8B),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Smart Pill Dispenser',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(),
            ..._sections.asMap().entries.map(
                  (entry) => ListTile(
                    leading: Icon(entry.value.icon, color: const Color(0xFF0D4F8B)),
                    title: Text(entry.value.title),
                    selected: _selectedIndex == entry.key,
                    selectedTileColor: const Color(0xFF0D4F8B).withOpacity(0.1),
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
        return _buildMedicines();
      case 2:
        return _buildArticles();
      case 3:
        return _buildTickets();
      case 4:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return _sectionWrapper(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                title: 'Total Medicines',
                value: _medicines.length.toString(),
                color: Colors.blue,
                icon: Icons.medication,
              ),
              _StatCard(
                title: 'Today\'s Reminders',
                value: '${_medicines.length * 2}',
                color: Colors.green,
                icon: Icons.notifications_active,
              ),
              _StatCard(
                title: 'App Users',
                value: '1,234',
                color: Colors.orange,
                icon: Icons.people,
              ),
              _StatCard(
                title: 'System Status',
                value: 'Online',
                color: Colors.purple,
                icon: Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _panel(
            title: 'Your Medications',
            child: _medicines.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No medications added yet'),
                  )
                : Column(
                    children: _medicines.take(5).map((medicine) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.medication_liquid, color: Colors.blue),
                        title: Text(medicine.name),
                        subtitle: Text('${medicine.dosage} at ${medicine.time}'),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Recent System Activity',
            child: Column(
              children: [
                _ActivityRow('Database Initialized', 'MYSQL storage active', '✅'),
                _ActivityRow('Notifications Enabled', 'Alarm reminders configured', '✅'),
                _ActivityRow('Authentication Active', 'Admin access granted', '✅'),
                _ActivityRow('Data Persistence', 'All medicines saved', '✅'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicines() {
    return _sectionWrapper(
      title: 'Medicines Management',
      action: ElevatedButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add new medicine from app interface')),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.medication, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No medicines added yet'),
                        const SizedBox(height: 8),
                        const Text(
                          'Add medicines from the app to see them here',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _panel(
                      title: 'All Medicines (${_medicines.length})',
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Medicine Name')),
                            DataColumn(label: Text('Dosage')),
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _medicines
                              .map((medicine) => DataRow(cells: [
                                    DataCell(Text(medicine.id?.toString() ?? 'N/A')),
                                    DataCell(Text(medicine.name)),
                                    DataCell(Text(medicine.dosage)),
                                    DataCell(Text(medicine.time)),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, size: 18),
                                          onPressed: () => _showMedicineDetails(medicine),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18, color: Colors.red),
                                          onPressed: () => ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Delete: ${medicine.name}',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                                  ]))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildArticles() {
    final List<_HelpArticle> articles = [
      _HelpArticle('How to add a medicine', 'Getting Started', 'Click the + button'),
      _HelpArticle('How reminders work', 'Features', 'Set daily reminders'),
      _HelpArticle('Edit medicines', 'Management', 'Tap to modify'),
      _HelpArticle('Delete medicines', 'Management', 'Swipe to remove'),
      _HelpArticle('Profile management', 'Account', 'Manage your profile'),
    ];

    return _sectionWrapper(
      title: 'Help Center Articles',
      action: ElevatedButton.icon(
        onPressed: () => _showAddArticle(context),
        icon: const Icon(Icons.add),
        label: const Text('New Article'),
      ),
      child: _panel(
        title: 'Published Articles (${articles.length})',
        child: Column(
          children: articles
              .map((article) => _articleRow(
                    article.title,
                    article.category,
                    article.description,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTickets() {
    final List<_SupportTicket> tickets = [
      _SupportTicket('#2401', 'Notifications not ringing', 'High', 'Open'),
      _SupportTicket('#2402', 'App crashes on edit', 'High', 'In Progress'),
      _SupportTicket('#2403', 'Sync issues with database', 'Medium', 'Open'),
      _SupportTicket('#2404', 'Reminder time incorrect', 'Medium', 'Resolved'),
      _SupportTicket('#2405', 'UI display glitch', 'Low', 'Open'),
    ];

    return _sectionWrapper(
      title: 'Support Tickets',
      child: _panel(
        title: 'Open Tickets (${tickets.where((t) => t.status == 'Open').length})',
        child: Column(
          children: tickets
              .map((ticket) => _ticketRow(
                    ticket.id,
                    ticket.issue,
                    ticket.priority,
                    ticket.status,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return _sectionWrapper(
      title: 'System Settings',
      child: Column(
        children: [
          _panel(
            title: 'Application Settings',
            child: Column(
              children: [
                _settingsRow('App Name', 'Smart Pill Dispenser'),
                _settingsRow('App Version', '1.0.0'),
                _settingsRow('Database Type', 'MYSQL'),
                _settingsRow('Admin Email', 'admin@medisafe.com'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Notification Settings',
            child: Column(
              children: [
                _settingsToggle('Reminder Notifications', true),
                _settingsToggle('Success Messages', true),
                _settingsToggle('Error Alerts', true),
                _settingsToggle('Email Notifications', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Support Settings',
            child: Column(
              children: [
                _settingsRow('Support Email', 'support@medisafe.com'),
                _settingsRow('Support Phone', '+91-878-009-5396'),
                _settingsRow('Help Center URL', 'medisafe.com/help'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Settings saved successfully')),
              ),
              icon: const Icon(Icons.save),
              label: const Text('Save All Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionWrapper({
    required String title,
    required Widget child,
    Widget? action,
  }) {
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D4F8B),
                  ),
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
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0D4F8B),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _articleRow(String title, String category, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.article, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$category • $description'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit: $title')),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete: $title')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              readOnly: true,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsToggle(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch(
            value: value,
            onChanged: (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label: ${!value ? 'Enabled' : 'Disabled'}')),
            ),
            activeColor: const Color(0xFF0D4F8B),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String id, String issue, String priority, String status) {
    final Color priorityColor = priority == 'High'
        ? Colors.red.shade100
        : priority == 'Medium'
            ? Colors.orange.shade100
            : Colors.green.shade100;

    final Color statusColor = status == 'Open'
        ? Colors.blue.shade100
        : status == 'In Progress'
            ? Colors.yellow.shade100
            : Colors.green.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('$id - $issue', style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(priority, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddArticle(BuildContext context) {
    _titleController.clear();
    _bodyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Article'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Article Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Article Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D4F8B),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Article created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create Article', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID', medicine.id?.toString() ?? 'N/A'),
            _detailRow('Dosage', medicine.dosage),
            _detailRow('Time', medicine.time),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label + ':', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Helper Classes
class _AdminSection {
  final String title;
  final IconData icon;

  const _AdminSection(this.title, this.icon);
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
    this.icon = Icons.analytics_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String detail;
  final String time;

  const _ActivityRow(this.title, this.detail, this.time);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle, size: 10, color: Colors.blue),
      title: Text(title),
      subtitle: Text(detail),
      trailing: Text(time),
    );
  }
}

class _HelpArticle {
  final String title;
  final String category;
  final String description;

  _HelpArticle(this.title, this.category, this.description);
}

class _SupportTicket {
  final String id;
  final String issue;
  final String priority;
  final String status;

  _SupportTicket(this.id, this.issue, this.priority, this.status);
}

class _UserRow extends StatelessWidget {
  final String name;
  final String email;
  final String status;

  const _UserRow(this.name, this.email, this.status);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(email),
      trailing: _StatusChip(text: status),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String id;
  final String issue;
  final String priority;
  final String status;

  const _TicketRow(this.id, this.issue, this.priority, this.status);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$id - $issue', style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: _StatusChip(text: priority),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final Color bgColor = text == 'High'
        ? Colors.red.shade100
        : text == 'Medium'
            ? Colors.orange.shade100
            : text == 'Low'
                ? Colors.green.shade100
                : Colors.blue.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

