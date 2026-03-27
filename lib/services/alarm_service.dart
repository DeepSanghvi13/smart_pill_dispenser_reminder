import 'dart:async';
import 'package:flutter/foundation.dart';

class AlarmService extends ChangeNotifier {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() {
    return _instance;
  }

  AlarmService._internal();

  // Alarm state
  bool _isAlarmActive = false;
  DateTime? _alarmTriggeredTime;
  String _currentMedicineId = '';
  String _currentMedicineName = '';
  String _currentMedicineDosage = '';
  Timer? _snoozeTimer;
  int _snoozeMinutesRemaining = 0;

  // Getters
  bool get isAlarmActive => _isAlarmActive;
  DateTime? get alarmTriggeredTime => _alarmTriggeredTime;
  String get currentMedicineId => _currentMedicineId;
  String get currentMedicineName => _currentMedicineName;
  String get currentMedicineDosage => _currentMedicineDosage;
  int get snoozeMinutesRemaining => _snoozeMinutesRemaining;

  /// Trigger an alarm for a specific medicine
  void triggerAlarm({
    required String medicineId,
    required String medicineName,
    required String medicineDosage,
  }) {
    _isAlarmActive = true;
    _alarmTriggeredTime = DateTime.now();
    _currentMedicineId = medicineId;
    _currentMedicineName = medicineName;
    _currentMedicineDosage = medicineDosage;
    _snoozeMinutesRemaining = 0;
    _cancelSnoozeTimer();
    notifyListeners();
  }

  /// Snooze the alarm for a specified duration (in minutes)
  void snoozeAlarm(int minutes) {
    _snoozeMinutesRemaining = minutes;
    _cancelSnoozeTimer();

    _snoozeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_snoozeMinutesRemaining > 0) {
        _snoozeMinutesRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        // Resume alarm after snooze ends
        _alarmTriggeredTime = DateTime.now();
        notifyListeners();
      }
    });

    // Also set a timer to re-trigger the alarm
    Timer(Duration(minutes: minutes), () {
      if (_isAlarmActive && _snoozeMinutesRemaining == 0) {
        _alarmTriggeredTime = DateTime.now();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Stop the alarm completely
  void stopAlarm() {
    _isAlarmActive = false;
    _alarmTriggeredTime = null;
    _currentMedicineId = '';
    _currentMedicineName = '';
    _currentMedicineDosage = '';
    _snoozeMinutesRemaining = 0;
    _cancelSnoozeTimer();
    notifyListeners();
  }

  /// Cancel snooze timer if running
  void _cancelSnoozeTimer() {
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
  }

  /// Format remaining snooze time as MM:SS
  String getSnoozeTimeFormatted() {
    int totalSeconds = _snoozeMinutesRemaining * 60;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _cancelSnoozeTimer();
    super.dispose();
  }
}

<<<<<<< HEAD

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
