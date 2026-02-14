import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareHelpCenterScreen extends StatelessWidget {
  const ShareHelpCenterScreen({super.key});

  void _copyLink(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(
        text: 'https://www.medisafe.com/help',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help Center link copied'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Help Center'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _copyLink(context),
          icon: const Icon(Icons.link),
          label: const Text('Copy Help Center Link'),
        ),
      ),
    );
  }
}
