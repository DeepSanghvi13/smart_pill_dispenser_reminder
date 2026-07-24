class User {
  final String fullName;
  final String email;
  final String password;
  final String role; // 'admin', 'patient', or 'caretaker'
  final bool isActive;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.fullName,
    required this.email,
    required this.password,
    this.role = 'patient',
    this.isActive = true,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdBy = createdBy ?? email,
        updatedBy = updatedBy ?? email,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  User copyWith({
    String? fullName,
    String? email,
    String? password,
    String? role,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      isActive: map['isActive'] == null ? true : (map['isActive'] as int? ?? 1) == 1,
      createdBy: map['createdBy'] as String? ?? map['email'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? map['email'] as String? ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }
}
