class Medicine {
  final String name;
  final String dosage;
  final String time;

  Medicine({
    required this.name,
    required this.dosage,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'time': time,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      dosage: json['dosage'],
      time: json['time'],
    );
  }
}
