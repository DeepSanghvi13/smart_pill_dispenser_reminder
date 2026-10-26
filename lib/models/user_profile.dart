class UserProfile {
  final String email; // acts as ID/relationship to User
  final String fullName;
  final String? profilePicture; // file path or base64
  final int? age;
  final String? gender;
  final String? mobileNumber;
  final String? emergencyContact;
  final String? bloodGroup;
  final String? weight;
  final String? height;
  final String? medicalConditions;
  final String? relationship; // Caretaker field
  final String? connectionCode; // Patient field
  final String? address; // Patient / general address

  // Doctor fields
  final String? specialization;
  final String? licenseNumber;
  final String? hospitalName;
  final String? experience;
  final String? location;
  final bool isVerified;

  // Audit metadata fields
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.email,
    required this.fullName,
    this.profilePicture,
    this.age,
    this.gender,
    this.mobileNumber,
    this.emergencyContact,
    this.bloodGroup,
    this.weight,
    this.height,
    this.medicalConditions,
    this.relationship,
    this.connectionCode,
    this.address,
    this.specialization,
    this.licenseNumber,
    this.hospitalName,
    this.experience,
    this.location,
    this.isVerified = false,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdBy = createdBy ?? email,
        updatedBy = updatedBy ?? email,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? email,
    String? fullName,
    String? profilePicture,
    int? age,
    String? gender,
    String? mobileNumber,
    String? emergencyContact,
    String? bloodGroup,
    String? weight,
    String? height,
    String? medicalConditions,
    String? relationship,
    String? connectionCode,
    String? address,
    String? specialization,
    String? licenseNumber,
    String? hospitalName,
    String? experience,
    String? location,
    bool? isVerified,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePicture: profilePicture ?? this.profilePicture,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      relationship: relationship ?? this.relationship,
      connectionCode: connectionCode ?? this.connectionCode,
      address: address ?? this.address,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hospitalName: hospitalName ?? this.hospitalName,
      experience: experience ?? this.experience,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'age': age,
      'gender': gender,
      'mobileNumber': mobileNumber,
      'emergencyContact': emergencyContact,
      'bloodGroup': bloodGroup,
      'weight': weight,
      'height': height,
      'medicalConditions': medicalConditions,
      'relationship': relationship,
      'connectionCode': connectionCode,
      'address': address ?? location,
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'hospitalName': hospitalName,
      'experience': experience,
      'location': location ?? address,
      'isVerified': isVerified ? 1 : 0,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    String? stringValue(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    int? calculateAge(String? birthDate) {
      if (birthDate == null) return null;
      final parsed = DateTime.tryParse(birthDate);
      if (parsed == null) return null;
      final today = DateTime.now();
      var result = today.year - parsed.year;
      if (today.month < parsed.month ||
          (today.month == parsed.month && today.day < parsed.day)) {
        result--;
      }
      return result >= 0 ? result : null;
    }

    final emailVal = stringValue(map['email']) ?? '';
    final rawAddr = stringValue(map['address'] ?? map['zipCode']);
    final rawLoc = stringValue(map['location']);
    final birthDate =
        stringValue(map['birthDate'] ?? map['birth_date'] ?? map['dob']);
    final rawAge = map['age'];
    return UserProfile(
      email: emailVal,
      fullName: stringValue(map['fullName']) ??
          '${stringValue(map['firstName']) ?? ''} ${stringValue(map['lastName']) ?? ''}'
              .trim(),
      profilePicture:
          stringValue(map['profilePicture'] ?? map['profile_picture']),
      age: rawAge is num
          ? rawAge.toInt()
          : int.tryParse(rawAge?.toString() ?? '') ?? calculateAge(birthDate),
      gender: stringValue(map['gender']),
      mobileNumber: stringValue(
          map['mobileNumber'] ?? map['phoneNumber'] ?? map['phone_number']),
      emergencyContact:
          stringValue(map['emergencyContact'] ?? map['emergency_contact']),
      bloodGroup: stringValue(map['bloodGroup'] ?? map['blood_group']),
      weight: stringValue(map['weight']),
      height: stringValue(map['height']),
      medicalConditions:
          stringValue(map['medicalConditions'] ?? map['medical_conditions']),
      relationship: stringValue(map['relationship']),
      connectionCode:
          stringValue(map['connectionCode'] ?? map['connection_code']),
      address: rawAddr ?? rawLoc,
      specialization: stringValue(map['specialization']),
      licenseNumber: stringValue(map['licenseNumber']),
      hospitalName: stringValue(map['hospitalName']),
      experience: stringValue(map['experience']),
      location: rawLoc ?? rawAddr,
      isVerified: map['isVerified'] == 1 || map['isVerified'] == true,
      createdBy: map['createdBy'] as String? ?? emailVal,
      updatedBy: map['updatedBy'] as String? ?? emailVal,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
