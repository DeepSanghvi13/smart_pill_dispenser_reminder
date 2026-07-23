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
    this.isScanned = false,
    this.scannedText,
    this.imagePath,
    this.healthCondition,
  });

  /// Compatibility getter for category
  MedicineCategory get category => MedicineCategory.fromString(type);

  /// Compatibility getter for expiryDate
  DateTime get expiryDate => endDate;

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
      'isScanned': isScanned ? 1 : 0,
      'scannedText': scannedText,
      'imagePath': imagePath,
      'healthCondition': healthCondition,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
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
