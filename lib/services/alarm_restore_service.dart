import 'database_service.dart';
import 'notification_service.dart';

class AlarmRestoreService {

  static Future<void> restoreAllAlarms() async {

    // Load medicines from database
    final List<Map<String, dynamic>> medicines =
    await DatabaseService().getMedicines();

    // Loop and restore alarms
    for (final Map<String, dynamic> m in medicines) {

      await NotificationService.scheduleNotificationFromDB(m);
    }
  }
}
