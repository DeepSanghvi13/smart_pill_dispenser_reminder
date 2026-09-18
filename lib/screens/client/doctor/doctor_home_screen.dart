import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/image_helper.dart';
import '../../../models/prescription.dart';
import '../../../models/user_profile.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/doctor_service.dart';
import '../../../services/medical_shop_service.dart';
import '../../../widgets/app_drawer.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedTabIndex = 0; // 0: Requests, 1: Patients, 2: Caretakers, 3: Prescriptions
  int? _processingId;
  final MedicalShopService _shopService = MedicalShopService();
  List<Prescription> _doctorPrescriptions = [];
  bool _isLoadingPrescriptions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    await doctorService.loadAllDoctorData();
    await _loadDoctorPrescriptions();
  }

  Future<void> _loadDoctorPrescriptions() async {
    setState(() => _isLoadingPrescriptions = true);
    try {
      final list = await _shopService.getDoctorPrescriptions();
      if (mounted) {
        setState(() {
          _doctorPrescriptions = list;
          _isLoadingPrescriptions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPrescriptions = false);
      }
    }
  }

  Future<void> _handleAccept(int connectionId) async {
    setState(() => _processingId = connectionId);
    final error = await doctorService.acceptRequest(connectionId);
    if (!mounted) return;
    setState(() => _processingId = null);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor connection request accepted.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleReject(int connectionId) async {
    setState(() => _processingId = connectionId);
    final error = await doctorService.rejectRequest(connectionId);
    if (!mounted) return;
    setState(() => _processingId = null);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor connection request rejected.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleRemoveRequest(int connectionId, String requesterName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Request'),
        content: Text('Are you sure you want to remove the connection request from $requesterName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processingId = connectionId);
      final success = await doctorService.removeRequest(connectionId);
      if (!mounted) return;
      setState(() => _processingId = null);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request removed.'),
            backgroundColor: Colors.blueGrey,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemovePatient(int connectionId, String patientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Patient'),
        content: Text('Are you sure you want to remove $patientName from your connected patients?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processingId = connectionId);
      final success = await doctorService.removeConnection(connectionId);
      if (!mounted) return;
      setState(() => _processingId = null);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$patientName has been removed from connected patients.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove patient connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveCaretaker(int connectionId, String caretakerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Caretaker'),
        content: Text('Are you sure you want to remove $caretakerName from your connected caretakers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processingId = connectionId);
      final success = await doctorService.removeConnection(connectionId);
      if (!mounted) return;
      setState(() => _processingId = null);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$caretakerName has been removed from connected caretakers.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove caretaker connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showCreatePrescriptionDialog([String? defaultPatientEmail]) {
    final patients = doctorService.myPatients;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have any connected patients yet to issue prescriptions for.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedPatient = defaultPatientEmail ?? patients.first['email'].toString();
    final medNameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '500 mg');
    final freqCtrl = TextEditingController(text: 'Twice daily after meals');
    final durCtrl = TextEditingController(text: '7 days');
    final qtyCtrl = TextEditingController(text: '14');
    final diagCtrl = TextEditingController();
    final instCtrl = TextEditingController();
    DateTime validUntil = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.medical_services_outlined, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Issue Prescription'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPatient,
                  decoration: const InputDecoration(
                    labelText: 'Select Patient *',
                    border: OutlineInputBorder(),
                  ),
                  items: patients.map((p) {
                    final pEmail = p['email'].toString();
                    final pName = p['fullName']?.toString() ?? pEmail;
                    return DropdownMenuItem(
                      value: pEmail,
                      child: Text('$pName ($pEmail)', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedPatient = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: medNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    hintText: 'e.g. Paracetamol / Amoxicillin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dosageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dosage *',
                          hintText: 'e.g. 500mg',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          hintText: 'e.g. 14',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: freqCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Frequency *',
                    hintText: 'e.g. Twice daily after meals',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duration *',
                    hintText: 'e.g. 7 days',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis / Condition',
                    hintText: 'e.g. Acute Bronchitis',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instructions / Dietary Advice',
                    hintText: 'e.g. Drink plenty of warm water. Avoid dairy.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: validUntil,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => validUntil = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Valid Until (DD/MM/YYYY) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(validUntil)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final medName = medNameCtrl.text.trim();
                final dosage = dosageCtrl.text.trim();
                final freq = freqCtrl.text.trim();
                final dur = durCtrl.text.trim();
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                if (medName.isEmpty || dosage.isEmpty || freq.isEmpty || dur.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required prescription fields.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final res = await _shopService.createPrescription(
                  patientId: selectedPatient,
                  medicineName: medName,
                  dosage: dosage,
                  frequency: freq,
                  duration: dur,
                  quantity: qty,
                  diagnosis: diagCtrl.text.trim().isEmpty ? null : diagCtrl.text.trim(),
                  instructions: instCtrl.text.trim().isEmpty ? null : instCtrl.text.trim(),
                  validUntil: validUntil,
                );

                if (!mounted) return;
                if (res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Prescription for $medName issued successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDoctorPrescriptions();
                  setState(() => _selectedTabIndex = 3);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to issue prescription. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Issue'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final email = auth.currentUser ?? 'doctor';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Doctor Profile Greeting Card
                    FutureBuilder<UserProfile?>(
                      future: DatabaseService().getUserProfileData(),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        final name = profile?.fullName ?? email.split('@').first;
                        final spec = profile?.specialization ?? 'General Physician';
                        final hosp = profile?.hospitalName ?? '';
                        final pic = profile?.profilePicture;

                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: theme.colorScheme.primary,
                                  backgroundImage: AppImageHelper.getImageProvider(pic),
                                  child: AppImageHelper.getImageProvider(pic) == null
                                      ? const Icon(Icons.medical_services, size: 30, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dr. $name',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        spec,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      if (hosp.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          hosp,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit Profile',
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.createProfile).then((_) {
                                      setState(() {});
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Dashboard Overview Section (Interactive Stat Cards)
                    AnimatedBuilder(
                      animation: doctorService,
                      builder: (context, _) {
                        final pendingCount = doctorService.incomingRequests.length;
                        final patientsCount = doctorService.myPatients.length;
                        final caretakersCount = doctorService.myCaretakers.length;
                        final prescriptionsCount = _doctorPrescriptions.length;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatCard(
                                context: context,
                                label: 'Requests',
                                value: '$pendingCount',
                                color: Colors.orange.shade800,
                                icon: Icons.pending_actions,
                                tabIndex: 0,
                                isSelected: _selectedTabIndex == 0,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                context: context,
                                label: 'Patients',
                                value: '$patientsCount',
                                color: Colors.blue.shade700,
                                icon: Icons.healing,
                                tabIndex: 1,
                                isSelected: _selectedTabIndex == 1,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                context: context,
                                label: 'Caretakers',
                                value: '$caretakersCount',
                                color: Colors.teal.shade700,
                                icon: Icons.people,
                                tabIndex: 2,
                                isSelected: _selectedTabIndex == 2,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                context: context,
                                label: 'Prescriptions',
                                value: '$prescriptionsCount',
                                color: Colors.deepPurple.shade700,
                                icon: Icons.description,
                                tabIndex: 3,
                                isSelected: _selectedTabIndex == 3,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Section Heading + Create Prescription Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _selectedTabIndex == 0
                                  ? Icons.pending_actions
                                  : _selectedTabIndex == 1
                                      ? Icons.healing
                                      : _selectedTabIndex == 2
                                          ? Icons.people
                                          : Icons.description,
                              size: 18,
                              color: _selectedTabIndex == 0
                                  ? Colors.orange.shade800
                                  : _selectedTabIndex == 1
                                      ? Colors.blue.shade700
                                      : _selectedTabIndex == 2
                                          ? Colors.teal.shade700
                                          : Colors.deepPurple.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTabIndex == 0
                                  ? 'Pending Connection Requests'
                                  : _selectedTabIndex == 1
                                      ? 'Connected Patients'
                                      : _selectedTabIndex == 2
                                          ? 'Connected Caretakers'
                                          : 'Issued Prescriptions',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedTabIndex == 3 || _selectedTabIndex == 1)
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Prescribe'),
                            onPressed: () => _showCreatePrescriptionDialog(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Active Tab Content List
            if (_selectedTabIndex == 0)
              _buildRequestsSliver(theme)
            else if (_selectedTabIndex == 1)
              _buildPatientsSliver(theme)
            else if (_selectedTabIndex == 2)
              _buildCaretakersSliver(theme)
            else
              _buildPrescriptionsSliver(theme),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: _selectedTabIndex == 3
          ? FloatingActionButton.extended(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Prescription'),
              onPressed: () => _showCreatePrescriptionDialog(),
            )
          : null,
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required int tabIndex,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? color.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.25),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedTabIndex = tabIndex;
          });
        },
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Section 1: Connection Requests ----
  Widget _buildRequestsSliver(ThemeData theme) {
    return AnimatedBuilder(
      animation: doctorService,
      builder: (context, _) {
        if (doctorService.isLoading && doctorService.incomingRequests.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final requests = doctorService.incomingRequests;

        if (requests.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No pending connection requests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When patients or caretakers request to connect with you, they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final req = requests[index];
                final isProcessing = _processingId == req.id;
                final isPatient = req.requesterRole.toLowerCase() == 'patient';
                final reqDateStr = req.createdAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt!)
                    : 'Recently';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isPatient ? Colors.blue.shade100 : Colors.orange.shade100,
                              child: Icon(
                                isPatient ? Icons.person : Icons.people,
                                color: isPatient ? Colors.blue.shade800 : Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.requesterName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPatient ? Colors.blue.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isPatient ? Colors.blue.shade300 : Colors.orange.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      isPatient ? 'Patient' : 'Caretaker',
                                      style: TextStyle(
                                        color: isPatient ? Colors.blue.shade800 : Colors.orange.shade800,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              tooltip: 'Remove Request',
                              onPressed: isProcessing ? null : () => _handleRemoveRequest(req.id, req.requesterName),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        if (req.requesterEmail.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(req.requesterEmail, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        if (req.requesterPhone != null && req.requesterPhone!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(req.requesterPhone!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text('Request Date: $reqDateStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (isProcessing)
                          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: () => _handleAccept(req.id),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.orange),
                                  label: const Text('Reject', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.orange),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: () => _handleReject(req.id),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: 'Delete Request',
                                onPressed: () => _handleRemoveRequest(req.id, req.requesterName),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: requests.length,
            ),
          ),
        );
      },
    );
  }

  // ---- Section 2: Connected Patients ----
  Widget _buildPatientsSliver(ThemeData theme) {
    return AnimatedBuilder(
      animation: doctorService,
      builder: (context, _) {
        final patients = doctorService.myPatients;

        if (patients.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.healing_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No connected patients yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Patients who connect with you will appear here with their contact details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final p = patients[index];
                final name = p['fullName']?.toString() ?? 'Patient';
                final pEmail = p['email']?.toString() ?? '';
                final pPhone = p['phoneNumber']?.toString();
                final gender = p['gender']?.toString();
                final connId = p['connectionId'] as int?;
                final connDateRaw = p['connectedAt']?.toString();
                final connDateStr = connDateRaw != null
                    ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(connDateRaw) ?? DateTime.now())
                    : 'Active';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(Icons.person, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (gender != null && gender.isNotEmpty)
                                    Text(gender, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                    style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (pEmail.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(pEmail, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (pPhone != null && pPhone.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(pPhone, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text('Connected Since: $connDateStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('Prescribe', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showCreatePrescriptionDialog(pEmail),
                            ),
                            if (pPhone != null && pPhone.isNotEmpty)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.call, size: 16, color: Colors.green),
                                label: const Text('Call', style: TextStyle(fontSize: 12, color: Colors.green)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                                onPressed: () => _makeCall(pPhone),
                              ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.mail_outline, size: 16),
                              label: const Text('Email', style: TextStyle(fontSize: 12)),
                              onPressed: () => _sendEmail(pEmail),
                            ),
                            if (connId != null)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_remove, size: 16),
                                label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  elevation: 0,
                                  side: BorderSide(color: Colors.red.shade300),
                                ),
                                onPressed: () => _handleRemovePatient(connId, name),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: patients.length,
            ),
          ),
        );
      },
    );
  }

  // ---- Section 3: Connected Caretakers ----
  Widget _buildCaretakersSliver(ThemeData theme) {
    return AnimatedBuilder(
      animation: doctorService,
      builder: (context, _) {
        final caretakers = doctorService.myCaretakers;

        if (caretakers.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No connected caretakers yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Caretakers who connect with you will appear here with their relationship and contact info.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final c = caretakers[index];
                final name = c['fullName']?.toString() ?? 'Caretaker';
                final cEmail = c['email']?.toString() ?? '';
                final cPhone = c['phoneNumber']?.toString();
                final rel = c['relationship']?.toString() ?? 'Caretaker';
                final connId = c['connectionId'] as int?;
                final connDateRaw = c['connectedAt']?.toString();
                final connDateStr = connDateRaw != null
                    ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(connDateRaw) ?? DateTime.now())
                    : 'Active';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.orange.shade50,
                              child: Icon(Icons.people, color: Colors.orange.shade800),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Relationship: $rel', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                    style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (cEmail.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(cEmail, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (cPhone != null && cPhone.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(cPhone, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text('Connected Since: $connDateStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (cPhone != null && cPhone.isNotEmpty) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.call, size: 16, color: Colors.green),
                                  label: const Text('Call', style: TextStyle(fontSize: 12, color: Colors.green)),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                                  onPressed: () => _makeCall(cPhone),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.mail_outline, size: 16),
                                label: const Text('Email', style: TextStyle(fontSize: 12)),
                                onPressed: () => _sendEmail(cEmail),
                              ),
                            ),
                            if (connId != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_remove, size: 16),
                                label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  elevation: 0,
                                  side: BorderSide(color: Colors.red.shade300),
                                ),
                                onPressed: () => _handleRemoveCaretaker(connId, name),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: caretakers.length,
            ),
          ),
        );
      },
    );
  }

  // ---- Section 4: Issued Prescriptions ----
  Widget _buildPrescriptionsSliver(ThemeData theme) {
    if (_isLoadingPrescriptions && _doctorPrescriptions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_doctorPrescriptions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No prescriptions issued yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Issue official digital prescriptions to connected patients for medical shop fulfillment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Issue First Prescription'),
                  onPressed: () => _showCreatePrescriptionDialog(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = _doctorPrescriptions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medication, color: Colors.deepPurple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.medicineName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Patient: ${p.patientName ?? p.patientId}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: p.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.isActive ? 'Active' : 'Expired',
                            style: TextStyle(
                              color: p.isActive ? Colors.green.shade800 : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChip(Icons.opacity, p.dosage),
                        _buildChip(Icons.alarm, p.frequency),
                        _buildChip(Icons.timelapse, p.duration),
                        _buildChip(Icons.numbers, 'Qty: ${p.quantity}'),
                      ],
                    ),
                    if (p.diagnosis != null && p.diagnosis!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Diagnosis: ${p.diagnosis}',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                      ),
                    ],
                    if (p.instructions != null && p.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Instructions: ${p.instructions}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Issued: ${p.formattedIssuedDate}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        Text(
                          'Valid until: ${p.formattedValidUntilDate}',
                          style: TextStyle(
                            color: p.isActive ? Colors.grey.shade700 : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _doctorPrescriptions.length,
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
