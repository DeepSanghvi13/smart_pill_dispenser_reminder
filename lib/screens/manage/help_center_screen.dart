import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  void _shareHelp(BuildContext context) {
    const helpText =
        'Need help with Medisafe?\n\n'
        'Visit the Help Center:\n'
        'https://www.medisafe.com/help';

    Clipboard.setData(const ClipboardData(text: helpText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help Center link copied to clipboard'),
      ),
    );
  }

  void _copySupportEmail(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(text: 'support@medisafe.com'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support email copied'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Find answers to common questions, get troubleshooting help, '
                  'or contact our support team.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 30),

            // ===== HELP OPTIONS =====
            _optionTile(
              icon: Icons.article_outlined,
              title: 'Help Articles',
              subtitle: 'Guides and FAQs',
              onTap: () {},
            ),

            _optionTile(
              icon: Icons.support_agent,
              title: 'Contact Support',
              subtitle: 'Email our support team',
              onTap: () => _copySupportEmail(context),
            ),

            _optionTile(
              icon: Icons.share,
              title: 'Share Help Center',
              subtitle: 'Share help resources with others',
              onTap: () => _shareHelp(context),
            ),

            const Spacer(),

            Center(
              child: Text(
                'Medisafe Help Center',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== OPTION TILE =====
  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D4F8B)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
