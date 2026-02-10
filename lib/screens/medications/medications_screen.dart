import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class MedicationsScreen extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMed;

  const MedicationsScreen({
    super.key,
    required this.medicines,
    required this.onAddMed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: medicines.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 120),
            const SizedBox(height: 20),
            const Text(
              'No medicines added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAddMed,
              child: const Text('Add a med'),
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
            ),
          );
        },
      ),

      // ✅ ADD A MED FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: onAddMed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
