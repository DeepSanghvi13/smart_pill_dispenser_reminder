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
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication,
                        size: 100,
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No medicines added yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the "+" button below or on home to add one.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
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
                        ? 'Continuous therapy'
                        : 'Until: ${DateFormat.yMMMd().format(med.expiryDate!)}';

                    // Color based on category type
                    Color categoryColor;
                    IconData categoryIcon;
                    switch (med.category) {
                      case MedicineCategory.tablets:
                        categoryColor = Colors.indigo;
                        categoryIcon = Icons.medication;
                        break;
                      case MedicineCategory.syrup:
                        categoryColor = Colors.teal;
                        categoryIcon = Icons.medication_liquid;
                        break;
                      case MedicineCategory.injection:
                        categoryColor = Colors.redAccent;
                        categoryIcon = Icons.vaccines;
                        break;
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Icon Backplate
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                categoryIcon,
                                color: categoryColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Medicine Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // Detail chips
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildMiniChip(
                                        context,
                                        Icons.opacity,
                                        med.dosage,
                                        theme.colorScheme.primary,
                                      ),
                                      _buildMiniChip(
                                        context,
                                        Icons.access_time,
                                        med.time,
                                        Colors.purple,
                                      ),
                                      _buildMiniChip(
                                        context,
                                        Icons.calendar_today,
                                        expiryText,
                                        Colors.brown,
                                      ),
                                    ],
                                  ),
                                  
                                  if (med.notes != null && med.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Note: ${med.notes}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Actions
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  color: Colors.blue.shade700,
                                  onPressed: () => onEdit(index),
                                  tooltip: 'Edit medicine',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red.shade700,
                                  onPressed: () {
                                    _showDeleteConfirm(context, med.name, () => onDelete(index));
                                  },
                                  tooltip: 'Delete medicine',
                                ),
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
    );
  }

  Widget _buildMiniChip(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? color.withOpacity(0.9) : color.darken(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String medName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete "$medName"? This will also cancel all future reminders for it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Helper extension to darken colors for text visibility
extension on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
