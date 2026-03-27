import 'package:flutter/material.dart';
import 'delete_account_confirm_screen.dart';

class DeleteAccountReasonScreen extends StatefulWidget {
  const DeleteAccountReasonScreen({super.key});

  @override
  State<DeleteAccountReasonScreen> createState() =>
      _DeleteAccountReasonScreenState();
}

class _DeleteAccountReasonScreenState
    extends State<DeleteAccountReasonScreen> {
  int? selectedIndex;

  final List<String> reasons = [
    'I have a privacy concern',
    'I’m no longer using Medisafe',
    'I’m using a different account',
    'I want to start fresh',
    'I’m not happy with the app',
    'I started using a different app',
    'Other',
  ];

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
          // 🔵 TOP HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: const Text(
              'Can you share with us why you wish to delete your account?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),

          // 📋 REASONS LIST
          Expanded(
            child: ListView.separated(
              itemCount: reasons.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(reasons[index]),
                  trailing: selectedIndex == index
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),

          // ▶ CONTINUE BUTTON (LINKED CORRECTLY)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedIndex == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const DeleteAccountConfirmScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D4F8B),
                  disabledBackgroundColor:
                  Colors.grey.shade300,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue',
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
