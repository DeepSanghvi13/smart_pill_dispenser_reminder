import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/medicine.dart';

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
    return Column(
      children: [
        Expanded(
          child: medicines.isEmpty
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
                    final expiryText = med.expiryDate == null
                        ? 'No expiry date'
                        : 'Expiry: ${DateFormat.yMMMd().format(med.expiryDate!)}';

                    return Card(
                      child: ListTile(
                        leading: Text(
                          med.category.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(med.name),
                        subtitle: Text(
                          '${med.dosage} • ${med.time} • ${med.category.label}\n$expiryText',
                        ),
                        isThreeLine: true,
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
                ),
        ),
      ],
    );
  }
}
