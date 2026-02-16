import 'package:flutter/material.dart';

class AdminWebpageScreen extends StatefulWidget {
  const AdminWebpageScreen({super.key});

  @override
  State<AdminWebpageScreen> createState() => _AdminWebpageScreenState();
}

class _AdminWebpageScreenState extends State<AdminWebpageScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  int _selectedIndex = 0;

  final List<_AdminSection> _sections = const [
    _AdminSection('Dashboard', Icons.dashboard_outlined),
    _AdminSection('Articles', Icons.article_outlined),
    _AdminSection('Users', Icons.people_outline),
    _AdminSection('Tickets', Icons.support_agent_outlined),
    _AdminSection('Settings', Icons.settings_outlined),
  ];

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
            title: const Text('Admin Webpage'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => _showInfo(context, 'No new notifications'),
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
      destinations: _sections
          .map(
            (section) => NavigationRailDestination(
              icon: Icon(section.icon),
              label: Text(section.title),
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
            const ListTile(
              title: Text(
                'Admin Panel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Manage help center content'),
            ),
            const Divider(),
            ..._sections.asMap().entries.map(
                  (entry) => ListTile(
                    leading: Icon(entry.value.icon),
                    title: Text(entry.value.title),
                    selected: _selectedIndex == entry.key,
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
        return _buildArticles();
      case 2:
        return _buildUsers();
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
            children: const [
              _StatCard(title: 'Total Users', value: '1,234', color: Colors.blue),
              _StatCard(title: 'Active Today', value: '438', color: Colors.green),
              _StatCard(title: 'Open Tickets', value: '27', color: Colors.orange),
              _StatCard(title: 'Articles', value: '12', color: Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          _panel(
            title: 'Recent Activity',
            child: Column(
              children: const [
                _ActivityRow('New article published', 'Medication basics', '2h ago'),
                _ActivityRow('Ticket closed', 'Notification delay', '5h ago'),
                _ActivityRow('User verified email', 'john@example.com', '1d ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticles() {
    return _sectionWrapper(
      title: 'Articles',
      action: ElevatedButton.icon(
        onPressed: () => _showAddArticle(context),
        icon: const Icon(Icons.add),
        label: const Text('New Article'),
      ),
      child: Column(
        children: [
          _panel(
            title: 'Published Articles',
            child: Column(
              children: [
                _articleRow('How to add a medicine', 'Getting Started'),
                _articleRow('How reminders work', 'Features'),
                _articleRow('Edit or delete medicines', 'Management'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsers() {
    return _sectionWrapper(
      title: 'Users',
      child: _panel(
        title: 'Recent Users',
        child: Column(
          children: const [
            _UserRow('Jane Doe', 'jane@demo.com', 'Active'),
            _UserRow('Sam Patel', 'sam@demo.com', 'Active'),
            _UserRow('Rita Singh', 'rita@demo.com', 'Inactive'),
          ],
        ),
      ),
    );
  }

  Widget _buildTickets() {
    return _sectionWrapper(
      title: 'Tickets',
      child: _panel(
        title: 'Open Tickets',
        child: Column(
          children: const [
            _TicketRow('#1201', 'App crash on login', 'High'),
            _TicketRow('#1205', 'Notifications not ringing', 'Medium'),
            _TicketRow('#1210', 'Account update failed', 'Low'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return _sectionWrapper(
      title: 'Settings',
      child: Column(
        children: [
          _panel(
            title: 'Help Center Settings',
            child: Column(
              children: [
                _settingsRow('Support Email', 'support@medisafe.com'),
                _settingsRow('Support Phone', '+1-800-123-4567'),
                _settingsToggle('Enable article suggestions', true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _showInfo(context, 'Settings saved'),
              child: const Text('Save Changes'),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _articleRow(String title, String category) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _showInfo(context, 'Edit "$title"'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _showInfo(context, 'Delete "$title"'),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsToggle(String label, bool value) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (_) {},
    );
  }

  void _showAddArticle(BuildContext context) {
    _titleController.clear();
    _bodyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfo(context, 'Article created');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AdminSection {
  final String title;
  final IconData icon;

  const _AdminSection(this.title, this.icon);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
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
          Icon(Icons.analytics_outlined, color: color),
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

  const _TicketRow(this.id, this.issue, this.priority);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$id - $issue'),
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

