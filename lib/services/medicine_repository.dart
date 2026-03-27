import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/alarm_log.dart';
import '../models/user_profile.dart';
import '../models/caretaker.dart';
import '../models/missed_medicine_alert.dart';
import 'database_service.dart';

/// Repository pattern for clean data access
class MedicineRepository {
  final DatabaseService _dbService = DatabaseService();

  // ============= MEDICINE OPERATIONS =============

  Future<int> addMedicine(Medicine medicine) => _dbService.addMedicine(medicine);

  Future<List<Medicine>> getAllMedicines() => _dbService.getAllMedicines();

  Future<Medicine?> getMedicineById(int id) => _dbService.getMedicineById(id);

  Future<int> updateMedicine(int id, Medicine medicine) =>
    _dbService.updateMedicine(id, medicine);

  Future<int> deleteMedicine(int id) => _dbService.deleteMedicine(id);

  // ============= REMINDER OPERATIONS =============

  Future<int> addReminder(Reminder reminder) => _dbService.addReminder(reminder);

  Future<List<Reminder>> getAllReminders() => _dbService.getAllReminders();

  Future<List<Reminder>> getActiveReminders() => _dbService.getActiveReminders();

  Future<List<Reminder>> getRemindersByMedicineId(int medicineId) =>
    _dbService.getRemindersByMedicineId(medicineId);

  Future<int> updateReminder(int id, Reminder reminder) =>
    _dbService.updateReminder(id, reminder);

  Future<int> deleteReminder(int id) => _dbService.deleteReminder(id);

  Future<int> toggleReminderStatus(int id, bool isActive) =>
    _dbService.toggleReminderStatus(id, isActive);

  // ============= ALARM LOG OPERATIONS =============

  Future<int> logAlarm(AlarmLog log) => _dbService.logAlarm(log);

  Future<List<AlarmLog>> getAllAlarmLogs() => _dbService.getAllAlarmLogs();

  Future<List<AlarmLog>> getAlarmLogsByMedicineId(int medicineId) =>
    _dbService.getAlarmLogsByMedicineId(medicineId);

  Future<List<AlarmLog>> getTodayAlarmLogs() => _dbService.getTodayAlarmLogs();

  Future<int> updateAlarmLogStatus(int id, String status,
    {int? snoozeCount, DateTime? takenAt}) =>
    _dbService.updateAlarmLogStatus(id, status, snoozeCount: snoozeCount, takenAt: takenAt);

  Future<int> incrementSnoozeCount(int id) => _dbService.incrementSnoozeCount(id);

  Future<int> markAlarmAsTaken(int id) => _dbService.markAlarmAsTaken(id);

  Future<int> markAlarmAsMissed(int id) => _dbService.markAlarmAsMissed(id);

  Future<List<AlarmLog>> getTodayMissedAlarms() => _dbService.getTodayMissedAlarms();

  // ============= USER PROFILE OPERATIONS =============

  Future<int> saveUserProfile(UserProfile profile) =>
    _dbService.saveUserProfile(profile);

  Future<UserProfile?> getUserProfile() => _dbService.getUserProfileData();

  // ============= CARETAKER OPERATIONS =============

  Future<int> addCaretaker(Caretaker caretaker) => _dbService.addCaretaker(caretaker);

  Future<List<Caretaker>> getAllCaretakers() => _dbService.getAllCaretakers();

  Future<List<Caretaker>> getActiveCaretakers() => _dbService.getActiveCaretakers();

  Future<int> updateCaretaker(int id, Caretaker caretaker) =>
    _dbService.updateCaretaker(id, caretaker);

  Future<int> deleteCaretaker(int id) => _dbService.deleteCaretaker(id);

  Future<int> toggleCaretakerStatus(int id, bool isActive) =>
    _dbService.toggleCaretakerStatus(id, isActive);

  // ============= MISSED MEDICINE ALERTS =============

  Future<int> logMissedAlert(MissedMedicineAlert alert) =>
    _dbService.logMissedAlert(alert);

  Future<List<MissedMedicineAlert>> getMissedAlerts() =>
    _dbService.getMissedAlerts();

  Future<List<MissedMedicineAlert>> getPendingAlerts() =>
    _dbService.getPendingAlerts();

  Future<int> updateAlertStatus(int id, String status, int count) =>
    _dbService.updateAlertStatus(id, status, count);

  // ============= SETTINGS OPERATIONS =============

  Future<void> saveSetting(String key, String value) =>
    _dbService.saveSetting(key, value);

  Future<String?> getSetting(String key) => _dbService.getSetting(key);

  Future<Map<String, String>> getAllSettings() => _dbService.getAllSettings();
}


