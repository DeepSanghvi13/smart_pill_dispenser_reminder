import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

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

  static Future<void> init() async {
    tz.initializeTimeZones();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create the channel
    await androidImplementation?.createNotificationChannel(_defaultChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  /// 🔔 Default Notification Reminder
  static Future<void> scheduleAlarmNotification({
    required DateTime dateTime,
  }) async {
    // Use the default channel id as defined above
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    await _notifications.zonedSchedule(
      0,
      'Medication Reminder',
      'Time to take your medicine',
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
