import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/medicine.dart';
import '../../../models/user_profile.dart';
import '../../../providers/medicine_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../widgets/bottom_nav.dart';
import '../../../widgets/app_drawer.dart';
import 'package:smart_pill_reminder/routes/app_routes.dart';

import '../updates/updates_screen.dart';
import '../medications/medications_screen.dart';
import '../manage/manage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<MedicineProvider>().loadMedicines();
      }
    });
  }

  Widget _buildCurrentPage(List<Medicine> medicines, String userName, String? profilePic) {
    switch (_currentIndex) {
      case 0:
        return HomeBody(
          medicines: medicines,
          userName: userName,
          profilePic: profilePic,
          searchQuery: _searchQuery,
          onSearchChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          onEdit: _editMedicine,
          onDelete: _deleteMedicine,
        );
      case 1:
        return const UpdatesScreen();
      case 2:
        return MedicationsScreen(
          medicines: medicines,
          onAddMed: _addMedicine,
          onEdit: _editMedicine,
          onDelete: _deleteMedicine,
        );
      case 3:
        return const ManageScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _addMedicine() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addMedication);
    if (!mounted) return;

    if (result != null && result is Medicine) {
      final provider = context.read<MedicineProvider>();
      final id = await provider.addMedicine(result);
      if (id != null && id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _editMedicine(int index) async {
    final provider = context.read<MedicineProvider>();
    final medicines = provider.medicines;
    if (index < 0 || index >= medicines.length) return;

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addMedication,
      arguments: medicines[index],
    );
    if (!mounted) return;

    if (result != null && result is Medicine) {
      final medicineId = medicines[index].id;
      if (medicineId != null) {
        final success = await provider.updateMedicine(medicineId, result);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine updated successfully'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  void _deleteMedicine(int index) {
    final provider = context.read<MedicineProvider>();
    final medicines = provider.medicines;
    if (index < 0 || index >= medicines.length) return;

    final medicineId = medicines[index].id;
    if (medicineId == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine and cancel its notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteMedicine(medicineId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medicine deleted'), backgroundColor: Colors.red),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines = medicineProvider.medicines;
    final currentUserEmail = context.watch<AuthService>().currentUser ?? 'Guest';

    return FutureBuilder<UserProfile?>(
      future: DatabaseService().getUserProfileData(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final userName = profile?.fullName ?? currentUserEmail.split('@').first;
        final profilePic = profile?.profilePicture;

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Text(_currentIndex == 0 ? 'PillDispenser' : _currentIndex == 2 ? 'My Medications' : 'Settings'),
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: MedicineSearchDelegate(
                        medicines: medicines,
                        onEdit: _editMedicine,
                        onDelete: _deleteMedicine,
                      ),
                    );
                  },
                ),
            ],
          ),
          body: _buildCurrentPage(medicines, userName, profilePic),
          floatingActionButton: (_currentIndex == 0 || _currentIndex == 2)
              ? FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  onPressed: _addMedicine,
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: BottomNav(
            index: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        );
      },
    );
  }
}

// ================= HOME BODY =================

class HomeBody extends StatelessWidget {
  final List<Medicine> medicines;
  final String userName;
  final String? profilePic;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const HomeBody({
    super.key,
    required this.medicines,
    required this.userName,
    this.profilePic,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onEdit,
    required this.onDelete,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  DateTime? _getScheduledDateTime(String timeStr) {
    final clean = timeStr.trim();
    final formats = [
      DateFormat('h:mm a'),
      DateFormat('hh:mm a'),
      DateFormat('H:mm'),
      DateFormat('HH:mm'),
    ];
    for (final format in formats) {
      try {
        final parsed = format.parse(clean);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
      } catch (_) {}
    }

    // Manual fallback for 24-hour time strings
    try {
      final parts = clean.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        final minute = int.parse(minStr);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Filter Today's Medicines
    final todayMedicines = medicines.where((m) {
      final start = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
      final end = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);
      return !today.isBefore(start) && !today.isAfter(end);
    }).toList();

    // 2. Group today's medicines
    final completed = <Medicine>[];
    final upcoming = <Medicine>[];
    final missed = <Medicine>[];

    for (final m in todayMedicines) {
      final status = m.getDailyStatus();
      if (status == 'taken') {
        completed.add(m);
      } else if (status == 'skipped') {
        missed.add(m);
      } else {
        // Pending status
        final scheduledTime = _getScheduledDateTime(m.time);
        if (scheduledTime != null && scheduledTime.isBefore(now)) {
          missed.add(m);
        } else {
          upcoming.add(m);
        }
      }
    }

    // Recent medicines (overall)
    final recentMedicines = medicines.reversed.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MedicineProvider>().loadMedicines();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Greeting Backplate
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d').format(now),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getGreeting()},\n$userName',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: profilePic != null && profilePic!.isNotEmpty
                        ? FileImage(File(profilePic!))
                        : null,
                    child: profilePic == null
                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Overview counters
          _buildQuickSummary(context, upcoming.length, completed.length, missed.length),
          const SizedBox(height: 24),

          // Upcoming Section
          _buildCategoryHeader(context, "Upcoming Medicines", upcoming.length, Colors.blue),
          if (upcoming.isEmpty)
            _buildEmptyState("No upcoming medications left for today.")
          else
            ...upcoming.map((m) => _buildMedicineActionCard(context, m, theme)),
          const SizedBox(height: 20),

          // Missed Section
          _buildCategoryHeader(context, "Missed / Skipped", missed.length, Colors.red),
          if (missed.isEmpty)
            _buildEmptyState("No missed medications today. Good job!")
          else
            ...missed.map((m) => _buildMedicineActionCard(context, m, theme)),
          const SizedBox(height: 20),

          // Completed Section
          _buildCategoryHeader(context, "Completed", completed.length, Colors.green),
          if (completed.isEmpty)
            _buildEmptyState("Take your first medication to see it here!")
          else
            ...completed.map((m) => _buildMedicineActionCard(context, m, theme)),
          const SizedBox(height: 24),

          // Recent Medicines Section
          if (recentMedicines.isNotEmpty) ...[
            Text(
              'Recent Additions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentMedicines.length,
                itemBuilder: (context, idx) {
                  final m = recentMedicines[idx];
                  return Card(
                    margin: const EdgeInsets.only(right: 12, bottom: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.dosage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(m.time, style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context, int up, int comp, int miss) {
    return Row(
      children: [
        _summaryItem(context, 'Upcoming', up.toString(), Colors.blue),
        const SizedBox(width: 8),
        _summaryItem(context, 'Completed', comp.toString(), Colors.green),
        const SizedBox(width: 8),
        _summaryItem(context, 'Missed', miss.toString(), Colors.red),
      ],
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title, int count, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _buildMedicineActionCard(BuildContext context, Medicine m, ThemeData theme) {
    final status = m.getDailyStatus();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Medicine Category Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: _categoryIcon(m.category),
            ),
            const SizedBox(width: 16),

            // Medicine text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${m.dosage} • ${m.quantity} • ${m.time}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (m.notes != null && m.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      m.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions Buttons
            if (status == 'taken')
              const Icon(Icons.check_circle, color: Colors.green, size: 28)
            else if (status == 'skipped')
              const Icon(Icons.cancel, color: Colors.red, size: 28)
            else ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  context.read<MedicineProvider>().markAsTaken(m);
                },
                tooltip: 'Take',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  context.read<MedicineProvider>().skipMedicine(m);
                },
                tooltip: 'Skip',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryIcon(MedicineCategory category) {
    switch (category) {
      case MedicineCategory.syrup:
        return const Icon(Icons.medication_liquid, size: 24, color: Colors.teal);
      case MedicineCategory.injection:
        return const Icon(Icons.vaccines, size: 24, color: Colors.redAccent);
      case MedicineCategory.tablets:
        return const Icon(Icons.medication, size: 24, color: Colors.indigo);
    }
  }
}

// ================= SEARCH DELEGATE =================

class MedicineSearchDelegate extends SearchDelegate {
  final List<Medicine> medicines;
  final Function(int) onEdit;
  final Function(int) onDelete;

  MedicineSearchDelegate({
    required this.medicines,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filtered = medicines
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No medicines found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, idx) {
        final m = filtered[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              m.category == MedicineCategory.syrup
                  ? Icons.medication_liquid
                  : m.category == MedicineCategory.injection
                      ? Icons.vaccines
                      : Icons.medication,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${m.dosage} • ${m.quantity} • ${m.time} • ${m.frequency}'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                close(context, null);
                // Open Medication edit
                final idxInOrig = medicines.indexOf(m);
                if (idxInOrig >= 0) {
                  onEdit(idxInOrig);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
