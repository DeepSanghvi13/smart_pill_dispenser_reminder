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
  });

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
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      email: map['email'] as String? ?? '',
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
    );
  }
}
