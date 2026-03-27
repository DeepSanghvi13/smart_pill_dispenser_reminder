import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
                    Icons.info,
                    size: 64,
                    color: Color(0xFF0D4F8B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Medisafe',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D4F8B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Smart Pill Dispenser Reminder',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // About Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Medisafe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Medisafe is a smart medication reminder application designed to help you and your loved ones never miss a dose. With intelligent reminders, medication tracking, and family support features, Medisafe makes medication management simple and reliable.\n\n'
                      'Our mission is to improve medication adherence and ultimately help millions of people live healthier lives.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features
            const Text(
              'Key Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _featureItem('📱', 'Smart Reminders', 'Get timely notifications for medications'),
            _featureItem('👥', 'Family Support', 'Share medication info with family members'),
            _featureItem('📊', 'Track Progress', 'Monitor your medication adherence'),
            _featureItem('🔔', 'Customizable Alerts', 'Set reminders that work for you'),
            const SizedBox(height: 24),

            // Contact & Support
            const Text(
              'Support & Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _contactOption(
              icon: Icons.email,
              title: 'Email Support',
              value: 'support@medisafe.com',
              onTap: () => _launchUrl('mailto:support@medisafe.com'),
            ),
            _contactOption(
              icon: Icons.language,
              title: 'Website',
              value: 'www.medisafe.com',
              onTap: () => _launchUrl('https://www.medisafe.com'),
            ),
            _contactOption(
              icon: Icons.phone,
              title: 'Phone',
              value: '+91-878-009-5396',
              onTap: () => _launchUrl('tel:+91-878-009-5396'),
            ),
            const SizedBox(height: 24),

            // Legal
            const Text(
              'Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _legalOption(
              'Privacy Policy',
              onTap: () => _launchUrl('https://www.medisafe.com/privacy'),
            ),
            _legalOption(
              'Terms of Service',
              onTap: () => _launchUrl('https://www.medisafe.com/terms'),
            ),
            _legalOption(
              'Open Source Licenses',
              onTap: () {
                showLicensePage(context: context);
              },
            ),
            const SizedBox(height: 24),

            // Credits
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Developed with ❤️ by Medisafe Team',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Thank you for trusting us with your health and wellness.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
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

  Widget _featureItem(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactOption({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D4F8B)),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _legalOption(String title, {required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

