import 'dart:async';
import 'package:flutter/foundation.dart';
import 'caretaker_service.dart';

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
  final Map<String, Timer> _scheduledTimers = {};
  Timer? _missedAlarmTimer;

  // Getters
  bool get isAlarmActive => _isAlarmActive;
  DateTime? get alarmTriggeredTime => _alarmTriggeredTime;
  String get currentMedicineId => _currentMedicineId;
  String get currentMedicineName => _currentMedicineName;
  String get currentMedicineDosage => _currentMedicineDosage;

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
    _scheduleMissedAlert();
    notifyListeners();
  }

  /// Schedule a daily in-app alarm for when the app is running.
  void scheduleDailyAlarm({
    required String medicineId,
    required String medicineName,
    required String medicineDosage,
    required int hour,
    required int minute,
  }) {
    if (medicineId.isEmpty) {
      return;
    }

    _cancelScheduledAlarm(medicineId);

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    final delay = next.difference(now);
    _scheduledTimers[medicineId] = Timer(delay, () {
      triggerAlarm(
        medicineId: medicineId,
        medicineName: medicineName,
        medicineDosage: medicineDosage,
      );

      scheduleDailyAlarm(
        medicineId: medicineId,
        medicineName: medicineName,
        medicineDosage: medicineDosage,
        hour: hour,
        minute: minute,
      );
    });
  }

  void cancelScheduledAlarm(String medicineId) {
    _cancelScheduledAlarm(medicineId);
  }

  void cancelAllScheduledAlarms() {
    for (final timer in _scheduledTimers.values) {
      timer.cancel();
    }
    _scheduledTimers.clear();
  }

  /// Stop the alarm completely
  void stopAlarm() {
    _isAlarmActive = false;
    _alarmTriggeredTime = null;
    _currentMedicineId = '';
    _currentMedicineName = '';
    _currentMedicineDosage = '';
    _cancelMissedAlert();
    notifyListeners();
  }

  void _cancelScheduledAlarm(String medicineId) {
    _scheduledTimers.remove(medicineId)?.cancel();
  }

  void _scheduleMissedAlert() {
    _cancelMissedAlert();

    const threshold = Duration(minutes: 10);
    _missedAlarmTimer = Timer(threshold, () {
      if (!_isAlarmActive) {
        return;
      }

      final parsedId = int.tryParse(_currentMedicineId);
      if (parsedId == null) {
        return;
      }

      CaretakerService().notifyMissedMedicine(
        medicineId: parsedId,
        medicineName: _currentMedicineName,
        scheduledTime: _alarmTriggeredTime ?? DateTime.now(),
      );
    });
  }

  void _cancelMissedAlert() {
    _missedAlarmTimer?.cancel();
    _missedAlarmTimer = null;
  }

  @override
  void dispose() {
    _cancelMissedAlert();
    cancelAllScheduledAlarms();
    super.dispose();
  }
}
