import 'mysql_api_service.dart';
import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';

/// Fire-and-forget sync helper connecting local operations to MySQL backend.
class MySQLSyncHelper {
  static void syncMedicine(Medicine medicine) {
    MySQLApiService().createMedicineOnServer(medicine);
  }

  static void deleteMedicine(int id) {
    MySQLApiService().deleteMedicineFromServer(id);
  }

  static void syncReminder(Reminder reminder) {
    // Reminders are synced with medicine schedules
  }

  static void syncAlarmLog(AlarmLog log) {
    MySQLApiService().logAlarmToServer(log);
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
