import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isSending = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || (phone.isEmpty && email.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and at least phone or email')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final message = shareMeds
          ? 'Hi $name, I\'m using Smart Pill Dispenser Reminder app to manage my medications. '
            'I\'d like you to be my Medfriend and get notifications if I miss my medicines. '
            'Please download the app and I\'ll add you as my Medfriend.'
          : 'Hi $name, I\'m inviting you to be my Medfriend on the Smart Pill Dispenser Reminder app. '
            'You\'ll help me remember to take my medications.';

      bool sentAny = false;

      // Send SMS
      if (phone.isNotEmpty) {
        final smsUri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: {'body': message},
        );
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          sentAny = true;
        }
      }

      // Send Email
      if (email.isNotEmpty) {
        final emailUri = Uri(
          scheme: 'mailto',
          path: email,
          queryParameters: {
            'subject': 'Join me as a Medfriend on Smart Pill Dispenser Reminder',
            'body': message,
          },
        );
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          sentAny = true;
        }
      }

      if (!mounted) return;
      setState(() => _isSending = false);

      if (sentAny) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invite sent successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send invite. Try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
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
        title: const Text('Invite Medfriend'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
              onPressed: _isSending ? null : _sendInvite,
            child: Text(
              'SEND',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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
              activeThumbColor: Theme.of(context).primaryColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendInvite,
                  icon: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Invite Friend'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



