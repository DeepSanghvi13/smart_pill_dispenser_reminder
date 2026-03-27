import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Vibration pattern for alarms
  static final Int64List _vibrationPattern = Int64List.fromList([0, 500, 250, 500]);

  // Define the channel with default settings
  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'default_channel', // id
    'Default Notifications', // title
    description: 'This channel is used for medication reminders.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Alarm channel for high-priority alarms
  static const AndroidNotificationChannel _alarmChannel =
      AndroidNotificationChannel(
    'alarm_channel', // id
    'Alarm Notifications', // title
    description: 'This channel is used for medication alarm notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    tz.initializeTimeZones();

    // Skip notification initialization on web platform
    if (kIsWeb) {
      return;
    }

    // Skip if not Android
    if (!Platform.isAndroid) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create both notification channels
    await androidImplementation?.createNotificationChannel(_defaultChannel);
    await androidImplementation?.createNotificationChannel(_alarmChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  static Future<void> requestPermissions() async {
    // Skip on web platform
    if (kIsWeb) {
      return;
    }

    // Only request permissions on Android
    if (!Platform.isAndroid) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  /// Schedule daily medication alarm with sound + vibration.
  static Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    // Skip notification scheduling on web platform
    if (kIsWeb) {
      return;
    }

    // Skip if not Android
    if (!Platform.isAndroid) {
      return;
    }

    // Use the alarm channel id
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule expiry reminders at 7 days and 1 day before expiry.
  static Future<void> scheduleExpiryNotifications({
    required int medicineId,
    required String medicineName,
    required DateTime expiryDate,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    final reminders = <Duration>[const Duration(days: 7), const Duration(days: 1)];

    for (var index = 0; index < reminders.length; index++) {
      final reminderDate = expiryDate.subtract(reminders[index]);
      final scheduledDate = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9,
      );
      if (scheduledDate.isBefore(DateTime.now())) {
        continue;
      }

      final id = 100000 + (medicineId * 10) + index;
      final androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        vibrationPattern: _vibrationPattern,
      );

      await _notifications.zonedSchedule(
        id,
        'Expiry Reminder',
        '$medicineName expires on ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// ðŸ‘¨â€âš•ï¸ Caretaker alert for missed medicine
  static Future<void> showCaretakerAlert({
    required String name,
    required String medicine,
    required String relationship,
  }) async {
    // Skip notification on web platform
    if (kIsWeb) {
      return;
    }

    // Skip if not Android
    if (!Platform.isAndroid) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'caretaker_alerts',
      'Caretaker Alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      'âš ï¸ Medicine Missed',
      'Your ${relationship.toLowerCase()} missed: $medicine',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Show immediate alarm notification for medication
  static Future<void> showImmediateAlarm({
    required String medicineName,
    required String medicineDosage,
  }) async {
    // Skip notification on web platform
    if (kIsWeb) {
      return;
    }

    // Skip if not Android
    if (!Platform.isAndroid) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      vibrationPattern: _vibrationPattern,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      'Medication Time: $medicineName',
      'Take $medicineDosage now',
      NotificationDetails(android: androidDetails),
      payload: 'alarm:$medicineName:$medicineDosage',
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by ID
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}

