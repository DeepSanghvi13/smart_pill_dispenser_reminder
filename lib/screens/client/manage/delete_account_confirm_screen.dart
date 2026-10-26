import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';

class DeleteAccountConfirmScreen extends StatefulWidget {
  const DeleteAccountConfirmScreen({super.key});

  @override
  State<DeleteAccountConfirmScreen> createState() =>
      _DeleteAccountConfirmScreenState();
}

class _DeleteAccountConfirmScreenState
    extends State<DeleteAccountConfirmScreen> {
  bool agreed = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔵 TOP BLUE HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: const Text(
              'Deleting your account will remove all your information.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 📄 CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'This cannot be undone.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'By checking the box, you confirm the deletion of this account, '
                    'including medications list, reports, history, etc. '
                    'Once deleted, this information cannot be recovered. '
                    'You will need to create a new account in order to continue using Medisafe.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'We strongly suggest to export all your information before deleting your account.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ☑️ CHECKBOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: (value) {
                    setState(() {
                      agreed = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'I understand and wish to proceed',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // 🔴 DELETE BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (agreed && !_isDeleting)
                    ? () async {
                        final auth = context.read<AuthService>();
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context, rootNavigator: true);

                        setState(() => _isDeleting = true);
                        try {
                          final success = await auth.deleteAccount();
                          if (!mounted) return;
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Account and all associated data permanently deleted.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            navigator.pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          } else {
                            setState(() => _isDeleting = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Account deletion failed. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isDeleting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error deleting account: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Delete Permanently',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



