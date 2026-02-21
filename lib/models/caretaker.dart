class Caretaker {
  final int? id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String relationship;
  final bool notifyViaSMS;
  final bool notifyViaEmail;
  final bool notifyViaNotification;
  final bool isActive;
  final String? createdAt;

  Caretaker({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.relationship,
    this.notifyViaSMS = true,
    this.notifyViaEmail = true,
    this.notifyViaNotification = true,
    this.isActive = true,
    this.createdAt,
  });

  Caretaker copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? notifyViaSMS,
    bool? notifyViaEmail,
    bool? notifyViaNotification,
    bool? isActive,
    String? createdAt,
  }) {
    return Caretaker(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      notifyViaSMS: notifyViaSMS ?? this.notifyViaSMS,
      notifyViaEmail: notifyViaEmail ?? this.notifyViaEmail,
      notifyViaNotification: notifyViaNotification ?? this.notifyViaNotification,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'notifyViaSMS': notifyViaSMS ? 1 : 0,
      'notifyViaEmail': notifyViaEmail ? 1 : 0,
      'notifyViaNotification': notifyViaNotification ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Caretaker.fromMap(Map<String, dynamic> map) {
    return Caretaker(
      id: map['id'] as int?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String,
      relationship: map['relationship'] as String,
      notifyViaSMS: (map['notifyViaSMS'] as int? ?? 0) == 1,
      notifyViaEmail: (map['notifyViaEmail'] as int? ?? 0) == 1,
      notifyViaNotification: (map['notifyViaNotification'] as int? ?? 0) == 1,
      isActive: (map['isActive'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() => 'Caretaker($fullName, $relationship)';
}

