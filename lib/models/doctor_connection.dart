class DoctorModel {
  final int? id;
  final int? userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String specialization;
  final String licenseNumber;
  final String hospitalName;
  final String experience;
  final String location;
  final String? profilePicture;
  final String connectionStatus; // 'none', 'pending', 'accepted', 'rejected'
  final int? connectionId;

  DoctorModel({
    this.id,
    this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.specialization = 'General Physician',
    this.licenseNumber = '',
    this.hospitalName = '',
    this.experience = '',
    this.location = '',
    this.profilePicture,
    this.connectionStatus = 'none',
    this.connectionId,
  });

  DoctorModel copyWith({
    int? id,
    int? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? specialization,
    String? licenseNumber,
    String? hospitalName,
    String? experience,
    String? location,
    String? profilePicture,
    String? connectionStatus,
    int? connectionId,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hospitalName: hospitalName ?? this.hospitalName,
      experience: experience ?? this.experience,
      location: location ?? this.location,
      profilePicture: profilePicture ?? this.profilePicture,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionId: connectionId ?? this.connectionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'hospitalName': hospitalName,
      'experience': experience,
      'location': location,
      'profilePicture': profilePicture,
      'connectionStatus': connectionStatus,
      'connectionId': connectionId,
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['userId'] is int ? map['userId'] as int : int.tryParse(map['userId']?.toString() ?? ''),
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString(),
      specialization: map['specialization']?.toString() ?? 'General Physician',
      licenseNumber: map['licenseNumber']?.toString() ?? '',
      hospitalName: map['hospitalName']?.toString() ?? '',
      experience: map['experience']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      profilePicture: map['profilePicture']?.toString(),
      connectionStatus: map['connectionStatus']?.toString() ?? 'none',
      connectionId: map['connectionId'] is int
          ? map['connectionId'] as int
          : int.tryParse(map['connectionId']?.toString() ?? ''),
    );
  }
}

class DoctorConnectionItem {
  final int id;
  final int doctorId;
  final int requesterId;
  final String requesterRole; // 'patient' or 'caretaker'
  final String requesterName;
  final String requesterEmail;
  final String? requesterPhone;
  final String? requesterGender;
  final String? requesterBirthDate;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DoctorConnectionItem({
    required this.id,
    required this.doctorId,
    required this.requesterId,
    required this.requesterRole,
    required this.requesterName,
    required this.requesterEmail,
    this.requesterPhone,
    this.requesterGender,
    this.requesterBirthDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  DoctorConnectionItem copyWith({
    int? id,
    int? doctorId,
    int? requesterId,
    String? requesterRole,
    String? requesterName,
    String? requesterEmail,
    String? requesterPhone,
    String? requesterGender,
    String? requesterBirthDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorConnectionItem(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      requesterId: requesterId ?? this.requesterId,
      requesterRole: requesterRole ?? this.requesterRole,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      requesterGender: requesterGender ?? this.requesterGender,
      requesterBirthDate: requesterBirthDate ?? this.requesterBirthDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'requesterId': requesterId,
      'requesterRole': requesterRole,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'requesterPhone': requesterPhone,
      'requesterGender': requesterGender,
      'requesterBirthDate': requesterBirthDate,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory DoctorConnectionItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDt(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return DoctorConnectionItem(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      doctorId: map['doctorId'] is int ? map['doctorId'] as int : int.tryParse(map['doctorId']?.toString() ?? '0') ?? 0,
      requesterId: map['requesterId'] is int ? map['requesterId'] as int : int.tryParse(map['requesterId']?.toString() ?? '0') ?? 0,
      requesterRole: map['requesterRole']?.toString() ?? 'patient',
      requesterName: map['requesterName']?.toString() ?? 'Unknown User',
      requesterEmail: map['requesterEmail']?.toString() ?? '',
      requesterPhone: map['requesterPhone']?.toString(),
      requesterGender: map['requesterGender']?.toString(),
      requesterBirthDate: map['requesterBirthDate']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: parseDt(map['createdAt']),
      updatedAt: parseDt(map['updatedAt']),
    );
  }
}
