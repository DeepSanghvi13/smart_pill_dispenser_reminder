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
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final emailVal = map['email'] as String? ?? '';
    return UserProfile(
      email: emailVal,
      fullName: map['fullName'] as String? ?? '',
      profilePicture: map['profilePicture'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      mobileNumber: map['mobileNumber'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      weight: map['weight'] as String?,
      height: map['height'] as String?,
      medicalConditions: map['medicalConditions'] as String?,
      relationship: map['relationship'] as String?,
      connectionCode: map['connectionCode'] as String?,
      createdBy: map['createdBy'] as String? ?? emailVal,
      updatedBy: map['updatedBy'] as String? ?? emailVal,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }
}
