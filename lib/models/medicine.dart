import 'package:intl/intl.dart';

enum MedicineCategory {
  tablets('Tablets', 'tablet'),
  syrup('Syrup', 'syrup'),
  injection('Injection', 'injection');

  final String label;
  final String emoji;

  const MedicineCategory(this.label, this.emoji);

  /// Get category from string
  static MedicineCategory fromString(String value) {
    return MedicineCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => MedicineCategory.tablets,
    );
  }
}

class Medicine {
  final int? id; // Numeric ID for notifications and unique identification
  final String userId; // Belongs to user email
  final String name;
  final String type; // tablets, syrup, injection, etc.
  final String dosage;
  final String quantity; // Quantity (e.g. 2 pills, 10ml)
  final String frequency; // Frequency (e.g. Daily, Weekly)
  final String time; // Scheduled time (e.g. 08:00 AM)
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final String status; // 'pending', 'taken', 'skipped'
  final String? lastActionDate; // YYYY-MM-DD for daily progress

  // Caretaker audit fields
  final String patientId; // Scoped patient email
  final String createdBy; // Email of the user who added
  final String updatedBy; // Email of the user who updated
  final DateTime createdAt;
  final DateTime updatedAt;

  // Compatibility flags
  final bool isScanned;
  final String? scannedText;
  final String? imagePath;
  final String? healthCondition;

  Medicine({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.dosage,
    required this.quantity,
    required this.frequency,
    required this.time,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.status = 'pending',
    this.lastActionDate,
    String? patientId,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isScanned = false,
    this.scannedText,
    this.imagePath,
    this.healthCondition,
  })  : patientId = patientId ?? userId,
        createdBy = createdBy ?? userId,
        updatedBy = updatedBy ?? userId,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Compatibility getter for category
  MedicineCategory get category => MedicineCategory.fromString(type);

  /// Compatibility getter for expiryDate
  DateTime get expiryDate => endDate;

  /// Compatibility getter for medicineId
  int? get medicineId => id;

  Medicine copyWith({
    int? id,
    String? userId,
    String? name,
    String? type,
    String? dosage,
    String? quantity,
    String? frequency,
    String? time,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? status,
    String? lastActionDate,
    String? patientId,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isScanned,
    String? scannedText,
    String? imagePath,
    String? healthCondition,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      lastActionDate: lastActionDate ?? this.lastActionDate,
      patientId: patientId ?? this.patientId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isScanned: isScanned ?? this.isScanned,
      scannedText: scannedText ?? this.scannedText,
      imagePath: imagePath ?? this.imagePath,
      healthCondition: healthCondition ?? this.healthCondition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'quantity': quantity,
      'frequency': frequency,
      'time': time,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'lastActionDate': lastActionDate,
      'patientId': patientId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isScanned': isScanned ? 1 : 0,
      'scannedText': scannedText,
      'imagePath': imagePath,
      'healthCondition': healthCondition,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    final userIdVal = map['userId'] as String? ?? '';
    return Medicine(
      id: map['id'] as int?,
      userId: userIdVal,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'Tablets',
      dosage: map['dosage'] as String? ?? '',
      quantity: map['quantity'] as String? ?? '1',
      frequency: map['frequency'] as String? ?? 'Daily',
      time: map['time'] as String? ?? '',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'pending',
      lastActionDate: map['lastActionDate'] as String?,
      patientId: map['patientId'] as String? ?? map['userId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? map['userId'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? map['userId'] as String? ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      isScanned: (map['isScanned'] as int? ?? 0) == 1,
      scannedText: map['scannedText'] as String?,
      imagePath: map['imagePath'] as String?,
      healthCondition: map['healthCondition'] as String?,
    );
  }

  String getDailyStatus() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (lastActionDate == todayStr) {
      return status;
    }
    return 'pending';
  }
}
