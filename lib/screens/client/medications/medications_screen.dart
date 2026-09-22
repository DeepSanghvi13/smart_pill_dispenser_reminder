import 'package:flutter/material.dart';
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No medicines added yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the "+" button below or on home to add one.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                    final expiryText = 'Expiry: ${med.formattedExpiryDate}';

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

                    // Expiry status attributes
                    Color statusColor;
                    String statusLabel;
                    IconData statusIcon;
                    if (med.isExpired) {
                      statusColor = Colors.red;
                      statusLabel = 'Expired';
                      statusIcon = Icons.error_outline;
                    } else if (med.isExpiringSoon) {
                      statusColor = Colors.orange;
                      statusLabel = 'Expiring Soon';
                      statusIcon = Icons.warning_amber_rounded;
                    } else {
                      statusColor = Colors.green;
                      statusLabel = 'Active';
                      statusIcon = Icons.check_circle_outline;
                    }

                    final isExpiredCard = med.isExpired;

                    return Card(
                      elevation: isExpiredCard ? 3 : 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isExpiredCard
                          ? Colors.red.withValues(alpha: 0.04)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: isExpiredCard
                            ? BorderSide(color: Colors.red.shade300, width: 1.5)
                            : (med.isExpiringSoon
                                ? BorderSide(color: Colors.orange.shade300, width: 1.2)
                                : BorderSide.none),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isExpiredCard)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Expired on ${med.formattedExpiryDate}. Do not consume!',
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Icon Backplate
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.12),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              med.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isExpiredCard ? Colors.red.shade900 : null,
                                              ),
                                            ),
                                          ),
                                          // Expiry status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(statusIcon, size: 12, color: statusColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                                            statusColor,
                                          ),
                                        ],
                                      ),

                                      if (med.notes != null && med.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Note: ${med.notes}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      if (med.sideEffects != null && med.sideEffects!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Side Effects: ${med.sideEffects}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade400,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      if (med.storageInstructions != null && med.storageInstructions!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Storage: ${med.storageInstructions}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade400,
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
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
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
              color: isDark ? color.withValues(alpha: 0.9) : color.darken(),
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
