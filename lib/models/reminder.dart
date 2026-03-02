class Reminder {
  final int? id;
  final int medicineId;
  final String medicineName;
  final String time;
  final List<String> daysOfWeek; // ['Mon', 'Tue', 'Wed', etc.]
  final bool isActive;
  final DateTime? lastNotifiedAt;
  final DateTime? createdAt;

  Reminder({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
    this.lastNotifiedAt,
    this.createdAt,
  });

  Reminder copyWith({
    int? id,
    int? medicineId,
    String? medicineName,
    String? time,
    List<String>? daysOfWeek,
    bool? isActive,
    DateTime? lastNotifiedAt,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'time': time,
      'daysOfWeek': daysOfWeek.join(','), // Store as comma-separated string
      'isActive': isActive ? 1 : 0,
      'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      medicineName: map['medicineName'] as String,
      time: map['time'] as String,
      daysOfWeek: (map['daysOfWeek'] as String?)?.split(',') ?? [],
      isActive: (map['isActive'] as int?) == 1,
      lastNotifiedAt: map['lastNotifiedAt'] != null
          ? DateTime.parse(map['lastNotifiedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Reminder($medicineName at $time on ${daysOfWeek.join(", ")})';
}

