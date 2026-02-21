class MissedMedicineAlert {
  final int? id;
  final int medicineId;
  final String medicineName;
  final DateTime scheduledTime;
  final DateTime detectedTime;
  final bool notificationSent;
  final int caretakersNotified;
  final String status;
  final String? notes;

  MissedMedicineAlert({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    required this.detectedTime,
    this.notificationSent = false,
    this.caretakersNotified = 0,
    this.status = 'pending',
    this.notes,
  });

  MissedMedicineAlert copyWith({
    int? id,
    int? medicineId,
    String? medicineName,
    DateTime? scheduledTime,
    DateTime? detectedTime,
    bool? notificationSent,
    int? caretakersNotified,
    String? status,
    String? notes,
  }) {
    return MissedMedicineAlert(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      detectedTime: detectedTime ?? this.detectedTime,
      notificationSent: notificationSent ?? this.notificationSent,
      caretakersNotified: caretakersNotified ?? this.caretakersNotified,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'detectedTime': detectedTime.toIso8601String(),
      'notificationSent': notificationSent ? 1 : 0,
      'caretakersNotified': caretakersNotified,
      'status': status,
      'notes': notes,
    };
  }

  factory MissedMedicineAlert.fromMap(Map<String, dynamic> map) {
    return MissedMedicineAlert(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      medicineName: map['medicineName'] as String,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      detectedTime: DateTime.parse(map['detectedTime'] as String),
      notificationSent: (map['notificationSent'] as int? ?? 0) == 1,
      caretakersNotified: map['caretakersNotified'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
    );
  }

  @override
  String toString() => 'MissedAlert($medicineName at $scheduledTime)';
}

