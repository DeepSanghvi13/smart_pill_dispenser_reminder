// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/mysql_api_service.dart';

class SyncProvider extends ChangeNotifier {
  static const String _keyPendingSync = 'pending_mysql_sync';

  final DatabaseService _dbService = DatabaseService();
  final MySQLApiService _apiService = MySQLApiService();

  bool _isSyncing = false;
  bool _isInitializing = false;
  bool _hasPendingSync = false;
  String? _lastSyncTime;
  String? _syncStatus;

  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _hasPendingSync;
  String? get lastSyncTime => _lastSyncTime;
  String? get syncStatus => _syncStatus;

  Future<void> _loadPendingSyncFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPendingSync = prefs.getBool(_keyPendingSync) ?? false;
  }

  Future<void> _savePendingSyncFlag(bool value) async {
    _hasPendingSync = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPendingSync, value);
  }

  /// Initialize sync
  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await _loadPendingSyncFlag();

      // Check server connection
      final isConnected = await _apiService.checkServerConnection();
      if (isConnected) {
        _syncStatus = _hasPendingSync
            ? 'Connected to server (${_apiService.currentBaseUrl}) - pending sync queued'
            : 'Connected to server (${_apiService.currentBaseUrl})';
        print('✅ Server connection: OK');
      } else {
        _syncStatus = _hasPendingSync
            ? 'Offline mode - local storage (pending sync queued)'
            : 'Offline mode - using local storage';
        print('⚠️ Server connection: Failed');
      }
      notifyListeners();
    } catch (e) {
      _syncStatus = 'Error: $e';
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  /// Sync all data to server
  Future<bool> syncAllData(String userId) async {
    try {
      _isSyncing = true;
      _syncStatus = 'Syncing...';
      notifyListeners();

      // Fetch all local data
      final medicines = await _dbService.getAllMedicines();
      final userProfile = await _dbService.getUserProfileData();
      final caretakers = await _dbService.getAllCaretakers();
      final alarmLogs = await _dbService.getAllAlarmLogs();
      final reminders = await _dbService.getAllReminders();

      // Sync to server
      final success = await _apiService.syncAllDataToServer(
        medicines: medicines,
        userProfile: userProfile,
        caretakers: caretakers,
        alarmLogs: alarmLogs,
        reminders: reminders,
        userId: userId,
      );

      _isSyncing = false;
      if (success) {
        await _savePendingSyncFlag(false);
        _lastSyncTime = DateTime.now().toString();
        _syncStatus = 'Synced successfully at ${DateTime.now().toLocal()}';
        print('✅ Data synced to MySQL');
      } else {
        await _savePendingSyncFlag(true);
        _syncStatus = 'Sync failed - check connection';
        print('❌ Sync failed');
      }
      notifyListeners();
      return success;
    } catch (e) {
      await _savePendingSyncFlag(true);
      _isSyncing = false;
      _syncStatus = 'Error: $e';
      notifyListeners();
      print('❌ Sync error: $e');
      return false;
    }
  }

  Future<bool> retryPendingSync(String userId) async {
    if (!_hasPendingSync) return true;
    final isConnected = await _apiService.checkServerConnection();
    if (!isConnected) {
      _syncStatus = 'Still offline - pending sync remains queued';
      notifyListeners();
      return false;
    }
    return syncAllData(userId);
  }

  /// Sync single medicine
  Future<bool> syncMedicine(Medicine medicine) async {
    try {
      return await _apiService.syncMedicine(medicine);
    } catch (e) {
      print('Error syncing medicine: $e');
      return false;
    }
  }

  /// Get medicines from server
  Future<List<Medicine>> fetchMedicinesFromServer() async {
    try {
      return await _apiService.getMedicinesFromServer();
    } catch (e) {
      print('Error fetching medicines: $e');
      return [];
    }
  }

  /// Pull medicines from server and save locally
  Future<bool> pullMedicinesFromServer() async {
    try {
      _isSyncing = true;
      _syncStatus = 'Pulling data from server...';
      notifyListeners();

      final medicines = await _apiService.getMedicinesFromServer();

      // Save to local database
      for (var medicine in medicines) {
        if (medicine.id != null) {
          final existing = await _dbService.getMedicineById(medicine.id!);
          if (existing != null) {
            await _dbService.updateMedicine(medicine.id!, medicine);
          } else {
            await _dbService.addMedicine(medicine);
          }
        } else {
          await _dbService.addMedicine(medicine);
        }
      }

      _isSyncing = false;
      _lastSyncTime = DateTime.now().toString();
      _syncStatus = 'Pulled ${medicines.length} medicines from server';
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      _syncStatus = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear sync status
  void clearSyncStatus() {
    _syncStatus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
<<<<<<< HEAD

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
