import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {

  final Medicine? medicine;

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() =>
      _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final timeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.medicine != null) {
      nameController.text = widget.medicine!.name;
      dosageController.text = widget.medicine!.dosage;
      timeController.text = widget.medicine!.time;
    }
  }

  Future<void> save() async {

    if (widget.medicine != null) {
      await NotificationService.cancelNotification(
          widget.medicine!.notificationId);
    }

    Medicine med = Medicine(
      id: widget.medicine?.id ??
          DateTime.now().millisecondsSinceEpoch,
      name: nameController.text,
      dosage: dosageController.text,
      time: timeController.text,
    );

    int newId =
    await NotificationService.scheduleNotification(med);

    med.notificationId = newId;

    if (widget.medicine == null) {
      await DatabaseService().insertMedicine(med);
    } else {
      await DatabaseService().updateMedicine(med);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicine == null
              ? "Add Medicine"
              : "Edit Medicine",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,

              children: [

                const Text(
                  "Medicine Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Medicine Name",
                    prefixIcon:
                    const Icon(Icons.medication),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: "Dosage",
                    prefixIcon:
                    const Icon(Icons.local_hospital),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: "Reminder Time",
                    prefixIcon:
                    const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Medicine"),
                  style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
