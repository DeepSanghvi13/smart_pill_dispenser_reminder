import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/services/database_service.dart';

class AddDependentScreen extends StatefulWidget {
  const AddDependentScreen({super.key});

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  String gender = '';
  DateTime? birthDate;
  Color selectedColor = Colors.blue;
  bool _isSaving = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  // Date picker
  Future<void> _pickBirthDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        birthDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Add Dependent'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDependent,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: const Text(
                'Manage meds for your family members',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Avatar
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.child_care, size: 40, color: Colors.white),
            ),

            const SizedBox(height: 20),

            // Form card
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // First name
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Last name
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gender
                    ListTile(
                      title: const Text('Gender'),
                      subtitle: Text(gender.isEmpty ? 'Gender' : gender),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final value = await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) => _genderSheet(),
                        );
                        if (value != null) {
                          setState(() => gender = value);
                        }
                      },
                    ),

                    const Divider(),

                    // Birth date
                    ListTile(
                      title: const Text('Birth date'),
                      subtitle: Text(
                        birthDate == null
                            ? 'Birth date'
                            : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickBirthDate,
                    ),

                    const Divider(),

                    // Default color
                    ListTile(
                      title: const Text('Default color'),
                      leading: CircleAvatar(backgroundColor: selectedColor),
                      onTap: () {
                        setState(() {
                          selectedColor = selectedColor == Colors.blue
                              ? Colors.pink
                              : Colors.blue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Terms text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'By clicking the "Done" button, you confirm that you received the consent of the dependent (when applicable) to the association of the dependent’s personal information with their health information and confirm you have read and agreed to our Terms and Privacy Policy.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDependent,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Dependent'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gender bottom sheet
  Widget _genderSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text('Male'),
          onTap: () => Navigator.pop(context, 'Male'),
        ),
        ListTile(
          title: const Text('Female'),
          onTap: () => Navigator.pop(context, 'Female'),
        ),
        ListTile(
          title: const Text('Other'),
          onTap: () => Navigator.pop(context, 'Other'),
        ),
      ],
    );
  }

  Future<void> _saveDependent() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First name and last name are required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final id = await DatabaseService().addDependent(
        firstName: firstName,
        lastName: lastName,
        gender: gender.isEmpty ? null : gender,
        birthDate: birthDate?.toIso8601String(),
        color: selectedColor.value.toRadixString(16),
      );

      if (!mounted) return;
      if (id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dependent saved successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save dependent')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving dependent: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}



