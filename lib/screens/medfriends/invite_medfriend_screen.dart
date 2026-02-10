import 'package:flutter/material.dart';

class InviteMedfriendScreen extends StatefulWidget {
  const InviteMedfriendScreen({super.key});

  @override
  State<InviteMedfriendScreen> createState() =>
      _InviteMedfriendScreenState();
}

class _InviteMedfriendScreenState extends State<InviteMedfriendScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool shareMeds = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Invite Medfriend'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // later: send invite
              Navigator.pop(context);
            },
            child: const Text(
              'SEND',
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
            // Blue header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).primaryColor,
              child: const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
            ),

            // Info text
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'A Medfriend is a family member or a friend that helps you remember '
                    'to take your meds in case you forget.',
                style: TextStyle(fontSize: 15),
              ),
            ),

            // Form card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // First name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Phone
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Share meds switch
            SwitchListTile(
              title: const Text('Share my meds with this Medfriend'),
              value: shareMeds,
              onChanged: (value) {
                setState(() => shareMeds = value);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
