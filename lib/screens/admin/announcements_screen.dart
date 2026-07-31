import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  bool _isBroadcasting = false;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedAudience = 'All Users'; // 'All Users', 'Patients Only', 'Caretakers Only'

  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final notifBox = HiveService().notificationsBox;
      // Filter out only announcements (notifications with payload containing 'type': 'announcement')
      final list = <Map<String, dynamic>>[];
      for (final key in notifBox.keys) {
        final notif = Map<String, dynamic>.from(notifBox.get(key) as Map);
        if (notif['type'] == 'announcement') {
          list.add(notif);
        }
      }
      list.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));

      setState(() {
        _announcements = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendAnnouncement() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and body for the announcement.')),
      );
      return;
    }

    setState(() => _isBroadcasting = true);
    try {
      final notifBox = HiveService().notificationsBox;
      final usersBox = HiveService().usersBox;
      final currentAdmin = context.read<AuthService>().currentUser ?? 'admin';
      final now = DateTime.now();

      final announcementId = 'ann_${now.millisecondsSinceEpoch}';
      final payload = {
        'notificationId': announcementId,
        'type': 'announcement',
        'title': title,
        'body': body,
        'audience': _selectedAudience,
        'createdBy': currentAdmin,
        'updatedBy': currentAdmin,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Save main broadcast log
      await notifBox.put(announcementId, payload);

      // Distribute copy of the announcement to targeted users' notification feeds
      for (final user in usersBox.values) {
        bool isAudience = false;
        if (_selectedAudience == 'All Users') {
          isAudience = true;
        } else if (_selectedAudience == 'Patients Only' && user.role == 'patient') {
          isAudience = true;
        } else if (_selectedAudience == 'Caretakers Only' && user.role == 'caretaker') {
          isAudience = true;
        }

        if (isAudience) {
          final userNotifId = '${announcementId}_${user.email}';
          final userPayload = {
            'notificationId': userNotifId,
            'type': 'announcement',
            'title': title,
            'body': body,
            'patientId': user.email,
            'patientName': user.fullName,
            'medicineName': 'Announcement',
            'scheduledTime': 'System Announcement',
            'createdBy': currentAdmin,
            'updatedBy': currentAdmin,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };
          await notifBox.put(userNotifId, userPayload);
        }
      }

      await _db.adminLogActivity('Broadcasted announcement "$title" to $_selectedAudience');

      _titleController.clear();
      _bodyController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement successfully broadcasted to $_selectedAudience.')),
        );
      }
      
      setState(() => _isBroadcasting = false);
      await _loadAnnouncements();
    } catch (_) {
      setState(() => _isBroadcasting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminLayout(
      title: 'Announcements Board',
      activeRoute: AppRoutes.adminAnnouncements,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Composer Panel
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compose System Announcement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Announcement Title',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bodyController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Message Body',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(Icons.message_outlined),
                            ),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DropdownButton<String>(
                              value: _selectedAudience,
                              items: const [
                                DropdownMenuItem(value: 'All Users', child: Text('All Registered Users')),
                                DropdownMenuItem(value: 'Patients Only', child: Text('Patients Only')),
                                DropdownMenuItem(value: 'Caretakers Only', child: Text('Caretakers Only')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedAudience = val);
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              onPressed: _isBroadcasting ? null : _sendAnnouncement,
                              icon: _isBroadcasting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Broadcast'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // History Panel
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Broadcasting Log History',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        if (_announcements.isEmpty)
                          const Center(child: Text('No announcements have been broadcasted.'))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _announcements.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final ann = _announcements[index];
                              final date = ann['createdAt'] != null
                                  ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(ann['createdAt'] as String))
                                  : 'N/A';
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  child: const Icon(Icons.campaign, color: Colors.indigo),
                                ),
                                title: Text(ann['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${ann['body']}\nAudience: ${ann['audience']} • Date: $date\nCreated By: ${ann['createdBy']}',
                                  style: const TextStyle(height: 1.3),
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Announcement'),
                                        content: const Text('Are you sure you want to permanently delete this broadcast log?'),
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
                                      final notifBox = HiveService().notificationsBox;
                                      await notifBox.delete(ann['notificationId']);
                                      await _db.adminLogActivity('Deleted announcement broadcast logs: ${ann['title']}');
                                      _loadAnnouncements();
                                    }
                                  },
                                ),
                              );
                            },
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
