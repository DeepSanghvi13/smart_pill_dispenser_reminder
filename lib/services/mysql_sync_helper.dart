import 'mysql_api_service.dart';
import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';

/// Fire-and-forget sync helper connecting local operations to MySQL backend.
class MySQLSyncHelper {
  static Future<void> syncMedicine(Medicine medicine) async {
    await MySQLApiService().createMedicineOnServer(medicine);
  }

  static Future<void> updateMedicine(int id, Medicine medicine) async {
    await MySQLApiService().updateMedicineOnServer(id, medicine);
  }

  static Future<void> deleteMedicine(int id, {String? userId}) async {
    await MySQLApiService().deleteMedicineFromServer(id, userId: userId);
  }

  static Future<void> syncReminder(Reminder reminder, {String? userId}) async {
    await MySQLApiService().createOrUpdateReminderOnServer(reminder, userId: userId);
  }

  static Future<void> deleteReminder(int id, {String? userId}) async {
    await MySQLApiService().deleteReminderFromServer(id, userId: userId);
  }

  static Future<void> syncAlarmLog(AlarmLog log, {String? userId}) async {
    await MySQLApiService().logAlarmToServer(log, userId: userId);
  }

  static void syncCaretaker(Caretaker caretaker) {
    MySQLApiService().saveCaretakerToServer(caretaker);
  }

  static void syncUserProfile(UserProfile profile) {
    MySQLApiService().saveUserProfileToServer(profile);
  }

  static Future<bool> syncAll({
    required String userId,
    required List<Medicine> medicines,
    required List<Reminder> reminders,
    required List<AlarmLog> alarmLogs,
    required List<Caretaker> caretakers,
    UserProfile? userProfile,
  }) async {
    return MySQLApiService().syncAllDataToServer(
      medicines: medicines,
      userProfile: userProfile,
      caretakers: caretakers,
      alarmLogs: alarmLogs,
      reminders: reminders,
      userId: userId,
    );
  }
}
