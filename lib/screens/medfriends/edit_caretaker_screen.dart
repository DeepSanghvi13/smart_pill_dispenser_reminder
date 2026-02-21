import 'package:flutter/material.dart';
import '../../services/caretaker_service.dart';
import '../../models/caretaker.dart';

class EditCaretakerScreen extends StatefulWidget {
  final Caretaker caretaker;
  const EditCaretakerScreen({super.key, required this.caretaker});

  @override
  State<EditCaretakerScreen> createState() => _EditCaretakerScreenState();
}

class _EditCaretakerScreenState extends State<EditCaretakerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CaretakerService();

  late String firstName;
  late String lastName;
  late String phone;
  late String email;
  late String relationship;
  late bool notifySMS;
  late bool notifyEmail;
  late bool notifyApp;
  late bool isActive;
  bool isLoading = false;

  final relationships = ['Son', 'Daughter', 'Wife', 'Husband', 'Father', 'Mother', 'Sister', 'Brother', 'Nurse', 'Caregiver', 'Friend'];

  @override
  void initState() {
    super.initState();
    firstName = widget.caretaker.firstName;
    lastName = widget.caretaker.lastName;
    phone = widget.caretaker.phoneNumber;
    email = widget.caretaker.email;
    relationship = widget.caretaker.relationship;
    notifySMS = widget.caretaker.notifyViaSMS;
    notifyEmail = widget.caretaker.notifyViaEmail;
    notifyApp = widget.caretaker.notifyViaNotification;
    isActive = widget.caretaker.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Caretaker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: firstName,
                decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onChanged: (v) => firstName = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: lastName,
                decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onChanged: (v) => lastName = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phone = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: email,
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status'),
                          Text(isActive ? '✅ Active' : '⛔ Inactive', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      Switch(value: isActive, onChanged: (v) => setState(() => isActive = v)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
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
      await _service.updateCaretaker(
        widget.caretaker.id!,
        Caretaker(
          id: widget.caretaker.id,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phone,
          email: email,
          relationship: relationship,
          notifyViaSMS: notifySMS,
          notifyViaEmail: notifyEmail,
          notifyViaNotification: notifyApp,
          isActive: isActive,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Updated')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

