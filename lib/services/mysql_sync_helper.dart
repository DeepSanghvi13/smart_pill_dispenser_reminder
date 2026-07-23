import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';

class MySQLSyncHelper {
  static void syncMedicine(Medicine medicine) {}
  static void deleteMedicine(int id) {}
  static void syncReminder(Reminder reminder) {}
  static void syncAlarmLog(AlarmLog log) {}
  static void syncCaretaker(Caretaker caretaker) {}
  static void syncUserProfile(UserProfile profile) {}

  static Future<bool> syncAll({
    required String userId,
    required List<Medicine> medicines,
    required List<Reminder> reminders,
    required List<AlarmLog> alarmLogs,
    required List<Caretaker> caretakers,
    UserProfile? userProfile,
  }) async {
    return true;
  }
}
