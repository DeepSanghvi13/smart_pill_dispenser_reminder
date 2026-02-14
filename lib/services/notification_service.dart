import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  /// 🔔 Notification + ⏰ Alarm at SAME TIME
  static Future<void> scheduleAlarmNotification({
    required DateTime dateTime,
  }) async {
    if (!Platform.isAndroid) {
      // Windows/Web fallback: notification only
      await _notifications.show(
        0,
        'Medication Reminder',
        'Time to take your medicine',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'basic_channel',
            'Basic Notifications',
            importance: Importance.max,
          ),
        ),
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Medication Alarms',
      importance: Importance.max,
      priority: Priority.high,

      // 🔊 THIS IS THE KEY PART
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    await _notifications.zonedSchedule(
      0,
      'Medication Alarm',
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
