// ignore_for_file: avoid_print

import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/missed_medicine_alert.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';
import 'mysql_api_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static String _currentUserId = 'guest';
  static final MySQLApiService _apiService = MySQLApiService();

  final List<Map<String, dynamic>> _notificationHistory =
      <Map<String, dynamic>>[];
  final List<MissedMedicineAlert> _missedAlerts = <MissedMedicineAlert>[];
  final Map<String, Map<String, dynamic>> _barcodeCache =
      <String, Map<String, dynamic>>{};
  final Map<String, String> _settingsCache = <String, String>{};

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  String get currentUserId => _currentUserId;

  static String _normalizeUserId(String? userId) {
    final value = userId?.trim().toLowerCase() ?? '';
    return value.isEmpty ? 'guest' : value;
  }

  Future<void> _ensureConnected() async {
    _apiService.configure(userId: _currentUserId);
    final connected = await _apiService.checkServerConnection();
    if (!connected) {
      throw StateError('Mongo API is not reachable');
    }
  }

  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = _normalizeUserId(userId);
    _apiService.configure(userId: _currentUserId);
  }

  Future<void> initializeHiveBoxes() async {
    // Compatibility no-op: project now uses Mongo API only.
  }

  Future<void> get database async {
    await _ensureConnected();
  }

  Future<int> _nextMedicineId() async {
    final medicines = await getAllMedicines();
    var maxId = 0;
    for (final item in medicines) {
      if ((item.id ?? 0) > maxId) maxId = item.id!;
    }
    return maxId + 1;
  }

  Future<int> _nextReminderId() async {
    final reminders = await getAllReminders();
    var maxId = 0;
    for (final item in reminders) {
      if ((item.id ?? 0) > maxId) maxId = item.id!;
    }
    return maxId + 1;
  }

  Future<int> _nextCaretakerId() async {
    final caretakers = await getAllCaretakers();
    var maxId = 0;
    for (final item in caretakers) {
      if ((item.id ?? 0) > maxId) maxId = item.id!;
    }
    return maxId + 1;
  }

  Future<int> _nextAlarmLogId() async {
    final logs = await getAllAlarmLogs();
    var maxId = 0;
    for (final item in logs) {
      if ((item.id ?? 0) > maxId) maxId = item.id!;
    }
    return maxId + 1;
  }

  Future<int> addMedicine(Medicine medicine) async {
    final id = await _apiService.createMedicineOnServer(medicine);
    if (id == null || id <= 0) {
      throw StateError('Failed to save medicine to MongoDB API');
    }
    return id;
  }

  Future<List<Medicine>> getAllMedicines() async {
    await _ensureConnected();
    return _apiService.getMedicinesFromServer();
  }

  Future<Medicine?> getMedicineById(int id) async {
    final medicines = await getAllMedicines();
    for (final medicine in medicines) {
      if (medicine.id == id) return medicine;
    }
    return null;
  }

  Future<int> updateMedicine(int id, Medicine medicine) async {
    await _ensureConnected();
    final ok = await _apiService.updateMedicineOnServer(id, medicine);
    return ok ? 1 : 0;
  }

  Future<int> deleteMedicine(int id) async {
    await _ensureConnected();
    final ok = await _apiService.deleteMedicineFromServer(id);
    return ok ? 1 : 0;
  }

  Future<void> saveSetting(String key, String value) async {
    await _ensureConnected();
    final ok = await _apiService.saveSettingToServer(key, value);
    if (ok) {
      _settingsCache[key] = value;
    }
  }

  Future<String?> getSetting(String key) async {
    final all = await getAllSettings();
    return all[key];
  }

  Future<Map<String, String>> getAllSettings() async {
    await _ensureConnected();
    final server = await _apiService.getSettingsFromServer();
    if (server.isNotEmpty) {
      _settingsCache
        ..clear()
        ..addAll(server);
    }
    return Map<String, String>.from(_settingsCache);
  }

  Future<int> logNotification(
    int medicineId,
    DateTime scheduledTime, {
    bool taken = false,
  }) async {
    final id = _notificationHistory.length + 1;
    _notificationHistory.add({
      'id': id,
      'medicineId': medicineId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'sentTime': DateTime.now().toIso8601String(),
      'taken': taken ? 1 : 0,
    });
    return id;
  }

  Future<int> markNotificationAsTaken(int notificationId) async {
    final index =
        _notificationHistory.indexWhere((item) => item['id'] == notificationId);
    if (index < 0) return 0;
    _notificationHistory[index]['taken'] = 1;
    return 1;
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    return List<Map<String, dynamic>>.from(_notificationHistory.reversed);
  }

  Future<int> addDependent({
    required String firstName,
    required String lastName,
    String? gender,
    String? birthDate,
    String? color,
  }) async {
    await _ensureConnected();
    final all = await _apiService.getDependentsFromServer();
    var maxId = 0;
    for (final dependent in all) {
      final id = dependent['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    final nextId = maxId + 1;

    final ok = await _apiService.saveDependentToServer({
      'id': nextId,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthDate': birthDate,
      'color': color,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ok ? nextId : 0;
  }

  Future<List<Map<String, dynamic>>> getAllDependents() async {
    await _ensureConnected();
    return _apiService.getDependentsFromServer();
  }

  Future<int> deleteDependent(int id) async {
    await _ensureConnected();
    final ok = await _apiService.deleteDependentFromServer(id);
    return ok ? 1 : 0;
  }

  Future<int> addCaretaker(Caretaker caretaker) async {
    await _ensureConnected();
    final id = caretaker.id ?? await _nextCaretakerId();
    final ok =
        await _apiService.saveCaretakerToServer(caretaker.copyWith(id: id));
    return ok ? id : 0;
  }

  Future<List<Caretaker>> getAllCaretakers() async {
    await _ensureConnected();
    return _apiService.getCaretakersFromServer();
  }

  Future<List<Caretaker>> getActiveCaretakers() async {
    final all = await getAllCaretakers();
    return all.where((c) => c.isActive).toList();
  }

  Future<int> updateCaretaker(int id, Caretaker caretaker) async {
    await _ensureConnected();
    final ok =
        await _apiService.saveCaretakerToServer(caretaker.copyWith(id: id));
    return ok ? 1 : 0;
  }

  Future<int> deleteCaretaker(int id) async {
    await _ensureConnected();
    final ok = await _apiService.deleteCaretakerFromServer(id);
    return ok ? 1 : 0;
  }

  Future<int> toggleCaretakerStatus(int id, bool isActive) async {
    final all = await getAllCaretakers();
    final target = all.where((c) => c.id == id).toList();
    if (target.isEmpty) return 0;
    final updated = target.first.copyWith(isActive: isActive);
    return updateCaretaker(id, updated);
  }

  Future<int> logMissedAlert(MissedMedicineAlert alert) async {
    final id = (_missedAlerts.isEmpty
            ? 0
            : _missedAlerts.map((a) => a.id ?? 0).reduce(
                (value, element) => value > element ? value : element)) +
        1;
    _missedAlerts.add(alert.copyWith(id: id));
    return id;
  }

  Future<List<MissedMedicineAlert>> getMissedAlerts() async {
    return List<MissedMedicineAlert>.from(_missedAlerts.reversed);
  }

  Future<List<MissedMedicineAlert>> getPendingAlerts() async {
    return _missedAlerts.where((a) => a.status == 'pending').toList();
  }

  Future<int> updateAlertStatus(int id, String status, int count) async {
    final index = _missedAlerts.indexWhere((a) => a.id == id);
    if (index < 0) return 0;
    _missedAlerts[index] = _missedAlerts[index].copyWith(
      status: status,
      notificationSent: true,
      caretakersNotified: count,
    );
    return 1;
  }

  Future<int> addReminder(Reminder reminder) async {
    await _ensureConnected();
    final id = reminder.id ?? await _nextReminderId();
    final ok =
        await _apiService.saveReminderToServer(reminder.copyWith(id: id));
    return ok ? id : 0;
  }

  Future<List<Reminder>> getAllReminders() async {
    await _ensureConnected();
    return _apiService.getRemindersFromServer();
  }

  Future<List<Reminder>> getActiveReminders() async {
    final all = await getAllReminders();
    return all.where((r) => r.isActive).toList();
  }

  Future<List<Reminder>> getRemindersByMedicineId(int medicineId) async {
    final all = await getAllReminders();
    return all.where((r) => r.medicineId == medicineId).toList();
  }

  Future<int> updateReminder(int id, Reminder reminder) async {
    await _ensureConnected();
    final ok =
        await _apiService.saveReminderToServer(reminder.copyWith(id: id));
    return ok ? 1 : 0;
  }

  Future<int> deleteReminder(int id) async {
    await _ensureConnected();
    final ok = await _apiService.deleteReminderFromServer(id);
    return ok ? 1 : 0;
  }

  Future<int> toggleReminderStatus(int id, bool isActive) async {
    final all = await getAllReminders();
    final target = all.where((r) => r.id == id).toList();
    if (target.isEmpty) return 0;
    final updated = target.first.copyWith(isActive: isActive);
    return updateReminder(id, updated);
  }

  Future<int> logAlarm(AlarmLog log) async {
    await _ensureConnected();
    final id = log.id ?? await _nextAlarmLogId();
    final ok = await _apiService.logAlarmToServer(log.copyWith(id: id));
    return ok ? id : 0;
  }

  Future<List<AlarmLog>> getAllAlarmLogs() async {
    await _ensureConnected();
    return _apiService.getAlarmLogsFromServer();
  }

  Future<List<AlarmLog>> getAlarmLogsByMedicineId(int medicineId) async {
    final all = await getAllAlarmLogs();
    return all.where((a) => a.medicineId == medicineId).toList();
  }

  Future<List<AlarmLog>> getTodayAlarmLogs() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final all = await getAllAlarmLogs();
    return all
        .where((a) =>
            !a.scheduledTime.isBefore(start) && a.scheduledTime.isBefore(end))
        .toList();
  }

  Future<int> updateAlarmLogStatus(
    int id,
    String status, {
    int? snoozeCount,
    DateTime? takenAt,
  }) async {
    final all = await getAllAlarmLogs();
    final target = all.where((a) => a.id == id).toList();
    if (target.isEmpty) return 0;
    final updated = target.first.copyWith(
      status: status,
      snoozeCount: snoozeCount,
      takenAt: takenAt,
    );
    await _ensureConnected();
    final ok = await _apiService.logAlarmToServer(updated);
    return ok ? 1 : 0;
  }

  Future<int> incrementSnoozeCount(int id) async {
    final all = await getAllAlarmLogs();
    final target = all.where((a) => a.id == id).toList();
    if (target.isEmpty) return 0;
    final current = target.first;
    final updated = current.copyWith(snoozeCount: current.snoozeCount + 1);
    await _ensureConnected();
    final ok = await _apiService.logAlarmToServer(updated);
    return ok ? 1 : 0;
  }

  Future<int> markAlarmAsTaken(int id) async {
    return updateAlarmLogStatus(
      id,
      'taken',
      takenAt: DateTime.now(),
    );
  }

  Future<int> markAlarmAsMissed(int id) async {
    return updateAlarmLogStatus(id, 'missed');
  }

  Future<List<AlarmLog>> getTodayMissedAlarms() async {
    final today = await getTodayAlarmLogs();
    return today.where((a) => a.status == 'missed').toList();
  }

  Future<Map<String, dynamic>?> getBarcodeLookupCache(String barcode) async {
    final key = barcode.trim();
    if (key.isEmpty) return null;
    return _barcodeCache[key];
  }

  Future<void> upsertBarcodeLookupCache({
    required String barcode,
    required String name,
    required String dosage,
    required String category,
  }) async {
    final key = barcode.trim();
    if (key.isEmpty) return;
    _barcodeCache[key] = {
      'barcode': key,
      'name': name,
      'dosage': dosage,
      'category': category,
      'cachedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<int> saveUserProfile(UserProfile profile) async {
    await _ensureConnected();
    final ok = await _apiService.saveUserProfileToServer(profile);
    return ok ? 1 : 0;
  }

  Future<UserProfile?> getUserProfileData() async {
    await _ensureConnected();
    return _apiService.getUserProfileFromServer(_currentUserId);
  }

  Future<int> registerUser(String email, String password) async {
    await _ensureConnected();
    final ok = await _apiService.registerUser(email, password);
    return ok ? 1 : 0;
  }

  Future<Map<String, String>> getRegisteredUsers() async {
    // Credentials are server-managed now; no local credential map.
    return <String, String>{};
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await _apiService.getAdminSqlEntries();
    if (data == null) return <Map<String, dynamic>>[];
    final users = data['users'] as List<dynamic>? ?? const <dynamic>[];
    return users.whereType<Map<String, dynamic>>().toList();
  }

  Future<int> updateUser(int id, {String? email, String? passwordHash}) async {
    // No direct user update endpoint in API.
    return 0;
  }

  Future<int> deleteUser(int id) async {
    // No direct user delete endpoint in API.
    return 0;
  }

  Future<void> clearAllData() async {
    final medicines = await getAllMedicines();
    for (final medicine in medicines) {
      if (medicine.id != null) {
        await deleteMedicine(medicine.id!);
      }
    }

    final reminders = await getAllReminders();
    for (final reminder in reminders) {
      if (reminder.id != null) {
        await deleteReminder(reminder.id!);
      }
    }

    final caretakers = await getAllCaretakers();
    for (final caretaker in caretakers) {
      if (caretaker.id != null) {
        await deleteCaretaker(caretaker.id!);
      }
    }

    final dependents = await getAllDependents();
    for (final dependent in dependents) {
      final id = dependent['id'] as int?;
      if (id != null) {
        await deleteDependent(id);
      }
    }

    _notificationHistory.clear();
    _missedAlerts.clear();
    _barcodeCache.clear();
    _settingsCache.clear();
  }

  Future<void> closeDatabase() async {
    // Compatibility no-op: API client is shared and disposed by owner.
  }
}
