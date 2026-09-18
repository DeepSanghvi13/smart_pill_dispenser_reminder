import 'package:intl/intl.dart';

class Prescription {
  final int? id;
  final int doctorId;
  final int patientId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final String? instructions;
  final String? diagnosis;
  final DateTime? validUntil;
  final int? shopMedicineId;
  final String status;
  final String? doctorName;
  final String? doctorEmail;
  final String? doctorPhone;
  final String? doctorSpecialization;
  final String? doctorHospital;
  final String? patientName;
  final String? patientEmail;
  final double? shopMedicinePrice;
  final int? shopMedicineStock;
  final bool? shopMedicineAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Prescription({
    this.id,
    required this.doctorId,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.quantity = 1,
    this.instructions,
    this.diagnosis,
    this.validUntil,
    this.shopMedicineId,
    this.status = 'active',
    this.doctorName,
    this.doctorEmail,
    this.doctorPhone,
    this.doctorSpecialization,
    this.doctorHospital,
    this.patientName,
    this.patientEmail,
    this.shopMedicinePrice,
    this.shopMedicineStock,
    this.shopMedicineAvailable,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive =>
      status.toLowerCase() == 'active' &&
      (validUntil == null || validUntil!.isAfter(DateTime.now()));

  String get formattedDate => createdAt != null
      ? DateFormat('dd/MM/yyyy, hh:mm a').format(createdAt!)
      : 'Active Prescription';

  String get formattedIssuedDate =>
      createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt!) : 'N/A';

  String get formattedValidUntilDate => validUntil != null
      ? DateFormat('dd/MM/yyyy').format(validUntil!)
      : 'No Expiry';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'medicineName': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'quantity': quantity,
      'instructions': instructions,
      'diagnosis': diagnosis,
      'validUntil': validUntil?.toIso8601String(),
      'shopMedicineId': shopMedicineId,
      'status': status,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as int?,
      doctorId: map['doctorId'] as int? ?? 0,
      patientId: map['patientId'] as int? ?? 0,
      medicineName: map['medicineName'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      instructions: map['instructions'] as String?,
      diagnosis: map['diagnosis'] as String?,
      validUntil: map['validUntil'] != null
          ? DateTime.tryParse(map['validUntil'].toString())
          : null,
      shopMedicineId: map['shopMedicineId'] as int?,
      status: map['status'] as String? ?? 'active',
      doctorName: map['doctorName'] as String?,
      doctorEmail: map['doctorEmail'] as String?,
      doctorPhone: map['doctorPhone'] as String?,
      doctorSpecialization: map['doctorSpecialization'] as String?,
      doctorHospital: map['doctorHospital'] as String?,
      patientName: map['patientName'] as String?,
      patientEmail: map['patientEmail'] as String?,
      shopMedicinePrice:
          double.tryParse(map['shopMedicinePrice']?.toString() ?? ''),
      shopMedicineStock:
          int.tryParse(map['shopMedicineStock']?.toString() ?? ''),
      shopMedicineAvailable:
          map['shopMedicineAvailable'] == 1 || map['shopMedicineAvailable'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}
