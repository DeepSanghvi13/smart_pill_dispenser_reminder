class NotificationService {

  /// Counter for fake notification IDs (demo purpose)
  static int _counter = 0;

  /// Initialize notifications
  static Future<void> init() async {
    print("Notification service initialized");
  }

  /// Request notification permissions
  static Future<void> requestPermissions() async {
    print("Notification permissions granted");
  }

  /// Schedule new notification
  static Future<int> scheduleNotification(dynamic medicine) async {

    int notificationId = _counter++;

    print(
        "Scheduled notification for ${medicine.name} with ID $notificationId");

    return notificationId;
  }

  /// Cancel notification
  static Future<void> cancelNotification(int? id) async {

    if (id == null) return;

    print("Cancelled notification ID $id");
  }

  /// ⭐ IMPORTANT — Restore alarm from database
  static Future<void> scheduleNotificationFromDB(
      Map<String, dynamic> medicine) async {

    final String name = medicine['medicine_name'];
    final String time = medicine['reminder_time'];
    final int? notificationId = medicine['notification_id'];

    print(
        "Restoring alarm -> Name: $name | Time: $time | ID: $notificationId");

    // Here you will add real notification scheduling later
  }

  /// Snooze feature
  static Future<void> snoozeNotification(String medicineName) async {

    print("Snooze pressed for $medicineName (10 minutes delay)");
  }
}
