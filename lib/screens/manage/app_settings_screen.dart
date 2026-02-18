import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'create_profile_screen.dart';
import 'delete_account_reason_screen.dart';
import 'delete_account_confirm_screen.dart';
import 'general_settings_screen.dart';
import 'share_app_screen.dart';
import 'rate_medisafe_screen.dart';
import 'send_feedback_screen.dart';
import 'about_screen.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _section('Settings'),
          _item(
            context,
            icon: Icons.settings,
            title: 'General Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GeneralSettingsScreen(),
                ),
              );
            },
          ),

          _section('Account'),
          _item(
            context,
            icon: Icons.key,
            title: 'Open Account',
            subtitle: 'Create a free Medisafe account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateProfileScreen(),
                ),
              );
            },
          ),
          _item(
            context,
            icon: Icons.login,
            title: 'Login',
            subtitle: 'Login with an existing account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
          _item(
            context,
            icon: Icons.delete,
            title: 'Delete This Account',
            subtitle: 'Permanently delete account and information',
            color: Colors.red,
            onTap: () {
              _showDeleteAccountSheet(context);
            },
          ),

          _section('General'),
          _item(
            context,
            icon: Icons.share,
            title: 'Help Us and Share Medisafe',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShareAppScreen(),
                ),
              );
            },
          ),
          _item(
            context,
            icon: Icons.star,
            title: 'Rate Medisafe',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RateMedisafeScreen(),
                ),
              );
            },
          ),
          _item(
            context,
            icon: Icons.mail,
            title: 'Send Feedback',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SendFeedbackScreen(),
                ),
              );
            },
          ),
          _item(
            context,
            icon: Icons.info,
            title: 'About',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= LIST TILE =================
  Widget _item(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        Color color = Colors.grey,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // ================= DELETE ACCOUNT BOTTOM SHEET =================
  void _showDeleteAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 16),

              const Text(
                'Attention!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Deleting your account will permanently delete your information. '
                    'Are you sure you want to proceed?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // -------- Proceed Button --------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeleteAccountReasonScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFF0D4F8B),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(
                      color: Color(0xFF0D4F8B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // -------- Cancel Button --------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4F8B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
