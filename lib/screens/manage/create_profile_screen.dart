import 'package:flutter/material.dart';

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
            onPressed: () {
              Navigator.pop(context); // Save logic can be added later
            },
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white),
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
}
