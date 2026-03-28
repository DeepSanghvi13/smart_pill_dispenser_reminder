import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/medicine.dart';
import '../../../providers/sync_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/database_service.dart';
import '../../../services/alarm_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/bottom_nav.dart';
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
  final List<Medicine> _medicines = [];
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = true;

  static const int _maxInt32 = 2147483647;
  static const int _expiryBaseOffset = 100000;
  static const int _expiryMultiplier = 10;

  int _safeAlarmNotificationId(int medicineId) {
    const int base = 1000;
    return base + (medicineId.abs() % (_maxInt32 - base));
  }

  int _safeExpirySeed(int medicineId) {
    final maxSeed = (_maxInt32 - _expiryBaseOffset - 1) ~/ _expiryMultiplier;
    return medicineId.abs() % maxSeed;
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeBody(
          medicines: _medicines,
          onEdit: _editMedicine,
          onDelete: _deleteMedicine,
        );
      case 1:
        return const UpdatesScreen();
      case 2:
        return MedicationsScreen(
          medicines: _medicines,
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

  Future<void> _retryPendingSync() async {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser;
    if (userId == null || userId.isEmpty) return;

    final sync = context.read<SyncProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await sync.retryPendingSync(userId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pending sync completed successfully.'
              : 'Sync still pending. Check connection and retry.',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  /// Load medicines from database
  Future<void> _loadMedicines() async {
    try {
      final medicines = await _dbService.getAllMedicines();
      if (!mounted) return;
      setState(() {
        _medicines.clear();
        _medicines.addAll(medicines);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading medicines: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ADD
  Future<void> _addMedicine() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addMedication,
    );
    if (!mounted) return;

    if (result != null && result is Medicine) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        // Persist to MongoDB API first.
        final id = await _dbService.addMedicine(result);
        await _loadMedicines();
        if (!mounted) return;

        // Schedule notification
        final time = DateFormat('h:mm a').parse(result.time);
        final now = DateTime.now();
        final dateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        await NotificationService.scheduleAlarmNotification(
          id: _safeAlarmNotificationId(id),
          title: 'Medication Reminder',
          body: 'Time to take ${result.name} (${result.dosage})',
          dateTime: dateTime,
        );
        if (result.expiryDate != null) {
          await NotificationService.scheduleExpiryNotifications(
            medicineId: _safeExpirySeed(id),
            medicineName: result.name,
            expiryDate: result.expiryDate!,
          );
        }

        if (!mounted) return;
        // Show success message
        messenger.showSnackBar(
          const SnackBar(content: Text('Medicine added successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Error adding medicine: $e')),
        );
      }
    }
  }

  // EDIT
  Future<void> _editMedicine(int index) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addMedication,
      arguments: _medicines[index],
    );
    if (!mounted) return;

    if (result != null && result is Medicine) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final medicineId = _medicines[index].id;
        if (medicineId != null) {
          // Update in database
          await _dbService.updateMedicine(medicineId, result);

          if (!mounted) return;
          setState(() => _medicines[index] = result.copyWith(id: medicineId));

          // Schedule notification
          final time = DateFormat('h:mm a').parse(result.time);
          final now = DateTime.now();
          final dateTime = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );

          await NotificationService.scheduleAlarmNotification(
            id: _safeAlarmNotificationId(medicineId),
            title: 'Medication Reminder',
            body: 'Time to take ${result.name} (${result.dosage})',
            dateTime: dateTime,
          );
          if (result.expiryDate != null) {
            await NotificationService.scheduleExpiryNotifications(
              medicineId: _safeExpirySeed(medicineId),
              medicineName: result.name,
              expiryDate: result.expiryDate!,
            );
          }

          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Medicine updated successfully')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating medicine: $e')),
        );
      }
    }
  }

  void _openExpiryCalendar() {
    Navigator.pushNamed(
      context,
      AppRoutes.expiryCalendar,
      arguments: _medicines,
    );
  }

  // DELETE
  void _deleteMedicine(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final medicineId = _medicines[index].id;
                if (medicineId != null) {
                  await _dbService.deleteMedicine(medicineId);
                  if (!mounted) return;
                  setState(() => _medicines.removeAt(index));

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Medicine deleted')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Error deleting medicine: $e')),
                );
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUserEmail =
        context.watch<AuthService>().currentUser ?? 'Guest';
    final syncProvider = context.watch<SyncProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(currentUserEmail),
        actions: [
          if (syncProvider.hasPendingSync || syncProvider.isSyncing)
            IconButton(
              tooltip: syncProvider.isSyncing
                  ? 'Sync in progress'
                  : 'Retry pending sync',
              onPressed: syncProvider.isSyncing ? null : _retryPendingSync,
              icon: syncProvider.isSyncing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_problem),
            ),
        ],
      ),
      body: _buildCurrentPage(),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 2)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0D4F8B),
              onPressed: _addMedicine,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNav(
        index: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/* ...existing code... */

/* ---------------- HOME BODY ---------------- */

class HomeBody extends StatelessWidget {
  final List<Medicine> medicines;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const HomeBody({
    super.key,
    required this.medicines,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) {
      return const Center(
        child: Text('No medicines added'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final med = medicines[index];
        final expiryText = med.expiryDate == null
            ? 'No expiry'
            : 'Expiry ${DateFormat.yMMMd().format(med.expiryDate!)}';

        return Card(
          child: ListTile(
            leading: Text(
              med.category.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            title: Text(med.name),
            subtitle: Text(
                '${med.dosage} • ${med.time} • ${med.category.label} • $expiryText'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Test Alarm Button
                IconButton(
                  icon: const Icon(Icons.alarm, color: Colors.orange),
                  tooltip: 'Test alarm',
                  onPressed: () {
                    final alarmService = Provider.of<AlarmService>(
                      context,
                      listen: false,
                    );
                    // Trigger alarm
                    alarmService.triggerAlarm(
                      medicineId: med.id?.toString() ?? '',
                      medicineName: med.name,
                      medicineDosage: med.dosage,
                    );
                    // Show notification
                    NotificationService.showImmediateAlarm(
                      medicineName: med.name,
                      medicineDosage: med.dosage,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
