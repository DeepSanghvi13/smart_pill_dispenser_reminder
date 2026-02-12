import 'package:flutter/material.dart';

class ReminderTroubleshootingScreen extends StatelessWidget {
  const ReminderTroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Troubleshooting'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete the following steps to make sure you get your reminders',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            _stepCard(
              step: 'Step 1: Check Autostart settings',
              icon: Icons.autorenew,
              description:
              'Medisafe needs to run automatically in the background when the phone starts up to send you reminders on time.',
              onTap: () {},
            ),

            _stepCard(
              step: 'Step 2: Verify notification sound is enabled',
              icon: Icons.volume_up,
              description:
              'Notification sound may be disabled on your device. To fix this, enable notification sound in your Settings.',
              onTap: () {},
            ),

            _stepCard(
              step: 'Step 3: Adjust advanced battery settings',
              icon: Icons.settings,
              description:
              'Ensure you get your notifications on time by adjusting these battery settings.',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            const Text(
              'Also, please take note:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const Text(
              "Beware of 'task killers'",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D4F8B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Battery savers, anti-viruses or task killers such as Clean Master, '
                  '360 Security, CM Security, Fast Booster, may terminate Medisafe\'s '
                  'reminders and put your health at risk.\n\n'
                  'Please deactivate them to make sure they don\'t interfere with your reminders.',
            ),

            const SizedBox(height: 16),

            const Text(
              "Don't 'force stop'",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D4F8B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Closing Medisafe through the task manager (force stop) might block your reminders.',
            ),

            const SizedBox(height: 32),

            Center(
              child: Column(
                children: [
                  const Text(
                    'Need more help?',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Contact support',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0D4F8B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- STEP CARD ----------------
  Widget _stepCard({
    required String step,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D4F8B),
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF0D4F8B)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D4F8B)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Take this action',
                style: TextStyle(
                  color: Color(0xFF0D4F8B),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
