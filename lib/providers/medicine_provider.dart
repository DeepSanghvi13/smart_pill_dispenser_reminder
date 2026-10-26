import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/alarm_log.dart';
import '../services/medicine_repository.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../services/database_service.dart';

class MedicineProvider extends ChangeNotifier {
  final MedicineRepository _repo = MedicineRepository();

  List<Medicine> _medicines = [];
  List<Reminder> _reminders = [];
  List<AlarmLog> _todayAlarms = [];
  List<AlarmLog> _missedAlarms = [];

  bool _loadingMedicines = false;
  bool _loadingReminders = false;
  bool _loadingAlarms = false;

  String? _error;

  String? _activePatientId;

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

  String? get activePatientId => _activePatientId;

  void setActivePatient(String? patientId) {
    _activePatientId = patientId;
    DatabaseService().setActivePatient(patientId);
    reloadAll();
  }

  // ============= MEDICINE OPERATIONS =============

  Future<void> loadMedicines() async {
    try {
      _loadingMedicines = true;
      _error = null;
      _medicines = await _repo.getAllMedicines();
    } catch (e) {
      _error = 'Failed to load medicines: $e';
    } finally {
      _loadingMedicines = false;
      notifyListeners();
    }
  }

  Future<int?> addMedicine(Medicine medicine) async {
    try {
      _error = null;
      final id = await _repo.addMedicine(medicine);
      if (id > 0) {
        final newMed = medicine.copyWith(id: id);
        _medicines.add(newMed);
        
        // Schedule notification automatically
        await _scheduleNotificationForMedicine(newMed);
      }
      notifyListeners();
      return id;
    } catch (e) {
      _error = 'Failed to add medicine: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateMedicine(int id, Medicine medicine) async {
    try {
      _error = null;
      await _repo.updateMedicine(id, medicine);
      final index = _medicines.indexWhere((m) => m.id == id);
      final updatedMed = medicine.copyWith(id: id);
      if (index >= 0) {
        _medicines[index] = updatedMed;
      } else {
        _medicines.add(updatedMed);
      }

      // Reschedule notification automatically
      await _cancelNotificationForMedicine(id);
      await _scheduleNotificationForMedicine(updatedMed);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update medicine: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicine(int id) async {
    try {
      _error = null;
      await _repo.deleteMedicine(id);
      _medicines.removeWhere((m) => m.id == id);

      // Cancel notification automatically
      await _cancelNotificationForMedicine(id);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
      notifyListeners();
      return false;
    }
  }

  Medicine? getMedicineById(int id) {
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============= DAILY STATUS OPERATIONS =============

  Future<void> markAsTaken(Medicine medicine) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final updated = medicine.copyWith(
      status: 'taken',
      lastActionDate: todayStr,
    );
    if (medicine.id != null) {
      await updateMedicine(medicine.id!, updated);
    }
  }

  Future<void> skipMedicine(Medicine medicine) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final updated = medicine.copyWith(
      status: 'skipped',
      lastActionDate: todayStr,
    );
    if (medicine.id != null) {
      await updateMedicine(medicine.id!, updated);
    }
  }

  List<Medicine> searchMedicines(String query) {
    if (query.trim().isEmpty) return _medicines;
    return _medicines
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ============= NOTIFICATION HELPERS =============

  DateTime? _parseTimeString(String raw) {
    final clean = raw.trim();
    final formats = [
      DateFormat('h:mm a'),
      DateFormat('hh:mm a'),
      DateFormat('H:mm'),
      DateFormat('HH:mm'),
    ];
    for (final format in formats) {
      try {
        return format.parse(clean);
      } catch (_) {}
    }
    final parts = clean.split(':');
    if (parts.length >= 2) {
      try {
        final hour = int.parse(parts[0]);
        final minStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        final minute = int.parse(minStr);
        return DateTime(2000, 1, 1, hour, minute);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _scheduleNotificationForMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    try {
      // 1. If treatment duration has ended, do not schedule; cancel any remaining alarms
      if (medicine.isTreatmentCompleted) {
        await _cancelNotificationForMedicine(medicine.id!);
        return;
      }

      final freq = medicine.frequency.trim().toLowerCase();
      if (freq == 'as needed') {
        // Do not schedule recurring alarms for "As needed"
        return;
      }

      // First cancel all previous notifications for this medicine to prevent stale slots
      await _cancelNotificationForMedicine(medicine.id!);

      final times = medicine.doseTimes.isNotEmpty ? medicine.doseTimes : [medicine.time];
      final now = DateTime.now();
      final startDay = DateTime(medicine.startDate.year, medicine.startDate.month, medicine.startDate.day);
      final endDay = DateTime(medicine.endDate.year, medicine.endDate.month, medicine.endDate.day, 23, 59, 59);

      for (int i = 0; i < times.length; i++) {
        final parsedTime = _parseTimeString(times[i]);
        if (parsedTime == null) continue;

        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        // If the medication start date is in the future, start scheduling from the start date
        final scheduleDay = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
        if (scheduleDay.isBefore(startDay)) {
          scheduledDate = DateTime(
            startDay.year,
            startDay.month,
            startDay.day,
            parsedTime.hour,
            parsedTime.minute,
          );
        }

        // If scheduled date is past the prescribed treatment end date, do not schedule
        if (scheduledDate.isAfter(endDay)) {
          continue;
        }

        final doseLabel = times.length > 1 ? ' (Dose ${i + 1})' : '';
        // Explicit segregated ID range for medicine alarms: 100000..189999
        final notificationId = 100000 + ((medicine.id! % 8000) * 10) + (i % 10);

        if (freq == 'weekly') {
          await NotificationService.scheduleWeeklyAlarmNotification(
            id: notificationId,
            title: 'Medication Reminder (Weekly)$doseLabel',
            body: 'Time to take ${medicine.name} (${medicine.dosage})',
            dateTime: scheduledDate,
            payload: jsonEncode({
              'type': 'alarm',
              'id': medicine.id,
              'name': medicine.name,
              'dosage': medicine.dosage,
              'doseIndex': i,
            }),
          );
        } else {
          await NotificationService.scheduleAlarmNotification(
            id: notificationId,
            title: 'Medication Reminder$doseLabel',
            body: 'Time to take ${medicine.name} (${medicine.dosage})',
            dateTime: scheduledDate,
            payload: jsonEncode({
              'type': 'alarm',
              'id': medicine.id,
              'name': medicine.name,
              'dosage': medicine.dosage,
              'doseIndex': i,
            }),
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelNotificationForMedicine(int medicineId) async {
    try {
      await NotificationService.cancelNotificationsForMedicine(medicineId);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  // ============= REMINDER OPERATIONS =============

  Future<void> loadReminders() async {
    try {
      _loadingReminders = true;
      _error = null;
      _reminders = await _repo.getAllReminders();
    } catch (e) {
      _error = 'Failed to load reminders: $e';
    } finally {
      _loadingReminders = false;
      notifyListeners();
    }
  }

  Future<int?> addReminder(Reminder reminder) async {
    try {
      _error = null;
      final id = await _repo.addReminder(reminder);
      await loadReminders();
      return id;
    } catch (e) {
      _error = 'Failed to add reminder: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateReminder(int id, Reminder reminder) async {
    try {
      _error = null;
      await _repo.updateReminder(id, reminder);
      await loadReminders();
      return true;
    } catch (e) {
      _error = 'Failed to update reminder: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReminder(int id) async {
    try {
      _error = null;
      await _repo.deleteReminder(id);
      await loadReminders();
      return true;
    } catch (e) {
      _error = 'Failed to delete reminder: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleReminderStatus(int id, bool isActive) async {
    try {
      _error = null;
      await _repo.toggleReminderStatus(id, isActive);
      await loadReminders();
      return true;
    } catch (e) {
      _error = 'Failed to toggle reminder: $e';
      notifyListeners();
      return false;
    }
  }

  // ============= ALARM LOG OPERATIONS =============

  Future<void> loadTodayAlarms() async {
    try {
      _loadingAlarms = true;
      _error = null;
      _todayAlarms = await _repo.getTodayAlarmLogs();
    } catch (e) {
      _error = 'Failed to load alarms: $e';
    } finally {
      _loadingAlarms = false;
      notifyListeners();
    }
  }

  Future<void> loadMissedAlarms() async {
    try {
      _error = null;
      _missedAlarms = await _repo.getTodayMissedAlarms();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load missed alarms: $e';
      notifyListeners();
    }
  }

  Future<int?> logAlarm(AlarmLog log) async {
    try {
      _error = null;
      final id = await _repo.logAlarm(log);
      await loadTodayAlarms();
      return id;
    } catch (e) {
      _error = 'Failed to log alarm: $e';
      notifyListeners();
      return null;
    }
  }

  // ============= CARETAKER ALERT LOGIC =============

  Future<void> checkMissedMedicinesAndNotifyCaretakers() async {
    final auth = AuthService();
    if (!auth.isLoggedIn || !auth.isCaretaker) return;

    final connectedPatients = auth.getConnectedPatients();
    final medicinesBox = HiveService().medicinesBox;
    final notificationsBox = HiveService().notificationsBox;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    for (final patient in connectedPatients) {
      final patientMeds = medicinesBox.values.where(
        (m) => m.patientId == patient.email || m.userId == patient.email
      );

      for (final med in patientMeds) {
        final clean = med.time.trim();
        final formats = [
          DateFormat('h:mm a'),
          DateFormat('hh:mm a'),
          DateFormat('H:mm'),
          DateFormat('HH:mm'),
        ];
        DateTime? parsedTime;
        for (final format in formats) {
          try {
            parsedTime = format.parse(clean);
            break;
          } catch (_) {}
        }

        if (parsedTime != null) {
          final medTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
          final difference = now.difference(medTime).inMinutes;
          
          final dailyStatus = med.getDailyStatus();
          // If medication was scheduled for today and is > 30 minutes past without action
          if (difference >= 30 && dailyStatus == 'pending') {
            final notifId = 'missed_${patient.email}_${med.id}_$todayStr';
            if (!notificationsBox.containsKey(notifId)) {
              final notif = {
                'notificationId': notifId,
                'patientId': patient.email,
                'patientName': patient.fullName,
                'medicineName': med.name,
                'scheduledTime': med.time,
                'createdAt': DateTime.now().toIso8601String(),
                'read': false,
              };
              await notificationsBox.put(notifId, notif);

              // Trigger Caretaker Alert
              await NotificationService.showCaretakerAlert(
                name: patient.fullName,
                medicine: med.name,
                relationship: patient.relationship ?? 'Patient',
              );
            }
          }
        }
      }
    }
  }

  // ============= UTILITY METHODS =============

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> checkExpiringMedicinesAndNotify() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationsBox = HiveService().notificationsBox;

    for (final med in _medicines) {
      final exp = med.resolvedExpiryDate;
      final expDay = DateTime(exp.year, exp.month, exp.day);
      final diffDays = expDay.difference(today).inDays;

      // 1. Medicine is already expired (< 0 days left)
      if (diffDays < 0) {
        final notifKey = 'expired_alert_${med.id}';
        // Alert only once when expired; do not repeatedly alert every day
        if (!notificationsBox.containsKey(notifKey)) {
          await notificationsBox.put(notifKey, {
            'type': 'expiry',
            'medicineId': med.id,
            'medicineName': med.name,
            'expiryDate': med.formattedExpiryDate,
            'daysLeft': diffDays,
            'status': 'expired',
            'createdAt': DateTime.now().toIso8601String(),
          });

          await NotificationService.showExpiryWarningAlert(
            medicineName: med.name,
            expiryDate: med.formattedExpiryDate,
            daysLeft: diffDays,
          );
        }
      }
      // 2. Medicine is expiring very soon (within next 7 days: 0 to 7 days)
      else if (diffDays <= 7) {
        // Milestone alerts: 7 days, 3 days, 1 day, and 0 days (day of expiry)
        final isMilestone = diffDays == 7 || diffDays == 3 || diffDays == 1 || diffDays == 0;
        if (isMilestone) {
          final notifKey = 'expiring_milestone_${med.id}_day_$diffDays';
          if (!notificationsBox.containsKey(notifKey)) {
            await notificationsBox.put(notifKey, {
              'type': 'expiry',
              'medicineId': med.id,
              'medicineName': med.name,
              'expiryDate': med.formattedExpiryDate,
              'daysLeft': diffDays,
              'status': 'expiring_soon',
              'createdAt': DateTime.now().toIso8601String(),
            });

            await NotificationService.showExpiryWarningAlert(
              medicineName: med.name,
              expiryDate: med.formattedExpiryDate,
              daysLeft: diffDays,
            );
          }
        }
      }
      // 3. Medicine is expiring within 30 days (8 to 30 days)
      else if (diffDays <= 30) {
        final notifKey = 'expiring_30d_${med.id}';
        // Notify once when entering the 30-day window
        if (!notificationsBox.containsKey(notifKey)) {
          await notificationsBox.put(notifKey, {
            'type': 'expiry',
            'medicineId': med.id,
            'medicineName': med.name,
            'expiryDate': med.formattedExpiryDate,
            'daysLeft': diffDays,
            'status': 'expiring_30d',
            'createdAt': DateTime.now().toIso8601String(),
          });

          await NotificationService.showExpiryWarningAlert(
            medicineName: med.name,
            expiryDate: med.formattedExpiryDate,
            daysLeft: diffDays,
          );
        }
      }
    }
  }

  Future<void> reloadAll() async {
    await Future.wait([
      loadMedicines(),
      loadReminders(),
      loadTodayAlarms(),
      loadMissedAlarms(),
    ]);
    await checkMissedMedicinesAndNotifyCaretakers();
    await checkExpiringMedicinesAndNotify();
  }
}