// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/professional_review_request.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';

class MySQLApiService {
  static final MySQLApiService _instance = MySQLApiService._internal();
  static const Duration _requestTimeout = Duration(seconds: 10);

<<<<<<< HEAD
  // Set at runtime with --dart-define=MONGO_API_BASE_URL=http://<your-ip>:3000/api
  static const String _configuredBaseUrl = String.fromEnvironment(
    'MONGO_API_BASE_URL',
=======
  // Set at runtime with --dart-define=MYSQL_API_BASE_URL=http://<your-ip>:3000/api
  static const String _configuredBaseUrl = String.fromEnvironment(
    'MYSQL_API_BASE_URL',
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
    defaultValue: 'http://localhost:3000/api',
  );

  late http.Client _client;
<<<<<<< HEAD
  String _userId = 'guest';
=======
  String _userId = 'demo-user';
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  String? _authToken;
  String _activeBaseUrl = _configuredBaseUrl;

  factory MySQLApiService() => _instance;

  MySQLApiService._internal() {
    _client = http.Client();
  }

  String get currentBaseUrl => _activeBaseUrl;

  void configure({String? userId, String? authToken}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _userId = userId.trim();
    }
    _authToken = authToken;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final fullPath =
        path.startsWith('/') ? '$_activeBaseUrl$path' : '$_activeBaseUrl/$path';
    return Uri.parse(fullPath).replace(queryParameters: query);
  }

  List<String> _candidateBaseUrls() {
    final candidates = <String>{_configuredBaseUrl};
    final uri = Uri.tryParse(_configuredBaseUrl);
    if (uri != null && uri.host == 'localhost') {
      candidates.add(
        uri.replace(host: '10.0.2.2').toString(),
      );
      candidates.add(
        uri.replace(host: '127.0.0.1').toString(),
      );
    } else if (uri != null && uri.host == '127.0.0.1') {
      candidates.add(
        uri.replace(host: 'localhost').toString(),
      );
      candidates.add(
        uri.replace(host: '10.0.2.2').toString(),
      );
    }
    return candidates.toList();
  }

  Future<bool> _checkHealthAt(String baseUrl) async {
    try {
      final healthUri = Uri.parse('$baseUrl/health');
      final response = await _client
          .get(healthUri, headers: _headers(json: false))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
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

  String? _extractErrorMessage(http.Response response) {
    final body = _safeBody(response);
    if (body is Map<String, dynamic>) {
      return body['message'] as String?;
    }
    return null;
  }

  dynamic _safeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

<<<<<<< HEAD
  Future<void> _resolveBaseUrl() async {
    await checkServerConnection();
  }

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  // ============= AUTH =============

  Future<bool> registerUser(String email, String password) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .post(
            _uri('/auth/register'),
            headers: _headers(),
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<String?> registerUserWithMessage(String email, String password) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .post(
            _uri('/auth/register'),
            headers: _headers(),
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      if (_isSuccess(response)) return null;
      return _extractErrorMessage(response) ?? 'Registration failed';
    } catch (e) {
      print('Error registering user with message: $e');
      return 'Registration request failed';
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .post(
            _uri('/auth/login'),
            headers: _headers(),
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      if (!_isSuccess(response)) return null;
      final body = _safeBody(response);
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      print('Error logging in user: $e');
      return null;
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .get(
            _uri('/auth/exists', {'email': email.trim().toLowerCase()}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);

      if (!_isSuccess(response)) return false;
      final body = _safeBody(response);
      if (body is! Map<String, dynamic>) return false;
      return body['exists'] == true;
    } catch (e) {
      print('Error checking registered email: $e');
      return false;
    }
  }

  Future<int> getTotalRegisteredUsers() async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .get(_uri('/auth/stats'), headers: _headers(json: false))
          .timeout(_requestTimeout);
      if (!_isSuccess(response)) return 0;
      final body = _safeBody(response);
      if (body is! Map<String, dynamic>) return 0;
      return body['totalUsers'] as int? ?? 0;
    } catch (e) {
      print('Error fetching auth stats: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>?> getAdminSqlEntries() async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .get(_uri('/admin/sql-entries'), headers: _headers(json: false))
          .timeout(const Duration(seconds: 15));

      if (!_isSuccess(response)) return null;
      final body = _safeBody(response);
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      print('Error fetching admin SQL entries: $e');
      return null;
    }
  }

  // ============= MEDICINES =============

  Future<bool> syncMedicine(Medicine medicine) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .post(
            _uri('/medicines'),
            headers: _headers(),
            body: jsonEncode({
              'userId': _userId,
              'id': medicine.id,
              'name': medicine.name,
              'dosage': medicine.dosage,
              'time': medicine.time,
              'category': medicine.category.name,
              'expiryDate': medicine.expiryDate?.toIso8601String(),
              'isScanned': medicine.isScanned,
              'scannedText': medicine.scannedText,
              'imagePath': medicine.imagePath,
              'healthCondition': medicine.healthCondition,
              'createdAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error syncing medicine: $e');
      return false;
    }
  }

  Future<List<Medicine>> getMedicinesFromServer() async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .get(
            _uri('/medicines', {'userId': _userId}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);

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
              expiryDate: item['expiryDate'] != null
                  ? DateTime.tryParse(item['expiryDate'] as String)
                  : null,
              isScanned: (item['isScanned'] == true || item['isScanned'] == 1),
              scannedText: item['scannedText'] as String?,
              imagePath: item['imagePath'] as String?,
              healthCondition: item['healthCondition'] as String?,
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client.put(
        _uri('/medicines/$id'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
          'category': medicine.category.name,
          'expiryDate': medicine.expiryDate?.toIso8601String(),
          'isScanned': medicine.isScanned,
          'scannedText': medicine.scannedText,
          'imagePath': medicine.imagePath,
          'healthCondition': medicine.healthCondition,
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
              notifyViaSMS:
                  item['notifyViaSMS'] == true || item['notifyViaSMS'] == 1,
              notifyViaEmail:
                  item['notifyViaEmail'] == true || item['notifyViaEmail'] == 1,
              notifyViaNotification: item['notifyViaNotification'] == true ||
                  item['notifyViaNotification'] == 1,
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

  Future<bool> deleteCaretakerFromServer(int id) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .delete(
            _uri('/caretakers/$id', {'userId': _userId}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error deleting caretaker: $e');
      return false;
    }
  }

  // ============= ALARM LOGS =============

  Future<bool> logAlarmToServer(AlarmLog log) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
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

  Future<bool> deleteReminderFromServer(int id) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .delete(
            _uri('/reminders/$id', {'userId': _userId}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error deleting reminder: $e');
      return false;
    }
  }

  // ============= PROFESSIONAL REVIEWS =============

  Future<bool> submitProfessionalReviewRequest(
    ProfessionalReviewRequest request,
  ) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client.post(
        _uri('/professional-reviews'),
        headers: _headers(),
        body: jsonEncode({
          'userId': _userId,
          ...request.toJson(),
        }),
      );
      return _isSuccess(response);
    } catch (e) {
      print('Error submitting professional review request: $e');
      return false;
    }
  }

  // ============= BARCODE LOOKUP =============

  Future<Map<String, dynamic>?> lookupBarcodeFromServer(String barcode) async {
    final sanitized = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) {
      return null;
    }

    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client.get(
        _uri('/barcode-lookup/$sanitized', {'userId': _userId}),
        headers: _headers(json: false),
      );

      if (!_isSuccess(response)) {
        return null;
      }

      final body = _safeBody(response);
      if (body is! Map<String, dynamic>) {
        return null;
      }

      final data = body['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      print('Error looking up barcode on server: $e');
      return null;
    }
  }

  // ============= DEPENDENTS =============

  Future<bool> saveDependentToServer(Map<String, dynamic> dependent) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .post(
            _uri('/dependents'),
            headers: _headers(),
            body: jsonEncode({
              'userId': _userId,
              ...dependent,
            }),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error saving dependent: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDependentsFromServer() async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .get(
            _uri('/dependents', {'userId': _userId}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);

      if (!_isSuccess(response)) return <Map<String, dynamic>>[];
      final body = _safeBody(response);
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List<dynamic>? ?? const <dynamic>[])
          : const <dynamic>[];
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching dependents: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<bool> deleteDependentFromServer(int id) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .delete(
            _uri('/dependents/$id', {'userId': _userId}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error deleting dependent: $e');
      return false;
    }
  }

  // ============= SETTINGS =============

  Future<bool> saveSettingToServer(String key, String value) async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .post(
            _uri('/settings'),
            headers: _headers(),
            body: jsonEncode({
              'userId': _userId,
              'key': key,
              'value': value,
            }),
          )
          .timeout(_requestTimeout);
      return _isSuccess(response);
    } catch (e) {
      print('Error saving setting: $e');
      return false;
    }
  }

  Future<Map<String, String>> getSettingsFromServer() async {
    try {
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      final response = await _client
          .get(
            _uri('/settings', {'userId': _userId}),
            headers: _headers(json: false),
          )
          .timeout(_requestTimeout);
      if (!_isSuccess(response)) return <String, String>{};

      final body = _safeBody(response);
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List<dynamic>? ?? const <dynamic>[])
          : const <dynamic>[];

      final map = <String, String>{};
      for (final row in list.whereType<Map<String, dynamic>>()) {
        final key = row['keyName']?.toString();
        if (key == null || key.isEmpty) continue;
        map[key] = row['value']?.toString() ?? '';
      }
      return map;
    } catch (e) {
      print('Error fetching settings: $e');
      return <String, String>{};
    }
  }

  // ============= UTILITY METHODS =============

  Future<bool> checkServerConnection() async {
    try {
      for (final candidate in _candidateBaseUrls()) {
        final ok = await _checkHealthAt(candidate);
        if (ok) {
          _activeBaseUrl = candidate;
          return true;
        }
      }
      return false;
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
<<<<<<< HEAD
      await _resolveBaseUrl();
=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
      if (userId != null && userId.trim().isNotEmpty) {
        _userId = userId.trim();
      }

      final response = await _client
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

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
