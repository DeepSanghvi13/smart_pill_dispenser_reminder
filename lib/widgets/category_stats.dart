import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class CategoryStats extends StatelessWidget {
  final List<Medicine> medicines;

  const CategoryStats({
    super.key,
    required this.medicines,
  });

  int countByCategory(MedicineCategory category) {
    return medicines.where((med) => med.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicine Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: MedicineCategory.values.map((category) {
              final count = countByCategory(category);
              return Column(
                children: [
                  Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


