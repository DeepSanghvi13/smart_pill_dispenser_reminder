import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  void _copyEmail(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(text: 'support@medisafe.com'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support email copied to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'If you are facing issues with reminders, medicines, '
                  'or account settings, contact our support team.',
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => _copyEmail(context),
              icon: const Icon(Icons.email),
              label: const Text('Copy Support Email'),
            ),
          ],
        ),
      ),
    );
  }
}
