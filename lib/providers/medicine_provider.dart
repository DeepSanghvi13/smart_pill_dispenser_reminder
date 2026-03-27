// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/alarm_log.dart';
import '../services/medicine_repository.dart';

/// Provider for managing Medicine data with error handling and loading states
class MedicineProvider extends ChangeNotifier {
  final MedicineRepository _repo = MedicineRepository();

  // State variables
  List<Medicine> _medicines = [];
  List<Reminder> _reminders = [];
  List<AlarmLog> _todayAlarms = [];
  List<AlarmLog> _missedAlarms = [];

  bool _loadingMedicines = false;
  bool _loadingReminders = false;
  bool _loadingAlarms = false;

  String? _error;

  // Getters
  List<Medicine> get medicines => _medicines;
  List<Reminder> get reminders => _reminders;
  List<AlarmLog> get todayAlarms => _todayAlarms;
  List<AlarmLog> get missedAlarms => _missedAlarms;

  bool get loadingMedicines => _loadingMedicines;
  bool get loadingReminders => _loadingReminders;
  bool get loadingAlarms => _loadingAlarms;

  String? get error => _error;

  bool get hasError => _error != null;

  // ============= MEDICINE OPERATIONS =============

  /// Load all medicines from database
  Future<void> loadMedicines() async {
    try {
      _loadingMedicines = true;
      _error = null;
      _medicines = await _repo.getAllMedicines();
    } catch (e) {
      _error = 'Failed to load medicines: $e';
      print(_error);
    } finally {
      _loadingMedicines = false;
      notifyListeners();
    }
  }

  /// Add a new medicine
  Future<int?> addMedicine(Medicine medicine) async {
    try {
      _error = null;
      final id = await _repo.addMedicine(medicine);
      await loadMedicines(); // Refresh list
      return id;
    } catch (e) {
      _error = 'Failed to add medicine: $e';
      print(_error);
      notifyListeners();
      return null;
    }
  }

  /// Update an existing medicine
  Future<bool> updateMedicine(int id, Medicine medicine) async {
    try {
      _error = null;
      await _repo.updateMedicine(id, medicine);
      await loadMedicines(); // Refresh list
      return true;
    } catch (e) {
      _error = 'Failed to update medicine: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete a medicine
  Future<bool> deleteMedicine(int id) async {
    try {
      _error = null;
      await _repo.deleteMedicine(id);
      await loadMedicines(); // Refresh list
      return true;
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Get medicine by ID
  Medicine? getMedicineById(int id) {
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============= REMINDER OPERATIONS =============

  /// Load all reminders
  Future<void> loadReminders() async {
    try {
      _loadingReminders = true;
      _error = null;
      _reminders = await _repo.getAllReminders();
    } catch (e) {
      _error = 'Failed to load reminders: $e';
      print(_error);
    } finally {
      _loadingReminders = false;
      notifyListeners();
    }
  }

  /// Add a new reminder
  Future<int?> addReminder(Reminder reminder) async {
    try {
      _error = null;
      final id = await _repo.addReminder(reminder);
      await loadReminders(); // Refresh list
      return id;
    } catch (e) {
      _error = 'Failed to add reminder: $e';
      print(_error);
      notifyListeners();
      return null;
    }
  }

  /// Update reminder
  Future<bool> updateReminder(int id, Reminder reminder) async {
    try {
      _error = null;
      await _repo.updateReminder(id, reminder);
      await loadReminders();
      return true;
    } catch (e) {
      _error = 'Failed to update reminder: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete reminder
  Future<bool> deleteReminder(int id) async {
    try {
      _error = null;
      await _repo.deleteReminder(id);
      await loadReminders();
      return true;
    } catch (e) {
      _error = 'Failed to delete reminder: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Toggle reminder active status
  Future<bool> toggleReminderStatus(int id, bool isActive) async {
    try {
      _error = null;
      await _repo.toggleReminderStatus(id, isActive);
      await loadReminders();
      return true;
    } catch (e) {
      _error = 'Failed to toggle reminder: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Get reminders for specific medicine
  List<Reminder> getRemindersByMedicineId(int medicineId) {
    return _reminders.where((r) => r.medicineId == medicineId).toList();
  }

  // ============= ALARM LOG OPERATIONS =============

  /// Load today's alarms
  Future<void> loadTodayAlarms() async {
    try {
      _loadingAlarms = true;
      _error = null;
      _todayAlarms = await _repo.getTodayAlarmLogs();
    } catch (e) {
      _error = 'Failed to load alarms: $e';
      print(_error);
    } finally {
      _loadingAlarms = false;
      notifyListeners();
    }
  }

  /// Load missed alarms
  Future<void> loadMissedAlarms() async {
    try {
      _error = null;
      _missedAlarms = await _repo.getTodayMissedAlarms();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load missed alarms: $e';
      print(_error);
      notifyListeners();
    }
  }

  /// Log a new alarm
  Future<int?> logAlarm(AlarmLog log) async {
    try {
      _error = null;
      final id = await _repo.logAlarm(log);
      await loadTodayAlarms(); // Refresh
      return id;
    } catch (e) {
      _error = 'Failed to log alarm: $e';
      print(_error);
      notifyListeners();
      return null;
    }
  }

  /// Mark alarm as taken
  Future<bool> markAlarmAsTaken(int id) async {
    try {
      _error = null;
      await _repo.markAlarmAsTaken(id);
      await loadTodayAlarms();
      await loadMissedAlarms();
      return true;
    } catch (e) {
      _error = 'Failed to mark as taken: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Mark alarm as missed
  Future<bool> markAlarmAsMissed(int id) async {
    try {
      _error = null;
      await _repo.markAlarmAsMissed(id);
      await loadTodayAlarms();
      await loadMissedAlarms();
      return true;
    } catch (e) {
      _error = 'Failed to mark as missed: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Snooze alarm
  Future<bool> snoozeAlarm(int id) async {
    try {
      _error = null;
      await _repo.incrementSnoozeCount(id);
      await _repo.updateAlarmLogStatus(id, 'snoozed');
      await loadTodayAlarms();
      return true;
    } catch (e) {
      _error = 'Failed to snooze alarm: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Get alarm by ID
  AlarmLog? getAlarmById(int id) {
    try {
      return _todayAlarms.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============= UTILITY METHODS =============

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reload all data
  Future<void> reloadAll() async {
    await Future.wait([
      loadMedicines(),
      loadReminders(),
      loadTodayAlarms(),
      loadMissedAlarms(),
    ]);
  }

  /// Get medicine count
  int get medicineCount => _medicines.length;

  /// Get reminder count
  int get reminderCount => _reminders.length;

  /// Get today's alarm count
  int get todayAlarmCount => _todayAlarms.length;

  /// Get missed alarm count
  int get missedAlarmCount => _missedAlarms.length;

  /// Get pending alarms (triggered but not taken)
  List<AlarmLog> get pendingAlarms {
    return _todayAlarms.where((a) => a.status == 'triggered').toList();
  }

  /// Get taken alarms
  List<AlarmLog> get takenAlarms {
    return _todayAlarms.where((a) => a.status == 'taken').toList();
  }

  /// Get snoozed alarms
  List<AlarmLog> get snoozedAlarms {
    return _todayAlarms.where((a) => a.status == 'snoozed').toList();
  }
}

