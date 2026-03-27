class UserProfile {
  final int? id;
  final String firstName;
  final String lastName;
  final String? gender;
  final String? birthDate;
  final String? zipCode;
  final String? phoneNumber;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.birthDate,
    this.zipCode,
    this.phoneNumber,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    String? zipCode,
    String? phoneNumber,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      zipCode: zipCode ?? this.zipCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthDate': birthDate,
      'zipCode': zipCode,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      gender: map['gender'] as String?,
      birthDate: map['birthDate'] as String?,
      zipCode: map['zipCode'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() => 'UserProfile($fullName)';
}


