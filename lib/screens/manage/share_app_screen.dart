import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Medisafe'),
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
                    Icons.share,
                    size: 64,
                    color: Color(0xFF0D4F8B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Share Medisafe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help others manage their medications',
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

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why Share?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Help loved ones never miss their medications\n'
                      '• Reduce medication errors\n'
                      '• Improve health outcomes\n'
                      '• Join millions of users worldwide',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        onPressed: () {
                          Share.share(
                            'Check out Medisafe - the smart pill dispenser reminder app! '
                            'Never miss your medication again. Download now: '
                            'https://medisafe.com',
                            subject: 'Download Medisafe App',
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text(
                          'Share App Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share Methods
            const Text(
              'Share Via',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _shareOption(
              context,
              icon: Icons.mail,
              title: 'Email',
              onTap: () {
                Share.share(
                  'Check out Medisafe - the smart pill dispenser reminder app! '
                  'Never miss your medication again.',
                );
              },
            ),
            _shareOption(
              context,
              icon: Icons.chat,
              title: 'WhatsApp',
              onTap: () {
                Share.share(
                  'Check out Medisafe - the smart pill dispenser reminder app! '
                  'Never miss your medication again. Download: https://medisafe.com',
                );
              },
            ),
            _shareOption(
              context,
              icon: Icons.people,
              title: 'Facebook',
              onTap: () {
                Share.share(
                  'I\'m using Medisafe to manage my medications. It\'s amazing! '
                  'You should try it too: https://medisafe.com',
                );
              },
            ),
            _shareOption(
              context,
              icon: Icons.link,
              title: 'Copy Link',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D4F8B)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

