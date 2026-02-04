import 'package:flutter/material.dart';
import '../models/medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine; // null = add, not null = edit

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  late TextEditingController nameController;
  late TextEditingController dosageController;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.medicine?.name ?? '');
    dosageController =
        TextEditingController(text: widget.medicine?.dosage ?? '');

    if (widget.medicine != null) {
      final parts = widget.medicine!.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]);
      selectedTime = TimeOfDay(hour: hour, minute: minute);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.medicine == null ? 'Add Medicine' : 'Edit Medicine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g. 1 pill)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTime == null
                        ? 'No time selected'
                        : 'Time: ${selectedTime!.format(context)}',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: pickTime,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    dosageController.text.isEmpty ||
                    selectedTime == null) return;

                final updated = Medicine(
                  name: nameController.text,
                  dosage: dosageController.text,
                  time: selectedTime!.format(context),
                );

                Navigator.pop(context, updated);
              },
              child: Text(widget.medicine == null ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
