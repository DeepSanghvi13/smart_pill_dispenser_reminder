class Medicine {
  final int? id; // Database ID (null for new medicines)
  final String name;
  final String dosage;
  final String time;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
  });

  /// Create a copy of Medicine with modified fields
  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? time,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
    );
  }

  /// Convert Medicine to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
    };
  }

  /// Create Medicine from database Map
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      time: map['time'] as String,
    );
  }
}
