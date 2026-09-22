import 'package:intl/intl.dart';

class DoctorFeedback {
  final int? id;
  final int doctorId;
  final int patientId;
  final int? medicineId;
  final String feedbackText;
  final String? doctorName;
  final DateTime createdAt;

  DoctorFeedback({
    this.id,
    required this.doctorId,
    required this.patientId,
    this.medicineId,
    required this.feedbackText,
    this.doctorName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedDate => DateFormat('dd/MM/yyyy, hh:mm a').format(createdAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'medicineId': medicineId,
      'feedbackText': feedbackText,
      'doctorName': doctorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DoctorFeedback.fromMap(Map<String, dynamic> map) {
    return DoctorFeedback(
      id: map['id'] as int?,
      doctorId: map['doctorId'] as int? ?? 0,
      patientId: map['patientId'] as int? ?? 0,
      medicineId: map['medicineId'] as int?,
      feedbackText: map['feedbackText'] as String? ?? '',
      doctorName: map['doctorName'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
