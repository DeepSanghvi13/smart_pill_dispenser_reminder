import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Medicine> medicines = [];

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('medicines');

    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        medicines.clear();
        medicines.addAll(
          decoded.map((e) => Medicine.fromJson(e)).toList(),
        );
      });
    }
  }

  Future<void> saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
    jsonEncode(medicines.map((e) => e.toJson()).toList());
    await prefs.setString('medicines', encoded);
  }

  void deleteMedicine(int index) {
    setState(() {
      medicines.removeAt(index);
    });
    saveMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Pill Reminder'),
        centerTitle: true,
      ),
      body: medicines.isEmpty
          ? const Center(
        child: Text(
          'No medicines added yet',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          return MedicineCard(
            medicine: medicines[index],
            onDelete: () => deleteMedicine(index),
            onEdit: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMedicineScreen(
                    medicine: medicines[index],
                  ),
                ),
              );

              if (updated != null) {
                setState(() {
                  medicines[index] = updated;
                });
                saveMedicines();
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
            ),
          );

          if (result != null) {
            setState(() {
              medicines.add(result);
            });
            saveMedicines();
          }
        },
        child: const Icon(Icons.add), // ✅ FIXED ICON
      ),
    );
  }
}
