import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/doctor_connection.dart';
import '../../../routes/app_routes.dart';
import '../../../services/doctor_service.dart';
import '../../../core/responsive.dart';

class MyDoctorsScreen extends StatefulWidget {
  const MyDoctorsScreen({super.key});

  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      doctorService.loadMyDoctors();
    });
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _confirmDisconnect(DoctorModel doctor) {
    if (doctor.connectionId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Connection'),
        content: Text('Are you sure you want to disconnect from ${doctor.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await doctorService.removeConnection(doctor.connectionId!);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Disconnected from ${doctor.fullName}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doctors'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => doctorService.loadMyDoctors(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.findDoctor).then((_) {
            doctorService.loadMyDoctors();
          });
        },
        icon: const Icon(Icons.person_search),
        label: const Text('Find Doctor'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ResponsiveContentWrapper(
          maxWidth: 1100,
          child: AnimatedBuilder(
            animation: doctorService,
            builder: (context, _) {
          if (doctorService.isLoading && doctorService.myDoctors.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctors = doctorService.myDoctors;

          if (doctors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No connected doctors yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search for doctors in your area and send a connection request to start monitoring your health with professional care.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_search),
                      label: const Text('Find a Doctor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.findDoctor).then((_) {
                          doctorService.loadMyDoctors();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => doctorService.loadMyDoctors(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 650) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 520,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doc = doctors[index];
                      return _buildDoctorCard(context, doc, theme);
                    },
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    return _buildDoctorCard(context, doc, theme);
                  },
                );
              },
            ),
          );
        },
      ),
    ),
  ),
);
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doc, ThemeData theme) {
    return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Header: Avatar, Name, Specialization, Connected Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.medical_information,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          doc.fullName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (doc.isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          doc.specialization,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Connected',
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Doctor Clinic & Location Info
                        if (doc.hospitalName.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.local_hospital_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.hospitalName,
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        if (doc.location.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                doc.location,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        if (doc.email.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.email,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        if (doc.phoneNumber != null && doc.phoneNumber!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                doc.phoneNumber!,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        const SizedBox(height: 4),

                        // Action Buttons: Call, Email, Disconnect
                        Row(
                          children: [
                            if (doc.phoneNumber != null && doc.phoneNumber!.isNotEmpty) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.call, size: 16, color: Colors.green),
                                  label: const Text('Call', style: TextStyle(fontSize: 13, color: Colors.green)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _makeCall(doc.phoneNumber),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.mail_outline, size: 16),
                                label: const Text('Email', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _sendEmail(doc.email),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.event, size: 16),
                                label: const Text('Book Appointment'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.bookAppointment,
                                    arguments: doc,
                                  );
                                },
                              ),
                            ),
                            if (doc.connectionId != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.link_off, color: Colors.red, size: 20),
                                tooltip: 'Disconnect',
                                onPressed: () => _confirmDisconnect(doc),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
  }
}
