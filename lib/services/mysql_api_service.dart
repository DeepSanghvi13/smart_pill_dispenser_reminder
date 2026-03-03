import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../models/caretaker.dart';
import '../models/reminder.dart';
import '../models/alarm_log.dart';

class MySQLApiService {
  static final MySQLApiService _instance = MySQLApiService._internal();

  // ⭐ CHANGE THIS TO YOUR SERVER URL
  static const String baseUrl = 'http://your-server.com/api';

  // Alternative if using localhost
  // static const String baseUrl = 'http://192.168.x.x:3000/api'; // Change IP

  late http.Client _client;

  factory MySQLApiService() {
    return _instance;
  }

  MySQLApiService._internal() {
    _client = http.Client();
  }

  // ============= MEDICINES =============

  /// Sync medicines to MySQL
  Future<bool> syncMedicine(Medicine medicine) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'id': medicine.id,
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'category': medicine.category.name,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error syncing medicine: $e');
      return false;
    }
  }

  /// Get all medicines from MySQL
  Future<List<Medicine>> getMedicinesFromServer() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/medicines'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body)['data'] ?? [];
        return jsonData
            .map((item) => Medicine(
                  id: item['id'],
                  name: item['name'],
                  dosage: item['dosage'],
                  time: item['time'],
                  category: MedicineCategory.fromString(item['category'] ?? 'tablets'),
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching medicines: $e');
      return [];
    }
  }

  /// Update medicine on server
  Future<bool> updateMedicineOnServer(int id, Medicine medicine) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/medicines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'category': medicine.category.name,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating medicine: $e');
      return false;
    }
  }

  /// Delete medicine from server
  Future<bool> deleteMedicineFromServer(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/medicines/$id'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting medicine: $e');
      return false;
    }
  }

  // ============= USER PROFILE =============

  /// Save user profile to server
  Future<bool> saveUserProfileToServer(UserProfile profile) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'gender': profile.gender,
          'birthDate': profile.birthDate,
          'zipCode': profile.zipCode,
          'phoneNumber': profile.phoneNumber,
          'email': profile.email,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  /// Get user profile from server
  Future<UserProfile?> getUserProfileFromServer(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/user-profile/$userId'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return UserProfile(
          firstName: data['firstName'],
          lastName: data['lastName'],
          gender: data['gender'],
          birthDate: data['birthDate'],
          zipCode: data['zipCode'],
          phoneNumber: data['phoneNumber'],
          email: data['email'],
        );
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // ============= CARETAKERS =============

  /// Save caretaker to server
  Future<bool> saveCaretakerToServer(Caretaker caretaker) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/caretakers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'firstName': caretaker.firstName,
          'lastName': caretaker.lastName,
          'phoneNumber': caretaker.phoneNumber,
          'email': caretaker.email,
          'relationship': caretaker.relationship,
          'notifyViaSMS': caretaker.notifyViaSMS,
          'notifyViaEmail': caretaker.notifyViaEmail,
          'notifyViaNotification': caretaker.notifyViaNotification,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error saving caretaker: $e');
      return false;
    }
  }

  /// Get caretakers from server
  Future<List<Caretaker>> getCaretakersFromServer() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/caretakers'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body)['data'] ?? [];
        return jsonData
            .map((item) => Caretaker(
                  id: item['id'],
                  firstName: item['firstName'],
                  lastName: item['lastName'],
                  phoneNumber: item['phoneNumber'],
                  email: item['email'],
                  relationship: item['relationship'],
                  notifyViaSMS: item['notifyViaSMS'] == 1,
                  notifyViaEmail: item['notifyViaEmail'] == 1,
                  notifyViaNotification: item['notifyViaNotification'] == 1,
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching caretakers: $e');
      return [];
    }
  }

  // ============= ALARM LOGS =============

  /// Log alarm to server
  Future<bool> logAlarmToServer(AlarmLog log) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/alarm-logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'medicineId': log.medicineId,
          'medicineName': log.medicineName,
          'scheduledTime': log.scheduledTime,
          'status': log.status,
          'snoozeCount': log.snoozeCount,
          'takenAt': log.takenAt,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error logging alarm: $e');
      return false;
    }
  }

  /// Get alarm logs from server
  Future<List<AlarmLog>> getAlarmLogsFromServer() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/alarm-logs'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body)['data'] ?? [];
        return jsonData
            .map((item) => AlarmLog(
                  id: item['id'],
                  medicineId: item['medicineId'],
                  medicineName: item['medicineName'],
                  scheduledTime: item['scheduledTime'],
                  status: item['status'],
                  snoozeCount: item['snoozeCount'] ?? 0,
                  takenAt: item['takenAt'],
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching alarm logs: $e');
      return [];
    }
  }

  // ============= REMINDERS =============

  /// Save reminder to server
  Future<bool> saveReminderToServer(Reminder reminder) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/reminders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'medicineId': reminder.medicineId,
          'medicineName': reminder.medicineName,
          'time': reminder.time,
          'daysOfWeek': reminder.daysOfWeek,
          'isActive': reminder.isActive,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error saving reminder: $e');
      return false;
    }
  }

  /// Get reminders from server
  Future<List<Reminder>> getRemindersFromServer() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/reminders'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body)['data'] ?? [];
        return jsonData
            .map((item) => Reminder(
                  id: item['id'],
                  medicineId: item['medicineId'],
                  medicineName: item['medicineName'],
                  time: item['time'],
                  daysOfWeek: item['daysOfWeek'],
                  isActive: item['isActive'] == 1,
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  // ============= UTILITY METHODS =============

  /// Check server connection
  Future<bool> checkServerConnection() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Server connection error: $e');
      return false;
    }
  }

  /// Sync all local data to server
  Future<bool> syncAllDataToServer({
    required List<Medicine> medicines,
    required UserProfile? userProfile,
    required List<Caretaker> caretakers,
    required List<AlarmLog> alarmLogs,
    required List<Reminder> reminders,
  }) async {
    try {
      bool allSuccess = true;

      // Sync medicines
      for (var medicine in medicines) {
        final success = await syncMedicine(medicine);
        allSuccess = allSuccess && success;
      }

      // Sync user profile
      if (userProfile != null) {
        final success = await saveUserProfileToServer(userProfile);
        allSuccess = allSuccess && success;
      }

      // Sync caretakers
      for (var caretaker in caretakers) {
        final success = await saveCaretakerToServer(caretaker);
        allSuccess = allSuccess && success;
      }

      // Sync alarm logs
      for (var log in alarmLogs) {
        final success = await logAlarmToServer(log);
        allSuccess = allSuccess && success;
      }

      // Sync reminders
      for (var reminder in reminders) {
        final success = await saveReminderToServer(reminder);
        allSuccess = allSuccess && success;
      }

      return allSuccess;
    } catch (e) {
      print('Error syncing all data: $e');
      return false;
    }
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

