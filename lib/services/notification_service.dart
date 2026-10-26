import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'hive_service.dart';
import '../models/reminder.dart';

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

  static final Map<String, String> _timezoneMap = {
    'UTC': 'UTC',
    'EST': 'America/New_York',
    'CST': 'America/Chicago',
    'MST': 'America/Denver',
    'PST': 'America/Los_Angeles',
    'GMT': 'Europe/London',
    'CET': 'Europe/Paris',
    'IST': 'Asia/Kolkata',
    'AEST': 'Australia/Sydney',
  };

  static void setTimezone(String? timezoneCode) {
    if (timezoneCode == null || timezoneCode.isEmpty) return;
    try {
      final ianaName = _timezoneMap[timezoneCode.toUpperCase()] ?? timezoneCode;
      final location = tz.getLocation(ianaName);
      tz.setLocalLocation(location);
    } catch (_) {}
  }

  static bool get soundEnabled {
    try {
      return HiveService().settingsBox.get('notification_sound', defaultValue: true) as bool;
    } catch (_) {
      return true;
    }
  }

  static bool get vibrationEnabled {
    try {
      return HiveService().settingsBox.get('notification_vibrate', defaultValue: true) as bool;
    } catch (_) {
      return true;
    }
  }

  static bool get ledLightEnabled {
    try {
      return HiveService().settingsBox.get('notification_led', defaultValue: true) as bool;
    } catch (_) {
      return true;
    }
  }

  static Future<void> updatePreferences({
    bool? sound,
    bool? vibrate,
    bool? ledLight,
    String? timezone,
  }) async {
    final settings = HiveService().settingsBox;
    if (sound != null) await settings.put('notification_sound', sound);
    if (vibrate != null) await settings.put('notification_vibrate', vibrate);
    if (ledLight != null) await settings.put('notification_led', ledLight);
    if (timezone != null) {
      await settings.put('app_timezone', timezone);
      setTimezone(timezone);
    }
  }

  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final savedTz = HiveService().settingsBox.get('app_timezone') as String?;
      if (savedTz != null) {
        setTimezone(savedTz);
      }
    } catch (_) {}

    // Skip notification initialization on web platform
    if (kIsWeb) {
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(_defaultChannel);
      await androidImplementation?.createNotificationChannel(_alarmChannel);
      await androidImplementation?.createNotificationChannel(_caretakerChannel);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

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
    if (kIsWeb) {
      return;
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      final mac = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await mac?.requestPermissions(alert: true, badge: true, sound: true);
    }
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

  static int _mapDayToWeekday(String day) {
    final d = day.trim().toLowerCase();
    if (d.startsWith('mon')) return DateTime.monday;
    if (d.startsWith('tue')) return DateTime.tuesday;
    if (d.startsWith('wed')) return DateTime.wednesday;
    if (d.startsWith('thu')) return DateTime.thursday;
    if (d.startsWith('fri')) return DateTime.friday;
    if (d.startsWith('sat')) return DateTime.saturday;
    if (d.startsWith('sun')) return DateTime.sunday;
    return -1;
  }

  static DateTime _nextInstanceOfDayAndTime(int targetWeekday, int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedule recurring notifications for a Reminder across all selected days of week
  static Future<void> scheduleReminderNotifications(Reminder reminder) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (reminder.id == null || !reminder.isActive || reminder.daysOfWeek.isEmpty) return;

    // Parse time
    int hour = 9;
    int minute = 0;
    final cleanTime = reminder.time.trim();
    final timeFormats = [
      DateFormat('h:mm a'),
      DateFormat('hh:mm a'),
      DateFormat('H:mm'),
      DateFormat('HH:mm'),
    ];
    bool parsed = false;
    for (final f in timeFormats) {
      try {
        final dt = f.parse(cleanTime);
        hour = dt.hour;
        minute = dt.minute;
        parsed = true;
        break;
      } catch (_) {}
    }
    if (!parsed) {
      final parts = cleanTime.split(':');
      if (parts.length >= 2) {
        try {
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
        } catch (_) {}
      }
    }

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

    for (final dayStr in reminder.daysOfWeek) {
      final weekday = _mapDayToWeekday(dayStr);
      if (weekday == -1) continue;

      final scheduledDate = _nextInstanceOfDayAndTime(weekday, hour, minute);
      final notificationId = 200000 + (reminder.id! * 10) + weekday;

      await _notifications.zonedSchedule(
        notificationId,
        'Medication Reminder',
        'Time to take ${reminder.medicineName}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: jsonEncode({
          'type': 'reminder',
          'id': reminder.id,
          'medicineId': reminder.medicineId,
          'medicineName': reminder.medicineName,
          'time': reminder.time,
        }),
      );
    }
  }

  /// Cancel all scheduled weekday notifications for a reminder
  static Future<void> cancelReminderNotifications(int reminderId) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    await cancelNotification(200000 + (reminderId * 10));
    for (int weekday = 1; weekday <= 7; weekday++) {
      await cancelNotification(200000 + (reminderId * 10) + weekday);
    }
  }

  /// Cancel all scheduled alarms and reminders for a specific medicine
  static Future<void> cancelNotificationsForMedicine(int medicineId) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    final baseId = 1000 + (medicineId.abs() % 100000);
    // Cancel slots up to 30 doses
    for (int i = 0; i < 30; i++) {
      await cancelNotification(baseId * 10 + i);
      await cancelNotification(baseId * 100 + i);
      await cancelNotification(100000 + (medicineId % 9000) * 10 + i);
    }
    // Also cancel expiry notifications for this medicine
    for (int i = 0; i < 5; i++) {
      await cancelNotification(100000 + (medicineId * 10) + i);
    }
    // And query pending notification requests to cancel any with matching payload
    try {
      final pending = await _notifications.pendingNotificationRequests();
      for (final req in pending) {
        if (req.payload != null) {
          try {
            final data = jsonDecode(req.payload!);
            if (data is Map &&
                (data['id'] == medicineId || data['medicineId'] == medicineId)) {
              await cancelNotification(req.id);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // ===== GENERAL PREFERENCE REMINDERS =====

  static const int morningReminderNotificationId = 500001;
  static const int eveningReminderNotificationId = 500002;
  static const int weekendReminderBaseNotificationId = 500010;

  static Future<void> scheduleDailyPreferenceReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      enableLights: ledLightEnabled,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyPreferenceReminder(int id) async {
    await cancelNotification(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    await _notifications.cancel(id);
  }
}
