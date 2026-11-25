import 'dart:convert';

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
    List<String> parsedDays = [];
    final rawDays = map['daysOfWeek'];
    if (rawDays is List) {
      parsedDays = rawDays.map((d) => d.toString()).toList();
    } else if (rawDays is String) {
      if (rawDays.startsWith('[') && rawDays.endsWith(']')) {
        try {
          final decoded = jsonDecode(rawDays);
          if (decoded is List) {
            parsedDays = decoded.map((d) => d.toString()).toList();
          }
        } catch (_) {
          parsedDays = rawDays.replaceAll(RegExp(r'[\[\]"]'), '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      } else {
        parsedDays = rawDays.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    final rawIsActive = map['isActive'];
    final bool active = rawIsActive is bool
        ? rawIsActive
        : (rawIsActive is num ? rawIsActive == 1 : (rawIsActive?.toString() == 'true' || rawIsActive?.toString() == '1'));

    return Reminder(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      medicineId: map['medicineId'] is int
          ? map['medicineId'] as int
          : int.tryParse(map['medicineId']?.toString() ?? '') ?? 0,
      medicineName: map['medicineName']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      daysOfWeek: parsedDays,
      isActive: active,
      lastNotifiedAt: map['lastNotifiedAt'] != null
          ? DateTime.tryParse(map['lastNotifiedAt'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  @override
  String toString() =>
      'Reminder($medicineName at $time on ${daysOfWeek.join(", ")})';
}
