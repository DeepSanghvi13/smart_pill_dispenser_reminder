class Medicine {

  int? id;
  String name;
  String dosage;
  String time;
  int? notificationId;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.notificationId,
  });

  Map<String,dynamic> toMap(){
    return {
      'id': id,
      'medicine_name': name,
      'dosage': dosage,
      'reminder_time': time,
      'notification_id': notificationId
    };
  }

  factory Medicine.fromMap(Map map){
    return Medicine(
      id: map['id'],
      name: map['medicine_name'],
      dosage: map['dosage'],
      time: map['reminder_time'],
      notificationId: map['notification_id'],
    );
  }
}
