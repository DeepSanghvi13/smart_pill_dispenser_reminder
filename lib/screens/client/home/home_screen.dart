import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/medicine.dart';
import '../../../providers/sync_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../../services/notification_service.dart';
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

  void _scheduleInAppAlarm(Medicine medicine, AlarmService alarmService) {
    final id = medicine.id;
    if (id == null) {
      return;
    }

    try {
      final time = DateFormat('h:mm a').parse(medicine.time);
      alarmService.scheduleDailyAlarm(
        medicineId: id.toString(),
        medicineName: medicine.name,
        medicineDosage: medicine.dosage,
        hour: time.hour,
        minute: time.minute,
      );
    } catch (e) {
      debugPrint('Error scheduling in-app alarm: $e');
    }
  }

  Widget _buildCurrentPage(List<Medicine> medicines) {
    switch (_currentIndex) {
      case 0:
        return HomeBody(
          medicines: medicines,
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
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<MedicineProvider>();
      provider.loadMedicines().then((_) {
        if (!mounted) return;
        final alarmService = context.read<AlarmService>();
        for (final medicine in provider.medicines) {
          _scheduleInAppAlarm(medicine, alarmService);
        }
      });
    });
  }

  // ADD
  Future<void> _addMedicine() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addMedication,
    );
    if (!mounted) return;

    if (result != null && result is Medicine) {
      final alarmService = context.read<AlarmService>();
      final messenger = ScaffoldMessenger.of(context);
      final provider = context.read<MedicineProvider>();
      
      try {
        final id = await provider.addMedicine(result);
        
        if (!mounted) return;

        if (id != null && id > 0) {
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
            payload: jsonEncode({
              'type': 'alarm',
              'id': id,
              'name': result.name,
              'dosage': result.dosage,
            }),
          );
          alarmService.scheduleDailyAlarm(
            medicineId: id.toString(),
            medicineName: result.name,
            medicineDosage: result.dosage,
            hour: time.hour,
            minute: time.minute,
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
        }
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
      final alarmService = context.read<AlarmService>();
      final messenger = ScaffoldMessenger.of(context);
      try {
        final medicineId = medicines[index].id;
        if (medicineId != null) {
          // Update in provider
          final success = await provider.updateMedicine(medicineId, result);

          if (!mounted) return;
          if (success) {
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
              payload: jsonEncode({
                'type': 'alarm',
                'id': medicineId,
                'name': result.name,
                'dosage': result.dosage,
              }),
            );
            alarmService.scheduleDailyAlarm(
              medicineId: medicineId.toString(),
              medicineName: result.name,
              medicineDosage: result.dosage,
              hour: time.hour,
              minute: time.minute,
            );
            if (result.expiryDate != null) {
              await NotificationService.scheduleExpiryNotifications(
                medicineId: _safeExpirySeed(medicineId),
                medicineName: result.name,
                expiryDate: result.expiryDate!,
              );
            }

            messenger.showSnackBar(
              const SnackBar(content: Text('Medicine updated successfully')),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating medicine: $e')),
        );
      }
    }
  }

  // DELETE
  void _deleteMedicine(int index) {
    final provider = context.read<MedicineProvider>();
    final medicines = provider.medicines;
    if (index < 0 || index >= medicines.length) return;
    
    final medicineId = medicines[index].id;
    if (medicineId == null) return;
    
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
              final alarmService = context.read<AlarmService>();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await provider.deleteMedicine(medicineId);
                
                if (!mounted) return;
                alarmService.cancelScheduledAlarm(medicineId.toString());

                messenger.showSnackBar(
                  const SnackBar(content: Text('Medicine deleted')),
                );
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
    final medicineProvider = context.watch<MedicineProvider>();
    
    if (medicineProvider.loadingMedicines) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUserEmail =
        context.watch<AuthService>().currentUser ?? 'Guest';
    final syncProvider = context.watch<SyncProvider>();
    final medicines = medicineProvider.medicines;

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
      body: _buildCurrentPage(medicines),
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
        final healthCondition = (med.healthCondition ?? '').trim();

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryIcon(med.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${med.dosage} • ${med.time} • ${med.category.label}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expiryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (healthCondition.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Use: $healthCondition',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryIcon(MedicineCategory category) {
    switch (category) {
      case MedicineCategory.syrup:
        return const Icon(Icons.medication_liquid,
            size: 28, color: Colors.teal);
      case MedicineCategory.injection:
        return const Icon(Icons.vaccines, size: 28, color: Colors.redAccent);
      case MedicineCategory.tablets:
        return const Icon(Icons.medication, size: 28, color: Colors.indigo);
    }
  }
}
