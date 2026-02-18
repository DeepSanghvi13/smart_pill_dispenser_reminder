import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ReminderTroubleshootingScreen extends StatefulWidget {
  const ReminderTroubleshootingScreen({super.key});

  @override
  State<ReminderTroubleshootingScreen> createState() =>
      _ReminderTroubleshootingScreenState();
}

class _ReminderTroubleshootingScreenState
    extends State<ReminderTroubleshootingScreen> {
  bool _step1Completed = false;
  bool _step2Completed = false;
  bool _step3Completed = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _confirmCancel();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reminder Troubleshooting'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmCancel(),
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
                isCompleted: _step1Completed,
                onTap: () => _openAutostartSettings(),
              ),

              _stepCard(
                step: 'Step 2: Verify notification sound is enabled',
                icon: Icons.volume_up,
                description:
                    'Notification sound may be disabled on your device. To fix this, enable notification sound in your Settings.',
                isCompleted: _step2Completed,
                onTap: () => _openNotificationSettings(),
              ),

              _stepCard(
                step: 'Step 3: Adjust advanced battery settings',
                icon: Icons.settings,
                description:
                    'Ensure you get your notifications on time by adjusting these battery settings.',
                isCompleted: _step3Completed,
                onTap: () => _openBatterySettings(),
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
                      onPressed: () => _contactSupport(),
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
      ),
    );
  }

  // ============= STEP CARD WIDGET =============
  Widget _stepCard({
    required String step,
    required IconData icon,
    required String description,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey[300]!,
          width: 2,
        ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : const Color(0xFF0D4F8B),
                  ),
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : icon,
                color: isCompleted ? Colors.green : const Color(0xFF0D4F8B),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.green : const Color(0xFF0D4F8B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isCompleted ? '✓ Completed' : 'Take this action',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Open Autostart Settings
  Future<void> _openAutostartSettings() async {
    try {
      if (Platform.isAndroid) {
        // Android intent for autostart settings
        const platform = MethodChannel('com.example.app/autostart');
        await platform.invokeMethod('openAutostartSettings');
      } else if (Platform.isIOS) {
        // iOS - Open Settings app
        await launchUrl(Uri.parse('app-settings:'));
      }

      // Mark step as completed
      _showCompletionDialog('Autostart Settings',
        'Step 1: Check Autostart settings has been completed!',
        () {
          setState(() {
            _step1Completed = true;
          });
        }
      );
    } catch (e) {
      // Fallback: Show manual instructions
      _showManualInstructions(
        'Step 1: Enable Autostart',
        Platform.isAndroid
          ? '1. Go to Settings → Apps → Medisafe\n'
            '2. Tap "Permissions"\n'
            '3. Enable "Autostart" or "Run at startup"\n'
            '4. Tap "Done" and come back to confirm'
          : '1. Go to Settings → General → Background App Refresh\n'
            '2. Find Medisafe and enable it\n'
            '3. Return to confirm',
        () {
          setState(() {
            _step1Completed = true;
          });
        }
      );
    }
  }

  /// Step 2: Open Notification Sound Settings
  Future<void> _openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        // Android intent for notification settings
        const platform = MethodChannel('com.example.app/notifications');
        await platform.invokeMethod('openNotificationSettings');
      } else if (Platform.isIOS) {
        // iOS - Open Settings
        await launchUrl(Uri.parse('app-settings:'));
      }

      _showCompletionDialog('Notification Sound',
        'Step 2: Verify notification sound is enabled!',
        () {
          setState(() {
            _step2Completed = true;
          });
        }
      );
    } catch (e) {
      // Fallback: Show manual instructions
      _showManualInstructions(
        'Step 2: Enable Notification Sound',
        Platform.isAndroid
          ? '1. Go to Settings → Apps → Medisafe\n'
            '2. Tap "Notifications"\n'
            '3. Enable "Sound"\n'
            '4. Make sure "Volume" is set to high\n'
            '5. Return to confirm'
          : '1. Go to Settings → Notifications → Medisafe\n'
            '2. Enable "Allow Notifications"\n'
            '3. Enable "Sound"\n'
            '4. Return to confirm',
        () {
          setState(() {
            _step2Completed = true;
          });
        }
      );
    }
  }

  /// Step 3: Open Battery Settings
  Future<void> _openBatterySettings() async {
    try {
      if (Platform.isAndroid) {
        // Android intent for battery optimization settings
        const platform = MethodChannel('com.example.app/battery');
        await platform.invokeMethod('openBatterySettings');
      } else if (Platform.isIOS) {
        // iOS - Open Settings
        await launchUrl(Uri.parse('app-settings:'));
      }

      _showCompletionDialog('Battery Settings',
        'Step 3: Adjust advanced battery settings completed!',
        () {
          setState(() {
            _step3Completed = true;
          });
        }
      );
    } catch (e) {
      // Fallback: Show manual instructions
      _showManualInstructions(
        'Step 3: Adjust Battery Settings',
        Platform.isAndroid
          ? '1. Go to Settings → Battery\n'
            '2. Find Medisafe in the battery optimization list\n'
            '3. Remove it from "Battery Saver" or "Doze" mode\n'
            '4. Go to Settings → Apps → Medisafe\n'
            '5. Set "Battery Optimization" to "Not Optimized"\n'
            '6. Return to confirm'
          : '1. Go to Settings → Battery\n'
            '2. Enable "Low Power Mode" if needed (but ensure notifications work)\n'
            '3. Return to confirm',
        () {
          setState(() {
            _step3Completed = true;
          });
        }
      );
    }
  }

  /// Contact Support
  Future<void> _contactSupport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a method to contact us:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('support@medisafe.com'),
              onTap: () {
                Navigator.pop(context);
                _launchEmail('support@medisafe.com');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: const Text('+91-878-009-5396'),
              onTap: () {
                Navigator.pop(context);
                _launchPhone('+91-878-009-5396');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Launch Email
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Medisafe Reminder Troubleshooting Support',
        'body': 'I need help with Medisafe reminders...',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  /// Launch Phone
  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  /// Show Completion Dialog
  void _showCompletionDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirmed'),
          ),
        ],
      ),
    );
  }

  /// Confirm Cancel Dialog
  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('Cancel Troubleshooting?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to exit? Your progress will not be saved.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You may need to complete these steps again if reminders don\'t work.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFF0D4F8B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context); // Exit screen
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  /// Show Manual Instructions
  void _showManualInstructions(String title, String instructions, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Follow these steps:'),
              const SizedBox(height: 12),
              Text(
                instructions,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D4F8B),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
