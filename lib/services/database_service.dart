import 'dart:convert';
import 'hive_service.dart';
import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/missed_medicine_alert.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static String _currentUserId = 'guest';

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  String get currentUserId => _currentUserId;

  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = userId?.trim().toLowerCase() ?? 'guest';
  }

  Future<void> initializeHiveBoxes() async {
    await HiveService.init();
  }

  Future<void> get database async {
    // Compatibility no-op
  }

  // ============= MEDICINE OPERATIONS =============

  Future<int> addMedicine(Medicine medicine) async {
    final box = HiveService().medicinesBox;
    
    // Find next numeric ID
    var maxId = 0;
    for (final m in box.values) {
      if (m.id != null && m.id! > maxId) {
        maxId = m.id!;
      }
    }
    final nextId = maxId + 1;
    
    final payload = medicine.copyWith(
      id: nextId,
      userId: _currentUserId,
    );
    await box.put(nextId, payload);
    return nextId;
  }

  Future<List<Medicine>> getAllMedicines() async {
    final box = HiveService().medicinesBox;
    return box.values.where((m) => m.userId == _currentUserId).toList();
  }

  Future<Medicine?> getMedicineById(int id) async {
    final box = HiveService().medicinesBox;
    final m = box.get(id);
    if (m != null && m.userId == _currentUserId) {
      return m;
    }
    return null;
  }

  Future<int> updateMedicine(int id, Medicine medicine) async {
    final box = HiveService().medicinesBox;
    final payload = medicine.copyWith(id: id, userId: _currentUserId);
    await box.put(id, payload);
    return 1;
  }

  Future<int> deleteMedicine(int id) async {
    final box = HiveService().medicinesBox;
    await box.delete(id);
    return 1;
  }

  // ============= USER PROFILE OPERATIONS =============

  Future<int> saveUserProfile(UserProfile profile) async {
    final box = HiveService().profilesBox;
    final payload = profile.copyWith(email: _currentUserId);
    await box.put(_currentUserId, payload);
    return 1;
  }

  Future<UserProfile?> getUserProfileData() async {
    final box = HiveService().profilesBox;
    return box.get(_currentUserId);
  }

  // ============= REMINDER OPERATIONS (Stored in Hive settings box for multi-user separation) =============

  String _remindersKey() => 'reminders_$_currentUserId';

  Future<List<Reminder>> getAllReminders() async {
    final settingsBox = HiveService().settingsBox;
    final raw = settingsBox.get(_remindersKey());
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw as String);
      return list.map((item) => Reminder.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveReminders(List<Reminder> reminders) async {
    final settingsBox = HiveService().settingsBox;
    final list = reminders.map((r) => r.toMap()).toList();
    await settingsBox.put(_remindersKey(), jsonEncode(list));
  }

  Future<int> addReminder(Reminder reminder) async {
    final all = await getAllReminders();
    var maxId = 0;
    for (final r in all) {
      if (r.id != null && r.id! > maxId) maxId = r.id!;
    }
    final nextId = maxId + 1;
    final payload = reminder.copyWith(id: nextId);
    all.add(payload);
    await _saveReminders(all);
    return nextId;
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
    final all = await getAllReminders();
    final index = all.indexWhere((r) => r.id == id);
    if (index >= 0) {
      all[index] = reminder.copyWith(id: id);
      await _saveReminders(all);
      return 1;
    }
    return 0;
  }

  Future<int> deleteReminder(int id) async {
    final all = await getAllReminders();
    all.removeWhere((r) => r.id == id);
    await _saveReminders(all);
    return 1;
  }

  Future<int> toggleReminderStatus(int id, bool isActive) async {
    final all = await getAllReminders();
    final index = all.indexWhere((r) => r.id == id);
    if (index >= 0) {
      all[index] = all[index].copyWith(isActive: isActive);
      await _saveReminders(all);
      return 1;
    }
    return 0;
  }

  // ============= ALARM LOG OPERATIONS =============

  String _alarmLogsKey() => 'alarmlogs_$_currentUserId';

  Future<List<AlarmLog>> getAllAlarmLogs() async {
    final settingsBox = HiveService().settingsBox;
    final raw = settingsBox.get(_alarmLogsKey());
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw as String);
      return list.map((item) => AlarmLog.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAlarmLogs(List<AlarmLog> logs) async {
    final settingsBox = HiveService().settingsBox;
    final list = logs.map((l) => l.toMap()).toList();
    await settingsBox.put(_alarmLogsKey(), jsonEncode(list));
  }

  Future<int> logAlarm(AlarmLog log) async {
    final all = await getAllAlarmLogs();
    var maxId = 0;
    for (final a in all) {
      if (a.id != null && a.id! > maxId) maxId = a.id!;
    }
    final nextId = maxId + 1;
    final payload = log.copyWith(id: nextId);
    all.add(payload);
    await _saveAlarmLogs(all);
    return nextId;
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
    final index = all.indexWhere((a) => a.id == id);
    if (index >= 0) {
      all[index] = all[index].copyWith(
        status: status,
        snoozeCount: snoozeCount,
        takenAt: takenAt,
      );
      await _saveAlarmLogs(all);
      return 1;
    }
    return 0;
  }

  Future<int> incrementSnoozeCount(int id) async {
    final all = await getAllAlarmLogs();
    final index = all.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final current = all[index];
      all[index] = current.copyWith(snoozeCount: current.snoozeCount + 1);
      await _saveAlarmLogs(all);
      return 1;
    }
    return 0;
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

  // ============= BARCODE LOOKUP CACHE OPERATIONS =============

  Future<Map<String, dynamic>?> getBarcodeLookupCache(String barcode) async {
    final settingsBox = HiveService().settingsBox;
    final raw = settingsBox.get('barcode_cache_${barcode.trim()}');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw as String));
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertBarcodeLookupCache({
    required String barcode,
    required String name,
    required String dosage,
    required String category,
    DateTime? expiryDate,
    String? healthCondition,
  }) async {
    final settingsBox = HiveService().settingsBox;
    final map = {
      'barcode': barcode.trim(),
      'name': name,
      'dosage': dosage,
      'category': category,
      'expiryDate': expiryDate?.toIso8601String(),
      'healthCondition': healthCondition,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await settingsBox.put('barcode_cache_${barcode.trim()}', jsonEncode(map));
  }

  // ============= SETTINGS PERSISTENCE =============

  Future<void> saveSetting(String key, String value) async {
    final settingsBox = HiveService().settingsBox;
    await settingsBox.put('$_currentUserId\_$key', value);
  }

  Future<String?> getSetting(String key) async {
    final settingsBox = HiveService().settingsBox;
    return settingsBox.get('$_currentUserId\_$key') as String?;
  }

  Future<Map<String, String>> getAllSettings() async {
    final settingsBox = HiveService().settingsBox;
    final result = <String, String>{};
    final prefix = '$_currentUserId\_';
    for (final key in settingsBox.keys) {
      if (key is String && key.startsWith(prefix)) {
        final val = settingsBox.get(key);
        if (val != null) {
          result[key.substring(prefix.length)] = val.toString();
        }
      }
    }
    return result;
  }

  // ============= OTHER SUPPORTING PERSISTENCE (Stubs/Local Helpers) =============

  Future<int> addCaretaker(Caretaker caretaker) async {
    final settingsBox = HiveService().settingsBox;
    final listRaw = settingsBox.get('caretakers_$_currentUserId');
    final List<Caretaker> list = [];
    if (listRaw != null) {
      try {
        final decoded = jsonDecode(listRaw as String) as List<dynamic>;
        list.addAll(decoded.map((item) => Caretaker.fromMap(Map<String, dynamic>.from(item))));
      } catch (_) {}
    }
    final nextId = list.length + 1;
    final payload = caretaker.copyWith(id: nextId);
    list.add(payload);
    await settingsBox.put('caretakers_$_currentUserId', jsonEncode(list.map((c) => c.toMap()).toList()));
    return nextId;
  }

  Future<List<Caretaker>> getAllCaretakers() async {
    final settingsBox = HiveService().settingsBox;
    final listRaw = settingsBox.get('caretakers_$_currentUserId');
    if (listRaw == null) return [];
    try {
      final decoded = jsonDecode(listRaw as String) as List<dynamic>;
      return decoded.map((item) => Caretaker.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Caretaker>> getActiveCaretakers() async {
    final all = await getAllCaretakers();
    return all.where((c) => c.isActive).toList();
  }

  Future<int> updateCaretaker(int id, Caretaker caretaker) async {
    final all = await getAllCaretakers();
    final index = all.indexWhere((c) => c.id == id);
    if (index >= 0) {
      all[index] = caretaker.copyWith(id: id);
      final settingsBox = HiveService().settingsBox;
      await settingsBox.put('caretakers_$_currentUserId', jsonEncode(all.map((c) => c.toMap()).toList()));
      return 1;
    }
    return 0;
  }

  Future<int> deleteCaretaker(int id) async {
    final all = await getAllCaretakers();
    all.removeWhere((c) => c.id == id);
    final settingsBox = HiveService().settingsBox;
    await settingsBox.put('caretakers_$_currentUserId', jsonEncode(all.map((c) => c.toMap()).toList()));
    return 1;
  }

  Future<int> toggleCaretakerStatus(int id, bool isActive) async {
    final all = await getAllCaretakers();
    final index = all.indexWhere((c) => c.id == id);
    if (index >= 0) {
      all[index] = all[index].copyWith(isActive: isActive);
      final settingsBox = HiveService().settingsBox;
      await settingsBox.put('caretakers_$_currentUserId', jsonEncode(all.map((c) => c.toMap()).toList()));
      return 1;
    }
    return 0;
  }

  Future<int> logMissedAlert(MissedMedicineAlert alert) async {
    return 1;
  }

  Future<List<MissedMedicineAlert>> getMissedAlerts() async {
    return [];
  }

  Future<List<MissedMedicineAlert>> getPendingAlerts() async {
    return [];
  }

  Future<int> updateAlertStatus(int id, String status, int count) async {
    return 1;
  }

  Future<int> addDependent({
    required String firstName,
    required String lastName,
    String? gender,
    String? birthDate,
    String? color,
  }) async {
    return 1;
  }

  Future<List<Map<String, dynamic>>> getAllDependents() async {
    return [];
  }

  Future<int> deleteDependent(int id) async {
    return 1;
  }

  Future<void> clearAllData() async {
    final box = HiveService().medicinesBox;
    final keys = box.keys.where((k) => box.get(k)?.userId == _currentUserId).toList();
    for (final k in keys) {
      await box.delete(k);
    }
    final settingsBox = HiveService().settingsBox;
    await settingsBox.delete(_remindersKey());
    await settingsBox.delete(_alarmLogsKey());
    await settingsBox.delete('caretakers_$_currentUserId');
  }

  Future<void> closeDatabase() async {
    // Compatibility no-op
  }
}
