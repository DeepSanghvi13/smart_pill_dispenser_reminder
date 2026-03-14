import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';

class MySQLApiService {
  static final MySQLApiService _instance = MySQLApiService._internal();

  // Set at runtime with --dart-define=MYSQL_API_BASE_URL=http://<your-ip>:3000/api
  static const String baseUrl = String.fromEnvironment(
    'MYSQL_API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  late http.Client _client;
  String _userId = 'demo-user';
  String? _authToken;

  factory MySQLApiService() => _instance;

  MySQLApiService._internal() {
    _client = http.Client();
  }

  void configure({String? userId, String? authToken}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _userId = userId.trim();
    }
    _authToken = authToken;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final fullPath = path.startsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
    return Uri.parse(fullPath).replace(queryParameters: query);
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  bool _isSuccess(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  dynamic _safeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  // ============= MEDICINES =============

  Future<bool> syncMedicine(Medicine medicine) async {
    try {
      final response = await _client.post(
        _uri('/medicines'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'id': medicine.id,
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'category': medicine.category.name,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error syncing medicine: $e');
      return false;
    }
  }

  Future<List<Medicine>> getMedicinesFromServer() async {
    try {
      final response = await _client.get(
        _uri('/medicines', {'userId': _userId}),
        headers: _headers(json: false),
      );

      if (!_isSuccess(response)) return [];
      final body = _safeBody(response);
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List<dynamic>? ?? const [])
          : const <dynamic>[];

      return list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => Medicine(
              id: item['id'] as int?,
              name: item['name'] as String? ?? '',
              dosage: item['dosage'] as String? ?? '',
              time: item['time'] as String? ?? '',
              category: MedicineCategory.fromString(
                item['category'] as String? ?? 'tablets',
              ),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching medicines: $e');
      return [];
    }
  }

  Future<bool> updateMedicineOnServer(int id, Medicine medicine) async {
    try {
      final response = await _client.put(
        _uri('/medicines/$id'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'category': medicine.category.name,
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error updating medicine: $e');
      return false;
    }
  }

  Future<bool> deleteMedicineFromServer(int id) async {
    try {
      final response = await _client.delete(
        _uri('/medicines/$id', {'userId': _userId}),
        headers: _headers(json: false),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error deleting medicine: $e');
      return false;
    }
  }

  // ============= USER PROFILE =============

  Future<bool> saveUserProfileToServer(UserProfile profile) async {
    try {
      final response = await _client.post(
        _uri('/user-profile'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'gender': profile.gender,
          'birthDate': profile.birthDate,
          'zipCode': profile.zipCode,
          'phoneNumber': profile.phoneNumber,
          'email': profile.email,
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  Future<UserProfile?> getUserProfileFromServer(String userId) async {
    try {
      final response = await _client.get(
        _uri('/user-profile/$userId'),
        headers: _headers(json: false),
      );

      if (!_isSuccess(response)) return null;
      final body = _safeBody(response);
      final data = (body is Map<String, dynamic>)
          ? body['data'] as Map<String, dynamic>?
          : null;
      if (data == null) return null;

      return UserProfile(
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        gender: data['gender'] as String?,
        birthDate: data['birthDate'] as String?,
        zipCode: data['zipCode'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
        email: data['email'] as String?,
      );
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // ============= CARETAKERS =============

  Future<bool> saveCaretakerToServer(Caretaker caretaker) async {
    try {
      final response = await _client.post(
        _uri('/caretakers'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'id': caretaker.id,
          'firstName': caretaker.firstName,
          'lastName': caretaker.lastName,
          'phoneNumber': caretaker.phoneNumber,
          'email': caretaker.email,
          'relationship': caretaker.relationship,
          'notifyViaSMS': caretaker.notifyViaSMS,
          'notifyViaEmail': caretaker.notifyViaEmail,
          'notifyViaNotification': caretaker.notifyViaNotification,
          'isActive': caretaker.isActive,
          'createdAt': caretaker.createdAt,
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error saving caretaker: $e');
      return false;
    }
  }

  Future<List<Caretaker>> getCaretakersFromServer() async {
    try {
      final response = await _client.get(
        _uri('/caretakers', {'userId': _userId}),
        headers: _headers(json: false),
      );

      if (!_isSuccess(response)) return [];
      final body = _safeBody(response);
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List<dynamic>? ?? const [])
          : const <dynamic>[];

      return list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => Caretaker(
              id: item['id'] as int?,
              firstName: item['firstName'] as String? ?? '',
              lastName: item['lastName'] as String? ?? '',
              phoneNumber: item['phoneNumber'] as String? ?? '',
              email: item['email'] as String? ?? '',
              relationship: item['relationship'] as String? ?? '',
              notifyViaSMS: item['notifyViaSMS'] == true || item['notifyViaSMS'] == 1,
              notifyViaEmail: item['notifyViaEmail'] == true || item['notifyViaEmail'] == 1,
              notifyViaNotification:
                  item['notifyViaNotification'] == true || item['notifyViaNotification'] == 1,
              isActive: item['isActive'] == true || item['isActive'] == 1,
              createdAt: item['createdAt'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching caretakers: $e');
      return [];
    }
  }

  // ============= ALARM LOGS =============

  Future<bool> logAlarmToServer(AlarmLog log) async {
    try {
      final response = await _client.post(
        _uri('/alarm-logs'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'id': log.id,
          'medicineId': log.medicineId,
          'medicineName': log.medicineName,
          'scheduledTime': log.scheduledTime.toIso8601String(),
          'triggeredTime': log.triggeredTime?.toIso8601String(),
          'status': log.status,
          'snoozeCount': log.snoozeCount,
          'takenAt': log.takenAt?.toIso8601String(),
          'notes': log.notes,
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error logging alarm: $e');
      return false;
    }
  }

  Future<List<AlarmLog>> getAlarmLogsFromServer() async {
    try {
      final response = await _client.get(
        _uri('/alarm-logs', {'userId': _userId}),
        headers: _headers(json: false),
      );

      if (!_isSuccess(response)) return [];
      final body = _safeBody(response);
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List<dynamic>? ?? const [])
          : const <dynamic>[];

      return list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => AlarmLog(
              id: item['id'] as int?,
              medicineId: item['medicineId'] as int,
              medicineName: item['medicineName'] as String,
              scheduledTime: DateTime.parse(item['scheduledTime'] as String),
              triggeredTime: item['triggeredTime'] == null
                  ? null
                  : DateTime.parse(item['triggeredTime'] as String),
              status: item['status'] as String? ?? 'pending',
              snoozeCount: item['snoozeCount'] as int? ?? 0,
              takenAt: item['takenAt'] == null
                  ? null
                  : DateTime.parse(item['takenAt'] as String),
              notes: item['notes'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching alarm logs: $e');
      return [];
    }
  }

  // ============= REMINDERS =============

  Future<bool> saveReminderToServer(Reminder reminder) async {
    try {
      final response = await _client.post(
        _uri('/reminders'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'id': reminder.id,
          'medicineId': reminder.medicineId,
          'medicineName': reminder.medicineName,
          'time': reminder.time,
          'daysOfWeek': reminder.daysOfWeek,
          'isActive': reminder.isActive,
          'lastNotifiedAt': reminder.lastNotifiedAt?.toIso8601String(),
          'createdAt': reminder.createdAt?.toIso8601String(),
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error saving reminder: $e');
      return false;
    }
  }

  Future<List<Reminder>> getRemindersFromServer() async {
    try {
      final response = await _client.get(
        _uri('/reminders', {'userId': _userId}),
        headers: _headers(json: false),
      );

      if (!_isSuccess(response)) return [];
      final body = _safeBody(response);
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List<dynamic>? ?? const [])
          : const <dynamic>[];

      return list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => Reminder(
              id: item['id'] as int?,
              medicineId: item['medicineId'] as int,
              medicineName: item['medicineName'] as String,
              time: item['time'] as String,
              daysOfWeek: (item['daysOfWeek'] as List<dynamic>? ?? const [])
                  .map((day) => day.toString())
                  .toList(),
              isActive: item['isActive'] == true || item['isActive'] == 1,
              lastNotifiedAt: item['lastNotifiedAt'] == null
                  ? null
                  : DateTime.parse(item['lastNotifiedAt'] as String),
              createdAt: item['createdAt'] == null
                  ? null
                  : DateTime.parse(item['createdAt'] as String),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  // ============= UTILITY METHODS =============

  Future<bool> checkServerConnection() async {
    try {
      final response = await _client
          .get(_uri('/health'), headers: _headers(json: false))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Server connection error: $e');
      return false;
    }
  }

  Future<bool> syncAllDataToServer({
    required List<Medicine> medicines,
    required UserProfile? userProfile,
    required List<Caretaker> caretakers,
    required List<AlarmLog> alarmLogs,
    required List<Reminder> reminders,
    String? userId,
  }) async {
    try {
      if (userId != null && userId.trim().isNotEmpty) {
        _userId = userId.trim();
      }

      final response = await _client.post(
        _uri('/sync/all'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'userProfile': userProfile?.toMap(),
          'medicines': medicines.map((m) => m.toMap()).toList(),
          'caretakers': caretakers.map((c) => c.toMap()).toList(),
          'alarmLogs': alarmLogs.map((a) => a.toMap()).toList(),
          'reminders': reminders.map((r) => r.toMap()).toList(),
        }),
      );

      return _isSuccess(response);
    } catch (e) {
      print('Error syncing all data: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
