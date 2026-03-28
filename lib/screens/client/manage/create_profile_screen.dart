import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pill_reminder/models/user_profile.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';
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

  String gender = 'Gender';
  DateTime? birthDate;
  bool _isSaving = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Adding your details allows us to make the app more personal.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Avatar
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),

            _inputField(
              icon: Icons.person,
              hint: 'First name',
              controller: firstNameController,
            ),
            _inputField(
              icon: Icons.person_outline,
              hint: 'Last name',
              controller: lastNameController,
            ),

            ListTile(
              title: Text(gender),
              leading: const Icon(Icons.wc),
              onTap: () {
                setState(() {
                  gender = gender == 'Gender' ? 'Male' : 'Gender';
                });
              },
            ),

            ListTile(
              title: Text(
                birthDate == null
                    ? 'Birth date'
                    : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
              ),
              leading: const Icon(Icons.cake),
              onTap: _pickBirthDate,
            ),

            _inputField(
              icon: Icons.location_city,
              hint: 'Zip code',
              controller: zipController,
            ),

            const SizedBox(height: 20),
            const Text(
              'By clicking the "Save" button, you consent to the association of '
                  'your personal information with your health information.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
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
      final email = context.read<AuthService>().currentUser;
      final result = await DatabaseService().saveUserProfile(
        UserProfile(
          firstName: firstName,
          lastName: lastName,
          gender: gender == 'Gender' ? null : gender,
          birthDate: birthDate?.toIso8601String(),
          zipCode: zipController.text.trim().isEmpty
              ? null
              : zipController.text.trim(),
          email: email,
        ),
      );

      if (!mounted) return;
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}



