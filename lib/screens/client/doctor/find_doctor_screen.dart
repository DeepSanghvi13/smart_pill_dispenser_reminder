import 'package:flutter/material.dart';
import '../../../models/doctor_connection.dart';
import '../../../services/doctor_service.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecialization = 'All';
  String? _connectingDoctorKey;

  final List<String> _specializations = [
    'All',
    'General Physician',
    'Cardiologist',
    'Neurologist',
    'Dermatologist',
    'Orthopedic',
    'Pediatrician',
    'Gynecologist',
    'Oncologist',
    'ENT Specialist',
    'Ophthalmologist',
    'Dentist',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    await doctorService.searchDoctors(
      query: _searchController.text.trim(),
      specialization: _selectedSpecialization,
    );
  }

  Future<void> _handleConnect(DoctorModel doctor) async {
    final key = doctor.id != null ? doctor.id.toString() : doctor.email;
    setState(() => _connectingDoctorKey = key);

    final error = await doctorService.sendConnectionRequest(
      doctor.id,
      doctorEmail: doctor.email,
    );

    if (!mounted) return;
    setState(() => _connectingDoctorKey = null);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor connection request sent successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _fetchDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Doctor'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDoctors,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by doctor name, specialization, hospital...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchDoctors();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    _fetchDoctors();
                  },
                  onSubmitted: (_) => _fetchDoctors(),
                ),
                const SizedBox(height: 12),

                // Specialization Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _specializations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final spec = _specializations[index];
                      final isSelected = _selectedSpecialization == spec;
                      return ChoiceChip(
                        label: Text(
                          spec,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSpecialization = spec;
                            });
                            _fetchDoctors();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Doctors List View
          Expanded(
            child: AnimatedBuilder(
              animation: doctorService,
              builder: (context, _) {
                if (doctorService.isLoading && doctorService.searchResults.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (doctorService.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text(
                            doctorService.errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            onPressed: _fetchDoctors,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final doctors = doctorService.searchResults;

                if (doctors.isEmpty) {
                  final isSearching = _searchController.text.isNotEmpty || _selectedSpecialization != 'All';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSearching ? 'No matching doctors found.' : 'No doctors are currently registered.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSearching
                                ? 'Try adjusting your search query or filter.'
                                : 'Registered doctors will appear here automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (isSearching) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Search'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedSpecialization = 'All';
                                });
                                _fetchDoctors();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _fetchDoctors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doc = doctors[index];
                      return _buildDoctorCard(context, doc);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doctor) {
    final theme = Theme.of(context);
    final isConnectingThis = _connectingDoctorKey == (doctor.id?.toString() ?? doctor.email);

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
            // Top: Avatar & Name & Specialization
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
                      Text(
                        doctor.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          doctor.specialization,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Details: Hospital, Location, Experience
            if (doctor.hospitalName.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.local_hospital_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor.hospitalName,
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            if (doctor.location.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    doctor.location,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            if (doctor.experience.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Experience: ${doctor.experience}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              child: _buildConnectionButton(context, doctor, isConnectingThis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton(BuildContext context, DoctorModel doctor, bool isConnecting) {
    final theme = Theme.of(context);
    final status = doctor.connectionStatus.toLowerCase();

    if (isConnecting) {
      return const OutlinedButton(
        onPressed: null,
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (status == 'accepted') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Connected'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already connected with this doctor.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    if (status == 'pending') {
      return OutlinedButton.icon(
        icon: Icon(Icons.hourglass_empty, size: 18, color: Colors.orange.shade700),
        label: Text('Request Pending', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.orange.shade400),
          backgroundColor: Colors.orange.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request already pending.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    if (status == 'rejected') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.refresh, size: 18, color: Colors.red),
        label: const Text('Rejected (Tap to Reconnect)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => _handleConnect(doctor),
      );
    }

    // Default 'none' status -> Connect Button
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add_alt_1, size: 18),
      label: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: () => _handleConnect(doctor),
    );
  }
}
