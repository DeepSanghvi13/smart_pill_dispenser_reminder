import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class MedicationsScreen extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMed;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const MedicationsScreen({
    super.key,
    required this.medicines,
    required this.onAddMed,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: medicines.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.medication, size: 120),
            SizedBox(height: 20),
            Text(
              'No medicines added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
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
                  // ✏️ EDIT
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => onEdit(index),
                  ),

                  // 🗑️ DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // ➕ ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D4F8B),
        onPressed: onAddMed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
