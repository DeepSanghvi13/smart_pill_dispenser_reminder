import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/doctor_connection.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/doctor_service.dart';
import '../../../../services/mysql_api_service.dart';
import '../../../../routes/app_routes.dart';

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
  List<Map<String, dynamic>> _patients = [];
  int? _selectedPatientId;
  int? _bookedById;
  bool _loadingPatients = false;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    if (context.read<AuthService>().isCaretaker) {
      _loadPatients();
    }
  }

  Future<void> _loadPatients() async {
    setState(() => _loadingPatients = true);
    try {
      final auth = context.read<AuthService>();
      final profiles = auth.getConnectedPatients();
      debugPrint('Caretaker local ID: ${auth.currentUser}');
      debugPrint(
          'Caretaker patient source: Hive connections via AuthService.getConnectedPatients()');
      debugPrint('Caretaker raw monitored patients: ${profiles.length}');
      final api = MySQLApiService();
      final resolved = <Map<String, dynamic>>[];
      for (final profile in profiles) {
        final id = await api.resolveUserIdByEmail(profile.email);
        debugPrint('Resolved patient ${profile.email} to userId=$id');
        if (id != null) {
          await api.syncCaretakerPatient(id);
          resolved.add({
            'id': id,
            'email': profile.email,
            'fullName': profile.fullName,
          });
        }
      }
      _bookedById = await api.resolveUserIdByEmail(auth.currentUser!);
      debugPrint('Caretaker bookedById: $_bookedById');
      debugPrint('Caretaker patients after filtering: ${resolved.length}');
      if (mounted) {
        setState(() {
          _patients = resolved;
          _selectedPatientId =
              resolved.length == 1 ? resolved.first['id'] as int : null;
          _patientError = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Loading caretaker patients failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() =>
            _patientError = 'Unable to load monitored patients. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

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
    final doctorId = widget.doctor.id;
    if (doctorId == null || doctorId <= 0) {
      _showError('A valid doctor was not selected.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select an appointment date.');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select an appointment time.');
      return;
    }
    final now = DateTime.now();
    final selected = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    if (selected.isBefore(now)) {
      _showError('Please select a future date and time.');
      return;
    }

    final auth = context.read<AuthService>();
    final isCaretaker = auth.isCaretaker;
    if (isCaretaker && _selectedPatientId == null) {
      setState(
          () => _patientError = 'Select the patient this appointment is for.');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    final reason = _reasonCtrl.text.trim();

    final error = await context.read<DoctorService>().bookAppointment(
          doctorId,
          dateStr,
          timeStr,
          reason,
          patientId: isCaretaker ? _selectedPatientId : null,
          bookedById: isCaretaker ? _bookedById : null,
          bookedByRole: isCaretaker ? 'caretaker' : 'patient',
        );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Appointment request sent successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<DoctorService>().isLoading;
    final isCaretaker = context.watch<AuthService>().isCaretaker;
    final canBook = !isLoading &&
        (!isCaretaker ||
            (!_loadingPatients &&
                _patients.isNotEmpty &&
                _selectedPatientId != null));

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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.specialization,
                      style: TextStyle(
                          fontSize: 16, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isCaretaker) ...[
              const Text('Booking for',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_loadingPatients)
                const LinearProgressIndicator()
              else if (_patientError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_patientError!,
                        style: const TextStyle(color: Colors.red)),
                    TextButton.icon(
                      onPressed: _loadPatients,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              else if (_patients.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No connected patients found.'),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.caretakerHome);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Patient'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedPatientId,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Select monitored patient',
                    errorText: _patientError,
                  ),
                  items: _patients
                      .map((patient) {
                        final id = int.tryParse(patient['id'].toString());
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                              patient['fullName']?.toString() ?? 'Patient'),
                        );
                      })
                      .where((item) => item.value != null)
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedPatientId = value;
                    _patientError = null;
                  }),
                ),
              const SizedBox(height: 24),
            ],
            const Text('Select Date & Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null
                        ? 'Select Date'
                        : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Reason for Visit (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              onPressed: canBook ? _bookAppointment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Booking',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
