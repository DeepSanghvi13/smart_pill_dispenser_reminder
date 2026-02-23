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

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.category = MedicineCategory.tablets,
  });

  /// Create a copy of Medicine with modified fields
  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? time,
    MedicineCategory? category,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      category: category ?? this.category,
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
    );
  }
}
