import 'package:flutter/foundation.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/mysql_api_service.dart';

class SyncProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final MySQLApiService _apiService = MySQLApiService();

  bool _isSyncing = false;
  String? _lastSyncTime;
  String? _syncStatus;

  bool get isSyncing => _isSyncing;
  String? get lastSyncTime => _lastSyncTime;
  String? get syncStatus => _syncStatus;

  /// Initialize sync
  Future<void> initialize() async {
    try {
      // Check server connection
      final isConnected = await _apiService.checkServerConnection();
      if (isConnected) {
        _syncStatus = 'Connected to server';
        print('✅ Server connection: OK');
      } else {
        _syncStatus = 'Offline mode - using local storage';
        print('⚠️ Server connection: Failed');
      }
      notifyListeners();
    } catch (e) {
      _syncStatus = 'Error: $e';
      notifyListeners();
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
      );

      _isSyncing = false;
      if (success) {
        _lastSyncTime = DateTime.now().toString();
        _syncStatus = 'Synced successfully at ${DateTime.now().toLocal()}';
        print('✅ Data synced to MySQL');
      } else {
        _syncStatus = 'Sync failed - check connection';
        print('❌ Sync failed');
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isSyncing = false;
      _syncStatus = 'Error: $e';
      notifyListeners();
      print('❌ Sync error: $e');
      return false;
    }
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
        await _dbService.saveMedicine(medicine);
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

