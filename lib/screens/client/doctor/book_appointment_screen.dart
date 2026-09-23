import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/doctor_connection.dart';
import '../../../../services/doctor_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonCtrl = TextEditingController();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeStr = _selectedTime!.format(context);
    final reason = _reasonCtrl.text.trim();

    final error = await context.read<DoctorService>().bookAppointment(
      widget.doctor.id ?? 0,
      dateStr,
      timeStr,
      reason,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment request sent successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<DoctorService>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${widget.doctor.fullName}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.specialization,
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Reason for Visit (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Fever, routine checkup...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _bookAppointment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
