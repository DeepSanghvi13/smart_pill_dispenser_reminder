import 'package:url_launcher/url_launcher.dart';
import 'database_service.dart';
import 'notification_service.dart';
import '../models/caretaker.dart';
import '../models/missed_medicine_alert.dart';

class CaretakerService {
  static final CaretakerService _instance = CaretakerService._internal();
  final DatabaseService _db = DatabaseService();

  factory CaretakerService() => _instance;
  CaretakerService._internal();

  /// Notify caretakers of missed medicine
  Future<void> notifyMissedMedicine({
    required int medicineId,
    required String medicineName,
    required DateTime scheduledTime,
  }) async {
    try {
      final caretakers = await _db.getActiveCaretakers();
      if (caretakers.isEmpty) return;

      final alert = MissedMedicineAlert(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        detectedTime: DateTime.now(),
        status: 'pending',
      );

      final alertId = await _db.logMissedAlert(alert);
      int count = 0;

      for (final caretaker in caretakers) {
        await _notifyCaretaker(caretaker, medicineName);
        count++;
      }

      await _db.updateAlertStatus(alertId, 'notified', count);
      print('✅ Notified $count caretakers about $medicineName');
    } catch (e) {
      print('❌ Error notifying caretakers: $e');
    }
  }

  /// Send notification to individual caretaker
  Future<void> _notifyCaretaker(Caretaker caretaker, String medicineName) async {
    try {
      if (caretaker.notifyViaNotification) {
        await NotificationService.showCaretakerAlert(
          name: caretaker.fullName,
          medicine: medicineName,
          relationship: caretaker.relationship,
        );
      }
      if (caretaker.notifyViaSMS) {
        await _sendSMS(caretaker.phoneNumber, medicineName, caretaker.relationship);
      }
      if (caretaker.notifyViaEmail) {
        await _sendEmail(caretaker.email, medicineName, caretaker.relationship);
      }
    } catch (e) {
      print('Error notifying ${caretaker.fullName}: $e');
    }
  }

  /// Send SMS alert
  Future<void> _sendSMS(String phone, String medicine, String relationship) async {
    try {
      final msg = Uri.encodeComponent(
        '⚠️ ALERT: Your $relationship missed medicine: $medicine\n\n'
        'Time: ${DateTime.now()}\n\n'
        'Please follow up!'
      );
      final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': msg});
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      print('SMS error: $e');
    }
  }

  /// Send email alert
  Future<void> _sendEmail(String email, String medicine, String relationship) async {
    try {
      final subject = Uri.encodeComponent('⚠️ Missed Medicine Alert');
      final body = Uri.encodeComponent(
        'Your $relationship missed their medicine!\n\n'
        'Medicine: $medicine\n'
        'Time: ${DateTime.now()}\n\n'
        'Please contact them immediately.'
      );
      final uri = Uri(scheme: 'mailto', path: email,
        queryParameters: {'subject': subject, 'body': body});
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      print('Email error: $e');
    }
  }

  // Caretaker management
  Future<int> addCaretaker(Caretaker c) => _db.addCaretaker(c);
  Future<List<Caretaker>> getAllCaretakers() => _db.getAllCaretakers();
  Future<List<Caretaker>> getActiveCaretakers() => _db.getActiveCaretakers();
  Future<int> updateCaretaker(int id, Caretaker c) => _db.updateCaretaker(id, c);
  Future<int> deleteCaretaker(int id) => _db.deleteCaretaker(id);
  Future<int> toggleStatus(int id, bool isActive) => _db.toggleCaretakerStatus(id, isActive);

  // Alert management
  Future<List<MissedMedicineAlert>> getMissedAlerts() => _db.getMissedAlerts();
  Future<List<MissedMedicineAlert>> getPendingAlerts() => _db.getPendingAlerts();
}

