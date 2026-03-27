import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/medicine.dart';

class MedicationsScreen extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMed;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final VoidCallback onOpenExpiryCalendar;

  const MedicationsScreen({
    super.key,
    required this.medicines,
    required this.onAddMed,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenExpiryCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Expiry notifications calendar'),
            trailing: TextButton(
              onPressed: onOpenExpiryCalendar,
              child: const Text('Open'),
            ),
          ),
          const Divider(height: 1),
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
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D4F8B),
        onPressed: onAddMed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}



