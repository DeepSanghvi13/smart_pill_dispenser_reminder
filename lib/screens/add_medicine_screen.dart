import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

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

    nameController = TextEditingController(text: widget.medicine?.name ?? '');
    dosageController =
        TextEditingController(text: widget.medicine?.dosage ?? '');

    if (widget.medicine != null) {
      final parts = widget.medicine!.time.split(':');
      final hour = int.parse(parts[0]);
      final minutePart = parts[1].split(' ')[0];
      final minute = int.parse(minutePart);
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

  Future<void> saveMedicine() async {
    if (nameController.text.isEmpty ||
        dosageController.text.isEmpty ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final medicine = Medicine(
      name: nameController.text,
      dosage: dosageController.text,
      time: selectedTime!.format(context),
    );

    try {
      /// ⭐ 1. SAVE INTO SQLITE DATABASE
      await DatabaseService().insertMedicine(
        name: medicine.name,
        dosage: medicine.dosage,
        time: medicine.time,
      );

      /// ⭐ 2. SCHEDULE NOTIFICATION
      if (Platform.isAndroid) {
        final notificationId = medicine.name.hashCode;

        await NotificationService.scheduleDailyNotification(
          id: notificationId,
          title: 'Medicine Reminder 💊',
          body: 'Time to take ${medicine.name} - ${medicine.dosage}',
          hour: selectedTime!.hour,
          minute: selectedTime!.minute,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Medicine saved & reminder set for ${selectedTime!.format(context)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, medicine);
    } catch (e) {
      print("Save error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medicine: $e'),
          backgroundColor: Colors.orange,
        ),
      );
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
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 1 tablet, 5ml)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_pharmacy),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: pickTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        selectedTime == null
                            ? 'Select time for reminder'
                            : 'Reminder at: ${selectedTime!.format(context)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// ⭐ SAVE BUTTON
            ElevatedButton.icon(
              onPressed: saveMedicine,
              icon: const Icon(Icons.save),
              label: const Text('Save Medicine'),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () async {
                await NotificationService.showImmediateNotification(
                  id: 999,
                  title: 'Test Notification',
                  body: 'Notifications are working! 🎉',
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Notification Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    super.dispose();
  }
}
