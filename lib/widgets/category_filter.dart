import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class CategoryFilter extends StatelessWidget {
  final MedicineCategory selectedCategory;
  final Function(MedicineCategory) onCategoryChanged;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: MedicineCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(category.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => onCategoryChanged(category),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.blue.shade300,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

<<<<<<< HEAD

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
