import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
        content: Text('Help Center link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareVia(BuildContext context, String platform) async {
    const String helpLink = 'https://www.medisafe.com/help';
    const String messageText =
        'Check out the Smart Pill Dispenser Reminder Help Center for medication management tips and support!';

    try {
      if (platform == 'whatsapp') {
        // WhatsApp share - properly encoded
        final String encodedMessage =
            Uri.encodeComponent('$messageText\n\n$helpLink');
        final Uri whatsappUri =
            Uri.parse('https://wa.me/?text=$encodedMessage');

        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp not installed. Please install WhatsApp.'),
            ),
          );
        }
      } else if (platform == 'email') {
        // Email share with proper URI encoding
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: '', // empty path for compose
          queryParameters: {
            'subject': 'Smart Pill Dispenser Reminder - Help Center',
            'body': '$messageText\n\n$helpLink',
          },
        );

        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email app found. Please check your settings.'),
            ),
          );
        }
      } else if (platform == 'sms') {
        // SMS share
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: '',
          queryParameters: {
            'body': '$messageText\n\n$helpLink',
          },
        );

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS not available on this device.'),
            ),
          );
        }
      } else {
        // Generic share for other platforms
        await Share.share(
          '$messageText\n\n$helpLink',
          subject: 'Smart Pill Dispenser Reminder - Help Center',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Help Center'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share the Help',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Help others discover our Help Center and support resources. Share with friends and family!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Copy Section
                  const Text(
                    'Copy Link',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Copy Link Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.link,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Help Center Link',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'medisafe.com/help',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy, size: 20),
                            onPressed: () => _copyLink(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Share Options Section
                  const Text(
                    'Share Via',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp Option
                  _buildShareOption(
                    icon: Icons.chat,
                    title: 'WhatsApp',
                    subtitle: 'Share via WhatsApp',
                    color: Colors.green,
                    onTap: () => _shareVia(context, 'whatsapp'),
                  ),

                  const SizedBox(height: 12),

                  // Email Option
                  _buildShareOption(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'Send via Email',
                    color: Colors.orange,
                    onTap: () => _shareVia(context, 'email'),
                  ),

                  const SizedBox(height: 12),

                  // SMS Option
                  _buildShareOption(
                    icon: Icons.sms,
                    title: 'SMS',
                    subtitle: 'Share via Text Message',
                    color: Colors.blue,
                    onTap: () => _shareVia(context, 'sms'),
                  ),

                  const SizedBox(height: 12),

                  // More Options
                  _buildShareOption(
                    icon: Icons.share,
                    title: 'More Options',
                    subtitle: 'Share using other apps',
                    color: Colors.purple,
                    onTap: () => _shareVia(context, 'more'),
                  ),

                  const SizedBox(height: 30),

                  // Features Section
                  const Text(
                    'Why Share?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureItem(
                    Icons.people,
                    'Help Others',
                    'Share valuable medication management resources',
                  ),
                  _buildFeatureItem(
                    Icons.support,
                    'Better Support',
                    'More users means better community support',
                  ),
                  _buildFeatureItem(
                    Icons.favorite,
                    'Improve Health',
                    'Help friends manage their medications safely',
                  ),
                  _buildFeatureItem(
                    Icons.star,
                    'Community Growth',
                    'Build a healthier community together',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
