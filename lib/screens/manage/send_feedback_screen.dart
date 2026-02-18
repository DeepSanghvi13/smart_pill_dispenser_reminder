import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General Feedback';

  final List<String> _categories = [
    'General Feedback',
    'Bug Report',
    'Feature Request',
    'Performance Issue',
    'User Experience',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.mail,
                    size: 64,
                    color: Color(0xFF0D4F8B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Send Feedback',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help us improve Medisafe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Category Dropdown
            const Text(
              'Feedback Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject Field
            const Text(
              'Subject',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Enter feedback subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),

            // Message Field
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Share your feedback, ideas, or issues...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D4F8B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitFeedback,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Alternative Contact Methods
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other Ways to Contact',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Email: support@medisafe.com\n'
                      'Phone: +91-878-009-5396',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    // Show success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Thank You!'),
        content: const Text(
          'Your feedback has been sent successfully. '
          'We appreciate your input and will review it shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to settings
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

