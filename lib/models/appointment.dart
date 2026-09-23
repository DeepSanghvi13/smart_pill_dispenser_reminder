class Appointment {
  final int id;
  final int patientId;
  final int doctorId;
  final String appointmentDate;
  final String appointmentTime;
  final String? reason;
  final String status;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? doctorPicture;
  final String? patientName;
  final String? patientPicture;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.reason,
    required this.status,
    this.doctorName,
    this.doctorSpecialization,
    this.doctorPicture,
    this.patientName,
    this.patientPicture,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      patientId: json['patientId'] is int ? json['patientId'] : int.parse(json['patientId'].toString()),
      doctorId: json['doctorId'] is int ? json['doctorId'] : int.parse(json['doctorId'].toString()),
      appointmentDate: json['appointmentDate']?.toString().split('T').first ?? '',
      appointmentTime: json['appointmentTime'] ?? '',
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      doctorName: json['doctorName'],
      doctorSpecialization: json['specialization'],
      doctorPicture: json['doctorPicture'],
      patientName: json['patientName'],
      patientPicture: json['patientPicture'],
    );
  }
}
