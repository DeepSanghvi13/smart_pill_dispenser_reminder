import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/models/user_profile.dart';
import 'package:smart_pill_reminder/services/database_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  String gender = '';
  DateTime? birthDate;
  Color selectedColor = Colors.blue;
  bool _isSaving = false;

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final zipCode = zipController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter first and last name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = UserProfile(
        firstName: firstName,
        lastName: lastName,
        gender: gender.isEmpty ? 'Not specified' : gender,
        birthDate: birthDate?.toIso8601String() ?? '',
        zipCode: zipCode,
        phoneNumber: '',
        email: '',
      );

      await _dbService.saveUserProfile(profile);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile saved successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Create Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: const Text(
                'Adding your details allows us to make the app more personal.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last name'),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gender'),
                      subtitle: Text(gender.isEmpty ? 'Select' : gender),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final value = await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) => Column(
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
                          ),
                        );
                        if (value != null) setState(() => gender = value);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Birth date'),
                      subtitle: Text(
                        birthDate == null ? 'Select' : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickBirthDate,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Color'),
                      leading: CircleAvatar(backgroundColor: selectedColor),
                      onTap: () {
                        setState(() {
                          selectedColor = selectedColor == Colors.blue ? Colors.pink : Colors.blue;
                        });
                      },
                    ),
                    const Divider(),
                    TextField(
                      controller: zipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Zip code',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'By clicking Save, you consent to association of personal and health information.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

