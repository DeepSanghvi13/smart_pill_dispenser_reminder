import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medicine? medicine; // null = add, not null = edit

  const AddMedicationScreen({super.key, this.medicine});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController dosageController;
  late TextEditingController timeController;
  late MedicineCategory selectedCategory;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.medicine?.name ?? '');
    dosageController =
        TextEditingController(text: widget.medicine?.dosage ?? '');
    timeController =
        TextEditingController(text: widget.medicine?.time ?? '');
    selectedCategory = widget.medicine?.category ?? MedicineCategory.tablets;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        timeController.text = time.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine == null ? 'Add a med' : 'Edit med'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<MedicineCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Medicine Category',
                  border: OutlineInputBorder(),
                ),
                items: MedicineCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        Medicine(
                          name: nameController.text,
                          dosage: dosageController.text,
                          time: timeController.text,
                          category: selectedCategory,
                        ),
                      );
                    }
                  },
                  child: Text(
                    widget.medicine == null ? 'Save' : 'Update',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
