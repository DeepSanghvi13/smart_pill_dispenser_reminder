import 'package:flutter/material.dart';
import '../../services/caretaker_service.dart';
import '../../models/caretaker.dart';

class AddCaretakerScreen extends StatefulWidget {
  const AddCaretakerScreen({super.key});

  @override
  State<AddCaretakerScreen> createState() => _AddCaretakerScreenState();
}

class _AddCaretakerScreenState extends State<AddCaretakerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CaretakerService();

  String firstName = '';
  String lastName = '';
  String phone = '';
  String email = '';
  String relationship = 'Son';
  bool notifySMS = true;
  bool notifyEmail = true;
  bool notifyApp = true;
  bool isLoading = false;

  final relationships = ['Son', 'Daughter', 'Wife', 'Husband', 'Father', 'Mother', 'Sister', 'Brother', 'Nurse', 'Caregiver', 'Friend'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Caretaker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onChanged: (v) => firstName = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onChanged: (v) => lastName = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phone = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => email = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: relationship,
                decoration: InputDecoration(labelText: 'Relationship', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => relationship = v ?? 'Son'),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('📱 SMS Notification'),
                value: notifySMS,
                onChanged: (v) => setState(() => notifySMS = v ?? true),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('📧 Email Notification'),
                value: notifyEmail,
                onChanged: (v) => setState(() => notifyEmail = v ?? true),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('🔔 App Notification'),
                value: notifyApp,
                onChanged: (v) => setState(() => notifyApp = v ?? true),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Caretaker'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!notifySMS && !notifyEmail && !notifyApp) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one notification')));
      return;
    }

    setState(() => isLoading = true);
    try {
      await _service.addCaretaker(Caretaker(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
        email: email,
        relationship: relationship,
        notifyViaSMS: notifySMS,
        notifyViaEmail: notifyEmail,
        notifyViaNotification: notifyApp,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Caretaker added')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

