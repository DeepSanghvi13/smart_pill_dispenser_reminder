class AlarmLog {
  final int? id;
  final int medicineId;
  final String medicineName;
  final DateTime scheduledTime;
  final DateTime? triggeredTime;
  final String status; // 'pending', 'triggered', 'snoozed', 'taken', 'missed'
  final int snoozeCount;
  final DateTime? takenAt;
  final String? notes;

  AlarmLog({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    this.triggeredTime,
    this.status = 'pending',
    this.snoozeCount = 0,
    this.takenAt,
    this.notes,
  });

  AlarmLog copyWith({
    int? id,
    int? medicineId,
    String? medicineName,
    DateTime? scheduledTime,
    DateTime? triggeredTime,
    String? status,
    int? snoozeCount,
    DateTime? takenAt,
    String? notes,
  }) {
    return AlarmLog(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      triggeredTime: triggeredTime ?? this.triggeredTime,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'triggeredTime': triggeredTime?.toIso8601String(),
      'status': status,
      'snoozeCount': snoozeCount,
      'takenAt': takenAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory AlarmLog.fromMap(Map<String, dynamic> map) {
    return AlarmLog(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      medicineName: map['medicineName'] as String,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      triggeredTime: map['triggeredTime'] != null
          ? DateTime.parse(map['triggeredTime'] as String)
          : null,
      status: map['status'] as String? ?? 'pending',
      snoozeCount: map['snoozeCount'] as int? ?? 0,
      takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  bool get isMissed => status == 'missed';
  bool get isTaken => status == 'taken';
  bool get isPending => status == 'pending';
  bool get isSnoozed => status == 'snoozed';

  @override
  String toString() => 'AlarmLog($medicineName - $status at $scheduledTime)';
}

