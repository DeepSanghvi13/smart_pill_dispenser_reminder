import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const int _maxInt32 = 2147483647;
  static void Function(String payload)? _payloadHandler;

  static int _safeNowNotificationId() {
    return DateTime.now().millisecondsSinceEpoch & _maxInt32;
  }

  // Vibration pattern for alarms
  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 500, 250, 500]);

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
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const AndroidNotificationChannel _caretakerChannel =
      AndroidNotificationChannel(
    'caretaker_alerts',
    'Caretaker Alerts',
    description: 'Notifications related to caretaker actions and alerts.',
    importance: Importance.high,
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
    await androidImplementation?.createNotificationChannel(_caretakerChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && _payloadHandler != null) {
          _payloadHandler!(payload);
        }
      },
    );
  }

  static void setPayloadHandler(void Function(String payload)? handler) {
    _payloadHandler = handler;
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
    await androidImplementation?.requestExactAlarmsPermission();
  }

  /// Schedule daily medication alarm with sound + vibration.
  static Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
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
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      vibrationPattern: _vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedule weekly medication alarm with sound + vibration.
  static Future<void> scheduleWeeklyAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      vibrationPattern: _vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
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

    final reminders = <Duration>[
      const Duration(days: 7),
      const Duration(days: 1)
    ];

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
        audioAttributesUsage: AudioAttributesUsage.alarm,
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

  /// Caretaker alert for missed medicine.
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
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _notifications.show(
      _safeNowNotificationId(),
      'Medicine Missed',
      'Your ${relationship.toLowerCase()} missed: $medicine',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Confirmation shown when caretaker is added/saved.
  static Future<void> showCaretakerSavedNotification({
    required String fullName,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'caretaker_alerts',
      'Caretaker Alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    await _notifications.show(
      _safeNowNotificationId(),
      'Caretaker saved',
      '$fullName has been added successfully.',
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
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      vibrationPattern: _vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _notifications.show(
      _safeNowNotificationId(),
      'Medication Time: $medicineName',
      'Take $medicineDosage now',
      NotificationDetails(android: androidDetails),
      payload: 'alarm:$medicineName:$medicineDosage',
    );
  }

  /// Show expiry warning notification for medicines expiring soon or expired
  static Future<void> showExpiryWarningAlert({
    required String medicineName,
    required String expiryDate,
    required int daysLeft,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final String title = daysLeft < 0
        ? '⚠️ Medicine Expired: $medicineName'
        : '⚠️ Expiry Warning: $medicineName';
    final String body = daysLeft < 0
        ? '$medicineName expired on $expiryDate. Please do not consume and safely replace it.'
        : '$medicineName will expire in $daysLeft day${daysLeft == 1 ? '' : 's'} (on $expiryDate).';

    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    await _notifications.show(
      _safeNowNotificationId(),
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: 'expiry:$medicineName:$expiryDate',
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _notifications.cancel(id);
  }
}
