enum MedicineCategory {
  tablets('Tablets', '💊'),
  syrup('Syrup', '🧴'),
  injection('Injection', '💉');

  final String label;
  final String emoji;

  const MedicineCategory(this.label, this.emoji);

  /// Get category from string
  static MedicineCategory fromString(String value) {
    return MedicineCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicineCategory.tablets,
    );
  }
}

class Medicine {
  final int? id; // Database ID (null for new medicines)
  final String name;
  final String dosage;
  final String time;
  final MedicineCategory category;
  final DateTime? expiryDate;
  final bool isScanned;
  final String? scannedText;
  final String? imagePath;
  final String? healthCondition;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.category = MedicineCategory.tablets,
    this.expiryDate,
    this.isScanned = false,
    this.scannedText,
    this.imagePath,
    this.healthCondition,
  });

  /// Create a copy of Medicine with modified fields
  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? time,
    MedicineCategory? category,
    DateTime? expiryDate,
    bool? isScanned,
    String? scannedText,
    String? imagePath,
    String? healthCondition,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      isScanned: isScanned ?? this.isScanned,
      scannedText: scannedText ?? this.scannedText,
      imagePath: imagePath ?? this.imagePath,
      healthCondition: healthCondition ?? this.healthCondition,
    );
  }

  /// Convert Medicine to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'category': category.name,
      'expiryDate': expiryDate?.toIso8601String(),
      'isScanned': isScanned ? 1 : 0,
      'scannedText': scannedText,
      'imagePath': imagePath,
      'healthCondition': healthCondition,
    };
  }

  /// Create Medicine from database Map
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      time: map['time'] as String,
      category: MedicineCategory.fromString(map['category'] as String? ?? 'tablets'),
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'] as String)
          : null,
      isScanned: (map['isScanned'] as int? ?? 0) == 1,
      scannedText: map['scannedText'] as String?,
      imagePath: map['imagePath'] as String?,
      healthCondition: map['healthCondition'] as String?,
    );
  }
}

