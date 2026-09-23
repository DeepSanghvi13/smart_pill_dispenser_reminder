import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/image_helper.dart';
import '../../../../services/doctor_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorService>().loadPatientAppointments();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: Consumer<DoctorService>(
        builder: (context, docService, _) {
          if (docService.isLoading && docService.patientAppointments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = docService.patientAppointments;

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                'You have no appointments yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => docService.loadPatientAppointments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                final statusColor = _getStatusColor(appt.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: AppImageHelper.getImageProvider(appt.doctorPicture),
                              child: AppImageHelper.getImageProvider(appt.doctorPicture) == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${appt.doctorName ?? 'Unknown'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (appt.doctorSpecialization != null)
                                    Text(
                                      appt.doctorSpecialization!,
                                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                appt.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(appt.appointmentDate),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(appt.appointmentTime),
                          ],
                        ),
                        if (appt.reason != null && appt.reason!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Reason: ${appt.reason}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
