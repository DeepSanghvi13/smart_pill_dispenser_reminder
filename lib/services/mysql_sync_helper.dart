// ignore_for_file: avoid_print

import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';
import 'mysql_api_service.dart';

/// Fire-and-forget helpers — call these after every local DB write.
/// Errors are silently swallowed so they never block the UI.
class MySQLSyncHelper {
  static final MySQLApiService _api = MySQLApiService();

  // ---- medicines ----
  static void syncMedicine(Medicine medicine) {
    _api.syncMedicine(medicine).catchError((e) {
      print('[MySQL] syncMedicine failed: $e');
      return false;
    });
  }

  static void deleteMedicine(int id) {
    _api.deleteMedicineFromServer(id).catchError((e) {
      print('[MySQL] deleteMedicine failed: $e');
      return false;
    });
  }

  // ---- reminders ----
  static void syncReminder(Reminder reminder) {
    _api.saveReminderToServer(reminder).catchError((e) {
      print('[MySQL] syncReminder failed: $e');
      return false;
    });
  }

  // ---- alarm logs ----
  static void syncAlarmLog(AlarmLog log) {
    _api.logAlarmToServer(log).catchError((e) {
      print('[MySQL] syncAlarmLog failed: $e');
      return false;
    });
  }

  // ---- caretakers ----
  static void syncCaretaker(Caretaker caretaker) {
    _api.saveCaretakerToServer(caretaker).catchError((e) {
      print('[MySQL] syncCaretaker failed: $e');
      return false;
    });
  }

  // ---- user profile ----
  static void syncUserProfile(UserProfile profile) {
    _api.saveUserProfileToServer(profile).catchError((e) {
      print('[MySQL] syncUserProfile failed: $e');
      return false;
    });
  }

  /// Bulk sync — call this once after login or on app resume.
  static Future<bool> syncAll({
    required String userId,
    required List<Medicine> medicines,
    required List<Reminder> reminders,
    required List<AlarmLog> alarmLogs,
    required List<Caretaker> caretakers,
    UserProfile? userProfile,
  }) async {
    _api.configure(userId: userId);
    try {
      return await _api.syncAllDataToServer(
        medicines: medicines,
        userProfile: userProfile,
        caretakers: caretakers,
        alarmLogs: alarmLogs,
        reminders: reminders,
        userId: userId,
      );
    } catch (e) {
      print('[MySQL] syncAll failed: $e');
      return false;
    }
  }
}
<<<<<<< HEAD

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
