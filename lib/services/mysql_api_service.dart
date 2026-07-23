import '../models/alarm_log.dart';
import '../models/caretaker.dart';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../models/reminder.dart';

class MySQLApiService {
  static final MySQLApiService _instance = MySQLApiService._internal();

  factory MySQLApiService() {
    return _instance;
  }

  MySQLApiService._internal();

  void configure({required String userId, String? authToken}) {}

  Future<bool> checkServerConnection() async => false;

  Future<bool> isEmailRegistered(String email) async => false;

  Future<String?> registerUserWithMessage(String email, String password) async => null;

  Future<bool> registerUser(String email, String password) async => false;

  Future<Map<String, dynamic>?> loginUser(String email, String password) async => null;

  Future<int> getTotalRegisteredUsers() async => 0;

  Future<int?> createMedicineOnServer(Medicine medicine) async => null;

  Future<List<Medicine>> getMedicinesFromServer() async => [];

  Future<List<Reminder>> getRemindersFromServer() async => [];

  Future<bool> syncAllDataToServer({
    required List<Medicine> medicines,
    required UserProfile? userProfile,
    required List<Caretaker> caretakers,
    required List<AlarmLog> alarmLogs,
    required List<Reminder> reminders,
    required String userId,
  }) async => true;

  Future<bool> updateMedicineOnServer(int id, Medicine medicine) async => false;

  Future<bool> deleteMedicineFromServer(int id) async => false;

  Future<bool> saveSettingToServer(String key, String value) async => false;

  Future<Map<String, String>> getSettingsFromServer() async => {};

  Future<bool> saveDependentToServer(Map<String, dynamic> dependent) async => false;

  Future<List<Map<String, dynamic>>> getDependentsFromServer() async => [];

  Future<bool> deleteDependentFromServer(int id) async => false;

  Future<bool> saveCaretakerToServer(Caretaker caretaker) async => false;

  Future<List<Caretaker>> getCaretakersFromServer() async => [];

  Future<bool> deleteCaretakerFromServer(int id) async => false;

  Future<bool> logAlarmToServer(AlarmLog log) async => false;

  Future<List<AlarmLog>> getAlarmLogsFromServer() async => [];

  Future<bool> saveUserProfileToServer(UserProfile profile) async => false;

  Future<UserProfile?> getUserProfileFromServer(String userId) async => null;

  Future<Map<String, dynamic>?> getAdminSqlEntries() async => null;

  String get currentBaseUrl => 'local';

  Future<bool> submitProfessionalReviewRequest(dynamic request) async => false;

  Future<dynamic> lookupBarcodeFromServer(String barcode) async => null;

  void dispose() {}
}
