import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  TimeOfDay? selectedTime;

  // ✅ OPEN CLOCK
  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
        timeController.text = time.format(context); // e.g. 8:30 AM
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a med')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Medicine Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter medicine name' : null,
              ),
              const SizedBox(height: 16),

              // Dosage
              TextFormField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g. 1 tablet)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter dosage' : null,
              ),
              const SizedBox(height: 16),

              // ✅ TIME PICKER FIELD
              TextFormField(
                controller: timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'Select time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (v) =>
                v!.isEmpty ? 'Select medicine time' : null,
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final medicine = Medicine(
                        name: nameController.text,
                        dosage: dosageController.text,
                        time: timeController.text,
                      );

                      Navigator.pop(context, medicine);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
