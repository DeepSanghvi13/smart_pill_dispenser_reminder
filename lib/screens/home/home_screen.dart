import 'package:flutter/material.dart';

import '../../models/medicine.dart';
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

  // ADD
  Future<void> _addMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMedicationScreen(),
      ),
    );

    if (result != null && result is Medicine) {
      setState(() => _medicines.add(result));
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
      setState(() => _medicines[index] = result);
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
            onPressed: () {
              setState(() => _medicines.removeAt(index));
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
