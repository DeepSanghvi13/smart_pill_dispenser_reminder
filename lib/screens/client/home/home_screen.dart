import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/medicine.dart';
import '../../../models/user_profile.dart';
import '../../../providers/medicine_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
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
        final auth = context.read<AuthService>();
        final provider = context.read<MedicineProvider>();
        
        if (auth.isCaretaker) {
          // Initialize Caretaker active patient to first connected patient
          final patients = auth.getConnectedPatients();
          if (patients.isNotEmpty) {
            provider.setActivePatient(patients.first.email);
          } else {
            provider.setActivePatient(null);
          }
        } else {
          provider.setActivePatient(auth.currentUser);
        }
        provider.reloadAll();
      }
    });
  }

  Widget _buildCurrentPage(List<Medicine> medicines, String userName, String? profilePic, bool isCaretaker) {
    if (_currentIndex == 3) {
      return const ManageScreen();
    }
    if (_currentIndex == 1) {
      return const UpdatesScreen();
    }

    if (isCaretaker) {
      switch (_currentIndex) {
        case 0:
          return CaretakerHomeBody(
            onEdit: _editMedicine,
            onDelete: _deleteMedicine,
          );
        case 2:
          return MedicationsScreen(
            medicines: medicines,
            onAddMed: _addMedicine,
            onEdit: _editMedicine,
            onDelete: _deleteMedicine,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
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
        case 2:
          return MedicationsScreen(
            medicines: medicines,
            onAddMed: _addMedicine,
            onEdit: _editMedicine,
            onDelete: _deleteMedicine,
          );
        default:
          return const SizedBox.shrink();
      }
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
    final auth = context.watch<AuthService>();
    final isCare = auth.isCaretaker;
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines = medicineProvider.medicines;
    final currentUserEmail = auth.currentUser ?? 'Guest';

    return FutureBuilder<UserProfile?>(
      future: DatabaseService().getUserProfileData(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final userName = profile?.fullName ?? currentUserEmail.split('@').first;
        final profilePic = profile?.profilePicture;

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Text(
              _currentIndex == 0 
                  ? (isCare ? 'Caregiver Dashboard' : 'PillDispenser') 
                  : _currentIndex == 2 
                      ? 'My Medications' 
                      : 'Settings'
            ),
            actions: [
              if (_currentIndex == 0 && !isCare)
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
          body: _buildCurrentPage(medicines, userName, profilePic, isCare),
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

// ================= PATIENT HOME BODY =================

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

    final todayMedicines = medicines.where((m) {
      final start = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
      final end = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);
      return !today.isBefore(start) && !today.isAfter(end);
    }).toList();

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
        final scheduledTime = _getScheduledDateTime(m.time);
        if (scheduledTime != null && scheduledTime.isBefore(now)) {
          missed.add(m);
        } else {
          upcoming.add(m);
        }
      }
    }

    final recentMedicines = medicines.reversed.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MedicineProvider>().reloadAll();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
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

          _buildQuickSummary(context, upcoming.length, completed.length, missed.length),
          const SizedBox(height: 24),

          _buildCategoryHeader(context, "Upcoming Medicines", upcoming.length, Colors.blue),
          if (upcoming.isEmpty)
            _buildEmptyState("No upcoming medications left for today.")
          else
            ...upcoming.map((m) => _buildMedicineActionCard(context, m, theme)),
          const SizedBox(height: 20),

          _buildCategoryHeader(context, "Missed / Skipped", missed.length, Colors.red),
          if (missed.isEmpty)
            _buildEmptyState("No missed medications today. Good job!")
          else
            ...missed.map((m) => _buildMedicineActionCard(context, m, theme)),
          const SizedBox(height: 20),

          _buildCategoryHeader(context, "Completed", completed.length, Colors.green),
          if (completed.isEmpty)
            _buildEmptyState("Take your first medication to see it here!")
          else
            ...completed.map((m) => _buildMedicineActionCard(context, m, theme)),
          const SizedBox(height: 24),

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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: _categoryIcon(m.category),
            ),
            const SizedBox(width: 16),

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

// ================= CARETAKER HOME BODY =================

class CaretakerHomeBody extends StatefulWidget {
  final Function(int) onEdit;
  final Function(int) onDelete;

  const CaretakerHomeBody({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CaretakerHomeBody> createState() => _CaretakerHomeBodyState();
}

class _CaretakerHomeBodyState extends State<CaretakerHomeBody> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddPatientDialog(BuildContext context, AuthService auth, MedicineProvider provider) {
    int methodIndex = 0; // 0 = SDP Code, 1 = Email & Phone

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Connected Patient'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('SDP Code'), icon: Icon(Icons.qr_code)),
                        ButtonSegment(value: 1, label: Text('Email & Phone'), icon: Icon(Icons.email_outlined)),
                      ],
                      selected: {methodIndex},
                      onSelectionChanged: (val) {
                        setDialogState(() {
                          methodIndex = val.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (methodIndex == 0) ...[
                      const Text(
                        'Enter the patient unique connection code (e.g. SPD-482915) to connect.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Patient Connection Code',
                          hintText: 'SPD-XXXXXX',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Enter the patient registered email and phone number to connect.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Patient Registered Email',
                          hintText: 'patient@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Patient Phone Number',
                          hintText: 'Enter phone or emergency contact',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _codeController.clear();
                    _emailController.clear();
                    _phoneController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? error;
                    if (methodIndex == 0) {
                      final code = _codeController.text.trim();
                      error = await auth.connectPatient(code);
                    } else {
                      final email = _emailController.text.trim();
                      final phone = _phoneController.text.trim();
                      error = await auth.connectPatient(email, phone);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      _codeController.clear();
                      _emailController.clear();
                      _phoneController.clear();
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: Colors.red),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully connected to patient!'), backgroundColor: Colors.green),
                        );
                        // Update active patient
                        final list = auth.getConnectedPatients();
                        if (list.isNotEmpty) {
                          provider.setActivePatient(list.last.email);
                        }
                      }
                    }
                  },
                  child: const Text('Connect'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getMedicineStatus(Medicine med) {
    final dailyStatus = med.getDailyStatus();
    if (dailyStatus == 'taken') return 'Taken';
    if (dailyStatus == 'skipped') return 'Skipped';

    // Parse time
    final clean = med.time.trim();
    final formats = [
      DateFormat('h:mm a'),
      DateFormat('hh:mm a'),
      DateFormat('H:mm'),
      DateFormat('HH:mm'),
    ];
    DateTime? parsedTime;
    for (final format in formats) {
      try {
        parsedTime = format.parse(clean);
        break;
      } catch (_) {}
    }
    if (parsedTime == null) return 'Upcoming';

    final now = DateTime.now();
    final medTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    final diff = now.difference(medTime).inMinutes;

    if (diff < 0) {
      return 'Upcoming';
    } else if (diff < 30) {
      return 'Delayed';
    } else {
      return 'Missed';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Taken':
        return Colors.green;
      case 'Upcoming':
        return Colors.blue;
      case 'Delayed':
        return Colors.orange;
      case 'Missed':
      case 'Skipped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Taken':
        return Icons.check_circle_outline;
      case 'Upcoming':
        return Icons.alarm_outlined;
      case 'Delayed':
        return Icons.pending_actions_outlined;
      case 'Missed':
      case 'Skipped':
        return Icons.highlight_off_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final provider = context.watch<MedicineProvider>();
    final connectedPatients = auth.getConnectedPatients();
    final activePatientEmail = provider.activePatientId;

    UserProfile? activePatient;
    if (activePatientEmail != null) {
      try {
        activePatient = connectedPatients.firstWhere((p) => p.email == activePatientEmail);
      } catch (_) {}
    }

    final notifications = HiveService()
        .notificationsBox
        .values
        .where((n) => activePatientEmail == null || n['patientId'] == activePatientEmail)
        .toList()
        .reversed
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayMedicines = provider.medicines.where((m) {
      final start = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
      final end = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);
      return !today.isBefore(start) && !today.isAfter(end);
    }).toList();

    final completed = <Medicine>[];
    final upcoming = <Medicine>[];
    final missed = <Medicine>[];

    for (final m in todayMedicines) {
      final status = _getMedicineStatus(m);
      if (status == 'Taken') {
        completed.add(m);
      } else if (status == 'Upcoming') {
        upcoming.add(m);
      } else {
        missed.add(m);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.reloadAll();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Connected Patients horizontal header selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monitored Patients',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Patient'),
                onPressed: () => _showAddPatientDialog(context, auth, provider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (connectedPatients.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'No Patients Connected Yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask your family member for their connection code (e.g. SPD-482915) to connect and manage their pill logs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Connect Patient'),
                      onPressed: () => _showAddPatientDialog(context, auth, provider),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: connectedPatients.length,
                itemBuilder: (context, idx) {
                  final patient = connectedPatients[idx];
                  final isSelected = patient.email == activePatientEmail;
                  return GestureDetector(
                    onTap: () {
                      provider.setActivePatient(patient.email);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withOpacity(0.1),
                            child: CircleAvatar(
                              radius: 27,
                              backgroundColor: Colors.white,
                              backgroundImage: patient.profilePicture != null && patient.profilePicture!.isNotEmpty
                                  ? FileImage(File(patient.profilePicture!))
                                  : null,
                              child: patient.profilePicture == null
                                  ? Icon(Icons.person, color: theme.colorScheme.primary)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patient.fullName.split(' ').first,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          if (activePatient != null) ...[
            // Patient details banner
            Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: activePatient.profilePicture != null && activePatient.profilePicture!.isNotEmpty
                          ? FileImage(File(activePatient.profilePicture!))
                          : null,
                      child: activePatient.profilePicture == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activePatient.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Age: ${activePatient.age ?? 'N/A'} • Blood: ${activePatient.bloodGroup ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (activePatient.medicalConditions != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Conditions: ${activePatient.medicalConditions}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {
                        // View patient profile dialog
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Patient Medical Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${activePatient!.fullName}'),
                                const SizedBox(height: 8),
                                Text('Age: ${activePatient.age ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                Text('Gender: ${activePatient.gender ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                Text('Blood Group: ${activePatient.bloodGroup ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                Text('Weight: ${activePatient.weight ?? 'N/A'} kg'),
                                const SizedBox(height: 8),
                                Text('Height: ${activePatient.height ?? 'N/A'} cm'),
                                const SizedBox(height: 8),
                                Text('Emergency Contact: ${activePatient.emergencyContact ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                Text('Medical Conditions: ${activePatient.medicalConditions ?? 'None'}'),
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
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today schedule status
            Text(
              "Today's Medication Tracker",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (todayMedicines.isEmpty)
              _buildEmptyState("No medicines scheduled for this patient today.")
            else
              ...todayMedicines.map((m) {
                final status = _getMedicineStatus(m);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.1),
                      child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                    ),
                    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${m.dosage} • ${m.time}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        ),
                      ),
                    ),
                    onTap: () {
                      // Allow editing/deleting patient medication
                      final idx = provider.medicines.indexOf(m);
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const SizedBox(height: 24),
                              ListTile(
                                leading: const Icon(Icons.edit, color: Colors.blue),
                                title: const Text('Edit Medication'),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onEdit(idx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Delete Medication'),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onDelete(idx);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],

          // Missed & Alerts Log
          Text(
            'Caregiver Alerts Log',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            _buildEmptyState("No caregiver alerts logged.")
          else
            ...notifications.take(5).map((n) {
              final isAnn = n['type'] == 'announcement';
              return Card(
                color: isAnn ? Colors.indigo.shade50.withOpacity(0.4) : Colors.red.shade50.withOpacity(0.4),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isAnn ? Colors.indigo.shade100 : Colors.red.shade100),
                ),
                child: ListTile(
                  leading: isAnn
                      ? const Icon(Icons.campaign, color: Colors.indigo)
                      : const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  title: Text(
                    isAnn
                        ? '${n['title']}'
                        : '${n['patientName']} missed ${n['medicineName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    isAnn
                        ? '${n['body']}'
                        : 'Scheduled for ${n['scheduledTime']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: () async {
                      final notifId = n['notificationId'] as String;
                      await HiveService().notificationsBox.delete(notifId);
                      setState(() {});
                    },
                    tooltip: 'Dismiss alert',
                  ),
                ),
              );
            }),
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
