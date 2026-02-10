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

  String gender = '';
  DateTime? birthDate;
  Color selectedColor = Colors.blue;

  // Birth date picker
  Future<void> _pickBirthDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
        title: const Text('Create Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // later: save profile
              Navigator.pop(context);
            },
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header description
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

            // Avatar
            const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 42, color: Colors.white),
            ),

            const SizedBox(height: 20),

            // Form Card
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                        final value =
                        await showModalBottomSheet<String>(
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
                      leading:
                      CircleAvatar(backgroundColor: selectedColor),
                      onTap: () {
                        setState(() {
                          selectedColor = selectedColor == Colors.blue
                              ? Colors.pink
                              : Colors.blue;
                        });
                      },
                    ),

                    const Divider(),

                    // Zip code
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

            // Terms text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'By clicking the "Save" button, you consent to the association '
                    'of your personal information with your health information and '
                    'confirm you have read and agreed to our Terms and Privacy Policy.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gender picker sheet
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
}
