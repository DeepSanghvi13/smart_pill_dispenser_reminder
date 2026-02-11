import 'package:flutter/material.dart';

class DeleteAccountConfirmScreen extends StatefulWidget {
  const DeleteAccountConfirmScreen({super.key});

  @override
  State<DeleteAccountConfirmScreen> createState() =>
      _DeleteAccountConfirmScreenState();
}

class _DeleteAccountConfirmScreenState
    extends State<DeleteAccountConfirmScreen> {
  bool agreed = false;

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
                onPressed: agreed
                    ? () {
                  // TODO: Add final delete logic here
                  Navigator.popUntil(
                    context,
                        (route) => route.isFirst,
                  );
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
                child: const Text(
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
