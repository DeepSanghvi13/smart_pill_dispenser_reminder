import 'package:flutter/material.dart';

import '../../../models/professional_review_request.dart';
import '../../../services/mysql_api_service.dart';

class ProfessionalReviewRequestScreen extends StatefulWidget {
  const ProfessionalReviewRequestScreen({super.key});

  @override
  State<ProfessionalReviewRequestScreen> createState() =>
      _ProfessionalReviewRequestScreenState();
}

class _ProfessionalReviewRequestScreenState
    extends State<ProfessionalReviewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _contactController = TextEditingController();
  final _concernController = TextEditingController();
  final _hospitalController = TextEditingController();

  String _urgency = 'normal';
  bool _submitting = false;

  @override
  void dispose() {
    _patientController.dispose();
    _contactController.dispose();
    _concernController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = ProfessionalReviewRequest(
        patientName: _patientController.text.trim(),
        contact: _contactController.text.trim(),
        concern: _concernController.text.trim(),
        preferredHospital: _hospitalController.text.trim().isEmpty
            ? null
            : _hospitalController.text.trim(),
        urgency: _urgency,
      );

      final ok = await MySQLApiService().submitProfessionalReviewRequest(request);
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional review request submitted.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit request. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor/Hospital Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _patientController,
                decoration: const InputDecoration(labelText: 'Patient Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact (phone/email)'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _urgency,
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _urgency = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Urgency'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Preferred doctor/hospital (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _concernController,
                decoration: const InputDecoration(labelText: 'Concern details'),
                minLines: 4,
                maxLines: 6,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.local_hospital),
                label: Text(_submitting ? 'Submitting...' : 'Submit for professional review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




