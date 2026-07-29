import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';

class CreateProfileScreen extends StatefulWidget {
  final bool isEditing; // If true, acts as Edit Profile screen from settings
  const CreateProfileScreen({super.key, this.isEditing = false});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController mobileController;
  late TextEditingController emergencyController;
  late TextEditingController weightController;
  late TextEditingController heightController;
  late TextEditingController conditionsController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedRelationship;
  String? _imagePath;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _relationships = [
    'Father',
    'Mother',
    'Wife',
    'Husband',
    'Son',
    'Daughter',
    'Brother',
    'Friend',
    'Doctor',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    ageController = TextEditingController();
    mobileController = TextEditingController();
    emergencyController = TextEditingController();
    weightController = TextEditingController();
    heightController = TextEditingController();
    conditionsController = TextEditingController();

    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final auth = context.read<AuthService>();
    final email = auth.currentUser;
    if (email == null) return;

    final profile = await DatabaseService().getUserProfileData();
    if (profile != null) {
      setState(() {
        nameController.text = profile.fullName;
        ageController.text = profile.age?.toString() ?? '';
        mobileController.text = profile.mobileNumber ?? '';
        emergencyController.text = profile.emergencyContact ?? '';
        weightController.text = profile.weight ?? '';
        heightController.text = profile.height ?? '';
        conditionsController.text = profile.medicalConditions ?? '';
        _selectedGender = _genders.contains(profile.gender) ? profile.gender : null;
        _selectedBloodGroup = _bloodGroups.contains(profile.bloodGroup) ? profile.bloodGroup : null;
        _selectedRelationship = _relationships.contains(profile.relationship) ? profile.relationship : null;
        _imagePath = profile.profilePicture;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    mobileController.dispose();
    emergencyController.dispose();
    weightController.dispose();
    heightController.dispose();
    conditionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final email = auth.currentUser ?? 'guest';
      final isCare = auth.isCaretaker;

      // Handle Connection Code logic for Patient profile
      String? connCode;
      if (!isCare) {
        final existing = await DatabaseService().getUserProfileData();
        connCode = existing?.connectionCode ??
            'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
      }

      final profile = UserProfile(
        email: email,
        fullName: nameController.text.trim(),
        profilePicture: _imagePath,
        age: isCare ? null : int.tryParse(ageController.text.trim()),
        gender: isCare ? null : _selectedGender,
        mobileNumber: mobileController.text.trim(),
        emergencyContact: isCare ? null : emergencyController.text.trim(),
        bloodGroup: isCare ? null : _selectedBloodGroup,
        weight: isCare ? null : weightController.text.trim(),
        height: isCare ? null : heightController.text.trim(),
        medicalConditions: isCare
            ? null
            : (conditionsController.text.trim().isEmpty ? null : conditionsController.text.trim()),
        relationship: isCare ? _selectedRelationship : null,
        connectionCode: connCode,
      );

      await DatabaseService().saveUserProfile(profile);
      await auth.markProfileAsCompleted();

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Routing logic
      if (widget.isEditing || Navigator.canPop(context)) {
        Navigator.pop(context, true); // go back if editing
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome); // go to home
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthService>();
    final isCare = auth.isCaretaker;
    final isFirstTime = !widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFirstTime ? 'Complete Profile' : 'Edit Profile'),
        automaticallyImplyLeading: Navigator.canPop(context),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isFirstTime) ...[
                      Text(
                        isCare ? 'Set Up Caretaker Profile' : 'Set Up Your Profile',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCare
                            ? 'Configure your credentials to monitor your patients.'
                            : 'Fill out your medical details to configure personalization.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Avatar Picker Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            backgroundImage: _imagePath != null && _imagePath!.isNotEmpty
                                ? FileImage(File(_imagePath!))
                                : null,
                            child: _imagePath == null
                                ? Icon(
                                    isCare ? Icons.medical_services_outlined : Icons.person,
                                    size: 64,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Full Name
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter full name'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Mobile Number
                            TextFormField(
                              controller: mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter mobile number'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Dynamic fields: Patient vs Caretaker
                            if (isCare) ...[
                              // Relationship Field
                              DropdownButtonFormField<String>(
                                value: _selectedRelationship,
                                decoration: InputDecoration(
                                  labelText: 'Relationship to Patient(s)',
                                  prefixIcon: const Icon(Icons.people_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: _relationships
                                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedRelationship = val),
                                validator: (value) => value == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Caretaker Email (Read Only Display)
                              TextFormField(
                                initialValue: auth.currentUser,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Registered Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ] else ...[
                              // Dynamic Patient Fields with Responsive Breakpoints
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 420;

                                  final ageField = TextFormField(
                                    controller: ageController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Age',
                                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  );

                                  final genderField = DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      prefixIcon: const Icon(Icons.wc),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _genders
                                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedGender = val),
                                    validator: (value) => value == null ? 'Required' : null,
                                  );

                                  final bloodField = DropdownButtonFormField<String>(
                                    value: _selectedBloodGroup,
                                    decoration: InputDecoration(
                                      labelText: 'Blood Group',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _bloodGroups
                                        .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedBloodGroup = val),
                                    validator: (value) => value == null ? 'Required' : null,
                                  );

                                  final weightField = TextFormField(
                                    controller: weightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Weight (kg)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) => value == null || value.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  );

                                  final heightField = TextFormField(
                                    controller: heightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Height (cm)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) => value == null || value.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  );

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (isCompact) ...[
                                        ageField,
                                        const SizedBox(height: 16),
                                        genderField,
                                      ] else ...[
                                        Row(
                                          children: [
                                            Expanded(flex: 2, child: ageField),
                                            const SizedBox(width: 12),
                                            Expanded(flex: 3, child: genderField),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 16),

                                      // Emergency Contact
                                      TextFormField(
                                        controller: emergencyController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          labelText: 'Emergency Contact',
                                          prefixIcon: const Icon(Icons.contact_phone_outlined),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (value) => value == null || value.trim().isEmpty
                                            ? 'Please enter emergency contact'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),

                                      if (isCompact) ...[
                                        bloodField,
                                        const SizedBox(height: 16),
                                        weightField,
                                        const SizedBox(height: 16),
                                        heightField,
                                      ] else ...[
                                        Row(
                                          children: [
                                            Expanded(child: bloodField),
                                            const SizedBox(width: 8),
                                            Expanded(child: weightField),
                                            const SizedBox(width: 8),
                                            Expanded(child: heightField),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Medical Conditions
                              TextFormField(
                                controller: conditionsController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Medical Conditions (optional)',
                                  alignLabelWithHint: true,
                                  prefixIcon: const Icon(Icons.healing_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                       style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isFirstTime ? 'Save & Continue' : 'Update Profile',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
