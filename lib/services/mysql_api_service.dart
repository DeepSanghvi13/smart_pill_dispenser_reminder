import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'hive_service.dart';
import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../models/reminder.dart';

class MySQLApiService {
  static final MySQLApiService _instance = MySQLApiService._internal();

  factory MySQLApiService() => _instance;
  MySQLApiService._internal();

  static const String _pcLanIp = '10.136.81.57';
  static const int _port = 3000;

  String? _resolvedBaseUrl;

  String get baseUrl {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    if (kIsWeb) return 'http://localhost:$_port';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:$_port';
    } catch (_) {}
    return 'http://localhost:$_port';
  }

  String get currentBaseUrl => baseUrl;

  String? get _token {
    try {
      return HiveService().settingsBox.get('jwt_token') as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    final tok = _token;
    if (tok != null) h['Authorization'] = 'Bearer $tok';
    return h;
  }

  String get _currentUserId {
    try {
      return HiveService().settingsBox.get('current_user_session') as String? ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  void configure({required String userId, String? authToken}) {
    if (authToken != null) {
      try {
        HiveService().settingsBox.put('jwt_token', authToken);
      } catch (_) {}
    }
  }

  /// Automatically tests and discovers working backend URL (localhost, emulator 10.0.2.2, PC LAN IP)
  Future<bool> checkServerConnection() async {
    final candidates = <String>[];
    if (kIsWeb) {
      candidates.add('http://localhost:$_port');
    } else {
      candidates.add('http://10.0.2.2:$_port');
      candidates.add('http://$_pcLanIp:$_port');
      candidates.add('http://127.0.0.1:$_port');
      candidates.add('http://localhost:$_port');
    }

    for (final candidate in candidates) {
      try {
        final res = await http
            .get(Uri.parse('$candidate/api/health'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = candidate;
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // ---- Auth ----

  Future<bool> isEmailRegistered(String email) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/auth/exists?email=${Uri.encodeComponent(email)}'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body)['exists'] as bool?) ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Register user on MySQL server. Returns null on success, error message on failure.
  Future<String?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
  }) async {
    // Attempt auto-discovery if URL not resolved yet
    await checkServerConnection();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': fullName,
              'email': email,
              'password': password,
              'role': role,
              if (phoneNumber != null) 'phoneNumber': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['ok'] == true) {
        return null; // success
      }
      return body['message'] as String? ?? 'Registration failed (${res.statusCode})';
    } catch (e) {
      return 'Server unreachable at $baseUrl: $e';
    }
  }

  Future<String?> registerUserWithMessage(String email, String password) async =>
      registerUser(email: email, password: password, fullName: email, role: 'patient');

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    await checkServerConnection();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> logoutUser() async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/logout'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- User Stats ----

  Future<int> getTotalRegisteredUsers() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/auth/stats'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body)['totalUsers'] as int?) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ---- Medicines ----

  Future<int?> createMedicineOnServer(Medicine medicine) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/medicines'),
            headers: _headers,
            body: jsonEncode(_medicinePayload(medicine)),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['id'] as int?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateMedicineOnServer(int id, Medicine medicine) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/medicines/$id'),
            headers: _headers,
            body: jsonEncode(_medicinePayload(medicine)),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMedicineFromServer(int id) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/api/medicines/$id?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Medicine>> getMedicinesFromServer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/medicines?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        return list.map((m) => Medicine.fromMap(Map<String, dynamic>.from(m as Map))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _medicinePayload(Medicine m) => {
        'userId': _currentUserId,
        'id': m.id,
        'name': m.name,
        'type': m.type,
        'dosage': m.dosage,
        'quantity': m.quantity,
        'frequency': m.frequency,
        'time': m.time,
        'startDate': m.startDate.toIso8601String(),
        'endDate': m.endDate.toIso8601String(),
        'notes': m.notes,
        'status': m.status,
        'isScanned': m.isScanned,
        'scannedText': m.scannedText,
        'imagePath': m.imagePath,
        'healthCondition': m.healthCondition,
      };

  // ---- Reminders ----

  Future<List<Reminder>> getRemindersFromServer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/reminders?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        return list.map((r) => Reminder.fromMap(Map<String, dynamic>.from(r as Map))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ---- Alarm Logs ----

  Future<bool> logAlarmToServer(AlarmLog log) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/alarm-logs'),
            headers: _headers,
            body: jsonEncode({
              'userId': _currentUserId,
              'medicineId': log.medicineId,
              'medicineName': log.medicineName,
              'scheduledTime': log.scheduledTime.toIso8601String(),
              'triggeredTime': log.triggeredTime?.toIso8601String(),
              'status': log.status,
              'snoozeCount': log.snoozeCount,
              'takenAt': log.takenAt?.toIso8601String(),
              'notes': log.notes,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<AlarmLog>> getAlarmLogsFromServer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/alarm-logs?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        return list.map((a) => AlarmLog.fromMap(Map<String, dynamic>.from(a as Map))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ---- User Profile ----

  Future<bool> saveUserProfileToServer(UserProfile profile) async {
    try {
      final userEmail = profile.email.trim().isNotEmpty ? profile.email.trim() : _currentUserId;
      final parts = profile.fullName.trim().split(' ');
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/user-profile'),
            headers: _headers,
            body: jsonEncode({
              'userId': userEmail,
              'firstName': parts.isNotEmpty ? parts.first : '',
              'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
              'email': profile.email,
              'gender': profile.gender,
              'phoneNumber': profile.mobileNumber,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<UserProfile?> getUserProfileFromServer(String userId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/user-profile/$userId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body)['data'] as Map<String, dynamic>?;
        if (d == null) return null;
        return UserProfile(
          email: d['email']?.toString() ?? '',
          fullName: '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim(),
          mobileNumber: d['phoneNumber']?.toString(),
          gender: d['gender']?.toString(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---- Settings ----

  Future<bool> saveSettingToServer(String key, String value) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/settings'),
            headers: _headers,
            body: jsonEncode({'userId': _currentUserId, 'key': key, 'value': value}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>> getSettingsFromServer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/settings?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        final map = <String, String>{};
        for (final item in list) {
          final i = item as Map;
          map[i['keyName'].toString()] = i['value'].toString();
        }
        return map;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // ---- Dependents ----

  Future<bool> saveDependentToServer(Map<String, dynamic> dependent) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/dependents'),
            headers: _headers,
            body: jsonEncode({'userId': _currentUserId, ...dependent}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDependentsFromServer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/dependents?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        return list.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteDependentFromServer(int id) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/api/dependents/$id?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Caretakers ----

  Future<bool> saveCaretakerToServer(Caretaker caretaker) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/caretakers'),
            headers: _headers,
            body: jsonEncode({
              'userId': _currentUserId,
              'firstName': caretaker.firstName,
              'lastName': caretaker.lastName,
              'phoneNumber': caretaker.phoneNumber,
              'email': caretaker.email,
              'relationship': caretaker.relationship,
              'notifyViaSMS': caretaker.notifyViaSMS,
              'notifyViaEmail': caretaker.notifyViaEmail,
              'notifyViaNotification': caretaker.notifyViaNotification,
              'isActive': caretaker.isActive,
            }),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Caretaker>> getCaretakersFromServer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/caretakers?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        return list.map((c) => Caretaker.fromMap(Map<String, dynamic>.from(c as Map))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteCaretakerFromServer(int id) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/api/caretakers/$id?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Full Sync ----

  Future<bool> syncAllDataToServer({
    required List<Medicine> medicines,
    required UserProfile? userProfile,
    required List<Caretaker> caretakers,
    required List<AlarmLog> alarmLogs,
    required List<Reminder> reminders,
    required String userId,
  }) async {
    try {
      final parts = userProfile?.fullName.trim().split(' ') ?? [];
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/sync/all'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'userProfile': userProfile != null
                  ? {
                      'firstName': parts.isNotEmpty ? parts.first : '',
                      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
                      'gender': userProfile.gender,
                      'phoneNumber': userProfile.mobileNumber,
                      'email': userProfile.email,
                    }
                  : null,
              'medicines': medicines.map(_medicinePayload).toList(),
              'reminders': reminders
                  .map((r) => {
                        'id': r.id,
                        'medicineId': r.medicineId,
                        'time': r.time,
                        'daysOfWeek': r.daysOfWeek,
                        'isActive': r.isActive,
                      })
                  .toList(),
              'alarmLogs': alarmLogs
                  .map((a) => {
                        'medicineId': a.medicineId,
                        'medicineName': a.medicineName,
                        'scheduledTime': a.scheduledTime.toIso8601String(),
                        'triggeredTime': a.triggeredTime?.toIso8601String(),
                        'status': a.status,
                        'snoozeCount': a.snoozeCount,
                        'takenAt': a.takenAt?.toIso8601String(),
                      })
                  .toList(),
              'caretakers': caretakers
                  .map((c) => {
                        'firstName': c.firstName,
                        'lastName': c.lastName,
                        'phoneNumber': c.phoneNumber,
                        'email': c.email,
                        'relationship': c.relationship,
                        'notifyViaSMS': c.notifyViaSMS,
                        'notifyViaEmail': c.notifyViaEmail,
                        'notifyViaNotification': c.notifyViaNotification,
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Admin ----

  Future<Map<String, dynamic>?> getAdminSqlEntries() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/admin/sql-entries'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---- Professional Review ----

  Future<bool> submitProfessionalReviewRequest(dynamic request) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/professional-reviews'),
            headers: _headers,
            body: jsonEncode(request),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Barcode Lookup ----

  Future<dynamic> lookupBarcodeFromServer(String barcode) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/barcode-lookup/$barcode'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(res.body)['data'];
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {}
}
