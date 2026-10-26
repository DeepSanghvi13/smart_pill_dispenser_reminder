import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hive_service.dart';
import '../services/mysql_api_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class SyncProvider extends ChangeNotifier {
  static const String _keyPendingSync = 'mysql_pending_sync';
  static const String _keyLastSync = 'mysql_last_sync_time';

  bool _isSyncing = false;
  bool _hasPendingSync = false;
  String? _lastSyncTime;
  String? _syncStatus;

  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _hasPendingSync;
  String? get lastSyncTime => _lastSyncTime;
  String? get syncStatus => _syncStatus;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasPendingSync = prefs.getBool(_keyPendingSync) ?? false;
      _lastSyncTime = prefs.getString(_keyLastSync);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> syncAllData(String userId) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _syncStatus = 'Synchronizing data with MySQL server...';
    notifyListeners();

    try {
      final api = MySQLApiService();
      final isOnline = await api.checkServerConnection();
      if (!isOnline) {
        _isSyncing = false;
        _hasPendingSync = true;
        _syncStatus = 'Sync failed. MySQL server is offline.';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyPendingSync, true);
        notifyListeners();
        return false;
      }

      // 1. Gather local data for userId
      final db = DatabaseService();
      final localMedicines = await db.getAllMedicines();
      final localReminders = await db.getAllReminders();
      final localAlarmLogs = await db.getAllAlarmLogs();
      final localCaretakers = await db.getAllCaretakers();
      final UserProfile? userProfile = HiveService().profilesBox.get(userId.trim().toLowerCase());

      // 2. Push to server
      final pushSuccess = await api.syncAllDataToServer(
        userId: userId,
        medicines: localMedicines,
        reminders: localReminders,
        alarmLogs: localAlarmLogs,
        caretakers: localCaretakers,
        userProfile: userProfile,
      );

      if (!pushSuccess) {
        _isSyncing = false;
        _hasPendingSync = true;
        _syncStatus = 'Partial sync failure during data upload.';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyPendingSync, true);
        notifyListeners();
        return false;
      }

      // 3. Pull latest medicines from server to reconcile local storage
      await pullMedicinesFromServer();

      // 4. Update sync state
      final nowStr = DateTime.now().toIso8601String();
      _isSyncing = false;
      _hasPendingSync = false;
      _lastSyncTime = nowStr;
      _syncStatus = 'Synchronization completed successfully.';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPendingSync, false);
      await prefs.setString(_keyLastSync, nowStr);

      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      _hasPendingSync = true;
      _syncStatus = 'Sync error: $e';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyPendingSync, true);
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  Future<bool> retryPendingSync(String userId) async {
    return syncAllData(userId);
  }

  Future<bool> pullMedicinesFromServer() async {
    try {
      final api = MySQLApiService();
      final isOnline = await api.checkServerConnection();
      if (!isOnline) return false;

      final serverMeds = await api.getMedicinesFromServer();
      if (serverMeds.isNotEmpty) {
        final box = HiveService().medicinesBox;
        for (final m in serverMeds) {
          if (m.id != null) {
            await box.put(m.id.toString(), m);
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearSyncStatus() {
    _syncStatus = null;
    notifyListeners();
  }
}
