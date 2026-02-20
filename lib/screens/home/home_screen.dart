import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/medicine.dart';
import '../../services/notification_service.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';

import '../medications/add_medication_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  /// Load medicines from database
  Future<void> _loadMedicines() async {
    try {
      final medicines = await _dbService.getAllMedicines();
      setState(() {
        _medicines.clear();
        _medicines.addAll(medicines);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medicines: $e');
      setState(() => _isLoading = false);
    }
  }

  // ADD
  Future<void> _addMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMedicationScreen(),
      ),
    );

    if (result != null && result is Medicine) {
      try {
        // Save to database
        final id = await _dbService.addMedicine(result);
        final newMedicine = result.copyWith(id: id);

        setState(() => _medicines.add(newMedicine));

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
        await NotificationService.scheduleAlarmNotification(dateTime: dateTime);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding medicine: $e')),
        );
      }
    }
  }

  // EDIT
  Future<void> _editMedicine(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(
          medicine: _medicines[index],
        ),
      ),
    );

    if (result != null && result is Medicine) {
      try {
        final medicineId = _medicines[index].id;
        if (medicineId != null) {
          // Update in database
          await _dbService.updateMedicine(medicineId, result);

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

          await NotificationService.scheduleAlarmNotification(dateTime: dateTime);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine updated successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating medicine: $e')),
        );
      }
    }
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
              try {
                final medicineId = _medicines[index].id;
                if (medicineId != null) {
                  await _dbService.deleteMedicine(medicineId);
                  setState(() => _medicines.removeAt(index));

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine deleted')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting medicine: $e')),
                );
              }
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

    final pages = [
      HomeBody(
        medicines: _medicines,
        onEdit: _editMedicine,
        onDelete: _deleteMedicine,
      ),
      const UpdatesScreen(),
      MedicationsScreen(
        medicines: _medicines,
        onAddMed: _addMedicine,
        onEdit: _editMedicine,
        onDelete: _deleteMedicine,
      ),
      const ManageScreen(),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Guest')),
      body: pages[_currentIndex],
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

        return Card(
          child: ListTile(
            leading: const Icon(Icons.medication),
            title: Text(med.name),
            subtitle: Text('${med.dosage} • ${med.time}'),
            trailing: Row(
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
          ),
        );
      },
    );
  }
}
