import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareMedisafeScreen extends StatelessWidget {
  const ShareMedisafeScreen({super.key});

  void _shareApp() {
    Share.share(
      '💊 Medisafe helps you remember to take your medicines on time!\n\n'
          'Download now:\n'
          'https://play.google.com/store/apps/details?id=com.medisafe.android.client',
      subject: 'Try Medisafe App',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Medisafe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Medisafe with friends',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Help your family and friends stay healthy by reminding them '
                  'to take their medicines on time.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: _shareApp,
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  'Share App',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D4F8B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
