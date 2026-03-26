// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';
import '../models/medicine.dart';
import '../models/caretaker.dart';
import '../models/missed_medicine_alert.dart';
import '../models/reminder.dart';
import '../models/alarm_log.dart';
import '../models/user_profile.dart';
import 'mysql_api_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static Box<dynamic>? _medicinesBox;
  static Box<dynamic>? _barcodeCacheBox;
  static int _medicineIdCounter = 0;
  static String _currentUserId = 'guest';
  static final MySQLApiService _apiService = MySQLApiService();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  String get currentUserId => _currentUserId;

  static String _normalizeUserId(String? userId) {
    final value = userId?.trim().toLowerCase() ?? '';
    return value.isEmpty ? 'guest' : value;
  }

  String _currentCounterKey() => '_idCounter_$_currentUserId';

  String _medicineHiveKey(int id) => 'med_${_currentUserId}_$id';

  Future<MySQLApiService?> _connectedApi() async {
    _apiService.configure(userId: _currentUserId);
    final connected = await _apiService.checkServerConnection();
    return connected ? _apiService : null;
  }

  Future<void> _syncWebCounterForCurrentUser() async {
    if (!kIsWeb || _medicinesBox == null) return;
    _medicineIdCounter =
        _medicinesBox!.get(_currentCounterKey(), defaultValue: 0) ?? 0;
  }

  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = _normalizeUserId(userId);
    if (kIsWeb) {
      await initializeHiveBoxes();
      await _syncWebCounterForCurrentUser();
    }
  }

  /// Initialize Hive boxes for web
  Future<void> initializeHiveBoxes() async {
    if (kIsWeb) {
      try {
        _medicinesBox = await Hive.openBox('medicines');
        _barcodeCacheBox = await Hive.openBox('barcode_lookup_cache');

        // Maintain a per-user medicine id counter so web data stays isolated.
        final counterKey = _currentCounterKey();
        if (!_medicinesBox!.containsKey(counterKey)) {
          _medicinesBox!.put(counterKey, 0);
        }
        _medicineIdCounter =
            _medicinesBox!.get(counterKey, defaultValue: 0) ?? 0;
      } catch (e) {
        print('Error initializing Hive boxes: $e');
      }
    }
  }

  /// Get database instance
  Future<Database> get database async {
    if (kIsWeb) {
      await initializeHiveBoxes();
      // Return a dummy database that won't be used for web
      return _getDummyDatabase();
    }

    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  /// Get dummy database for web
  Database _getDummyDatabase() {
    throw UnsupportedError('Database not available on web');
  }

  /// Initialize database
  Future<Database> _initializeDatabase() async {
    if (kIsWeb) {
      await initializeHiveBoxes();
      return _getDummyDatabase();
    }

    final dbPath = await getDatabasesPath();
    final databasePath = path.join(dbPath, 'smart_pill_reminder.db');

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: _createTables,
      onOpen: (db) async {
        await _createTables(db, 1);
        await _ensureSchemaColumns(db);
      },
    );
  }

  /// Create all tables
  Future<void> _createTables(Database db, int version) async {
    // Medicine table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerUserId TEXT NOT NULL DEFAULT 'guest',
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        category TEXT DEFAULT 'tablets',
        expiryDate TEXT,
        isScanned INTEGER DEFAULT 0,
        scannedText TEXT,
        imagePath TEXT,
        healthCondition TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // User Profile table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        gender TEXT,
        birthDate TEXT,
        zipCode TEXT,
        phoneNumber TEXT,
        email TEXT,
        updatedAt TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Dependents table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dependents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        gender TEXT,
        birthDate TEXT,
        color TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    // Notification history
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        scheduledTime TEXT NOT NULL,
        sentTime TEXT,
        taken INTEGER DEFAULT 0,
        FOREIGN KEY (medicineId) REFERENCES medicines(id)
      )
    ''');

    // Caretakers table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caretakers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerUserId TEXT NOT NULL DEFAULT 'guest',
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT NOT NULL,
        relationship TEXT NOT NULL,
        notifyViaSMS INTEGER DEFAULT 1,
        notifyViaEmail INTEGER DEFAULT 1,
        notifyViaNotification INTEGER DEFAULT 1,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // Missed medicine alerts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS missed_medicine_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        medicineName TEXT NOT NULL,
        scheduledTime TEXT NOT NULL,
        detectedTime TEXT NOT NULL,
        notificationSent INTEGER DEFAULT 0,
        caretakersNotified INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        FOREIGN KEY (medicineId) REFERENCES medicines(id)
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerUserId TEXT NOT NULL DEFAULT 'guest',
        medicineId INTEGER NOT NULL,
        medicineName TEXT NOT NULL,
        time TEXT NOT NULL,
        daysOfWeek TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        lastNotifiedAt TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (medicineId) REFERENCES medicines(id)
      )
    ''');

    // Alarm logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alarm_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        medicineName TEXT NOT NULL,
        scheduledTime TEXT NOT NULL,
        triggeredTime TEXT,
        status TEXT DEFAULT 'pending',
        snoozeCount INTEGER DEFAULT 0,
        takenAt TEXT,
        notes TEXT,
        FOREIGN KEY (medicineId) REFERENCES medicines(id)
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Barcode lookup cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS barcode_lookup_cache (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        category TEXT NOT NULL,
        cachedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureSchemaColumns(Database db) async {
    await _ensureColumn(db,
        table: 'user_profiles', column: 'phoneNumber', type: 'TEXT');
    await _ensureColumn(db,
        table: 'user_profiles', column: 'email', type: 'TEXT');
    await _ensureColumn(db,
        table: 'user_profiles', column: 'updatedAt', type: 'TEXT');
    await _ensureColumn(db,
        table: 'medicines', column: 'expiryDate', type: 'TEXT');
    await _ensureColumn(db,
        table: 'medicines', column: 'isScanned', type: 'INTEGER DEFAULT 0');
    await _ensureColumn(db,
        table: 'medicines', column: 'scannedText', type: 'TEXT');
    await _ensureColumn(db,
        table: 'medicines', column: 'imagePath', type: 'TEXT');
    await _ensureColumn(db,
        table: 'medicines', column: 'healthCondition', type: 'TEXT');
    await _ensureColumn(db,
        table: 'medicines',
        column: 'ownerUserId',
        type: "TEXT NOT NULL DEFAULT 'guest'");
    await _ensureColumn(db,
        table: 'reminders',
        column: 'ownerUserId',
        type: "TEXT NOT NULL DEFAULT 'guest'");
    await _ensureColumn(db,
        table: 'caretakers',
        column: 'ownerUserId',
        type: "TEXT NOT NULL DEFAULT 'guest'");
  }

  Future<void> _ensureColumn(
    Database db, {
    required String table,
    required String column,
    required String type,
  }) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
    final exists = tableInfo.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  // ============= MEDICINE OPERATIONS =============

  /// Add a new medicine (works on web and native)
  Future<int> addMedicine(Medicine medicine) async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      _medicineIdCounter++;
      final medicineMap = {
        'id': _medicineIdCounter,
        'ownerUserId': _currentUserId,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'category': medicine.category.name,
        'expiryDate': medicine.expiryDate?.toIso8601String(),
        'isScanned': medicine.isScanned ? 1 : 0,
        'scannedText': medicine.scannedText,
        'imagePath': medicine.imagePath,
        'healthCondition': medicine.healthCondition,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _medicinesBox!
          .put(_medicineHiveKey(_medicineIdCounter), medicineMap);
      await _medicinesBox!.put(_currentCounterKey(), _medicineIdCounter);
      final api = await _connectedApi();
      if (api != null) {
        await api.syncMedicine(medicine.copyWith(id: _medicineIdCounter));
      }
      return _medicineIdCounter;
    }

    // Native implementation using SQLite
    final db = await database;
    final id = await db.insert(
      'medicines',
      {
        'ownerUserId': _currentUserId,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'category': medicine.category.name,
        'expiryDate': medicine.expiryDate?.toIso8601String(),
        'isScanned': medicine.isScanned ? 1 : 0,
        'scannedText': medicine.scannedText,
        'imagePath': medicine.imagePath,
        'healthCondition': medicine.healthCondition,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.syncMedicine(medicine.copyWith(id: id));
    }
    return id;
  }

  /// Get all medicines (works on web and native)
  Future<List<Medicine>> getAllMedicines() async {
    final api = await _connectedApi();
    if (api != null) {
      return api.getMedicinesFromServer();
    }

    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      final medicines = <Medicine>[];
      final keyPrefix = 'med_${_currentUserId}_';
      for (var key in _medicinesBox!.keys) {
        if (key is! String || !key.startsWith(keyPrefix)) continue;
        final data = _medicinesBox!.get(key) as Map?;
        if (data != null) {
          medicines.add(Medicine(
            id: data['id'] as int?,
            name: data['name'] as String,
            dosage: data['dosage'] as String,
            time: data['time'] as String,
            category: MedicineCategory.fromString(
                data['category'] as String? ?? 'tablets'),
            expiryDate: data['expiryDate'] != null
                ? DateTime.tryParse(data['expiryDate'] as String)
                : null,
            isScanned: (data['isScanned'] as int? ?? 0) == 1,
            scannedText: data['scannedText'] as String?,
            imagePath: data['imagePath'] as String?,
            healthCondition: data['healthCondition'] as String?,
          ));
        }
      }
      return medicines;
    }

    // Native implementation using SQLite
    final db = await database;
    final result = await db.query(
      'medicines',
      where: 'ownerUserId = ?',
      whereArgs: [_currentUserId],
    );
    return result.map((map) => Medicine.fromMap(map)).toList();
  }

  /// Get medicine by ID (works on web and native)
  Future<Medicine?> getMedicineById(int id) async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      final data = _medicinesBox!.get(_medicineHiveKey(id)) as Map?;
      if (data != null) {
        return Medicine(
          id: data['id'] as int?,
          name: data['name'] as String,
          dosage: data['dosage'] as String,
          time: data['time'] as String,
          category: MedicineCategory.fromString(
              data['category'] as String? ?? 'tablets'),
          expiryDate: data['expiryDate'] != null
              ? DateTime.tryParse(data['expiryDate'] as String)
              : null,
          isScanned: (data['isScanned'] as int? ?? 0) == 1,
          scannedText: data['scannedText'] as String?,
          imagePath: data['imagePath'] as String?,
          healthCondition: data['healthCondition'] as String?,
        );
      }
      return null;
    }

    // Native implementation using SQLite
    final db = await database;
    final result = await db.query(
      'medicines',
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
    );
    if (result.isNotEmpty) {
      return Medicine.fromMap(result.first);
    }
    return null;
  }

  /// Update medicine (works on web and native)
  Future<int> updateMedicine(int id, Medicine medicine) async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      final medicineMap = {
        'id': id,
        'ownerUserId': _currentUserId,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'category': medicine.category.name,
        'expiryDate': medicine.expiryDate?.toIso8601String(),
        'isScanned': medicine.isScanned ? 1 : 0,
        'scannedText': medicine.scannedText,
        'imagePath': medicine.imagePath,
        'healthCondition': medicine.healthCondition,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _medicinesBox!.put(_medicineHiveKey(id), medicineMap);
      final api = await _connectedApi();
      if (api != null) {
        await api.updateMedicineOnServer(id, medicine);
      }
      return 1; // Return 1 to indicate success
    }

    // Native implementation using SQLite
    final db = await database;
    final updated = await db.update(
      'medicines',
      {
        'ownerUserId': _currentUserId,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'category': medicine.category.name,
        'expiryDate': medicine.expiryDate?.toIso8601String(),
        'isScanned': medicine.isScanned ? 1 : 0,
        'scannedText': medicine.scannedText,
        'imagePath': medicine.imagePath,
        'healthCondition': medicine.healthCondition,
      },
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.updateMedicineOnServer(id, medicine);
    }
    return updated;
  }

  /// Delete medicine (works on web and native)
  Future<int> deleteMedicine(int id) async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      await _medicinesBox!.delete(_medicineHiveKey(id));
      final api = await _connectedApi();
      if (api != null) {
        await api.deleteMedicineFromServer(id);
      }
      return 1; // Return 1 to indicate success
    }

    // Native implementation using SQLite
    final db = await database;
    final deleted = await db.delete(
      'medicines',
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.deleteMedicineFromServer(id);
    }
    return deleted;
  }

  // ============= SETTINGS OPERATIONS =============

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    final api = await _connectedApi();
    if (api != null) {
      await api.saveSettingToServer(key, value);
    }

    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    final all = await getAllSettings();
    if (all.containsKey(key)) {
      return all[key];
    }

    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final api = await _connectedApi();
    if (api != null) {
      final serverSettings = await api.getSettingsFromServer();
      if (serverSettings.isNotEmpty) {
        return serverSettings;
      }
    }

    final db = await database;
    final result = await db.query('settings');
    final map = <String, String>{};
    for (var row in result) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }

  // ============= NOTIFICATION HISTORY =============

  /// Log notification
  Future<int> logNotification(
    int medicineId,
    DateTime scheduledTime, {
    bool taken = false,
  }) async {
    final db = await database;
    return await db.insert(
      'notification_history',
      {
        'medicineId': medicineId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'sentTime': DateTime.now().toIso8601String(),
        'taken': taken ? 1 : 0,
      },
    );
  }

  /// Mark notification as taken
  Future<int> markNotificationAsTaken(int notificationId) async {
    final db = await database;
    return await db.update(
      'notification_history',
      {'taken': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final db = await database;
    return await db.query('notification_history',
        orderBy: 'scheduledTime DESC');
  }

  // ============= DEPENDENTS OPERATIONS =============

  /// Add dependent
  Future<int> addDependent({
    required String firstName,
    required String lastName,
    String? gender,
    String? birthDate,
    String? color,
  }) async {
    final db = await database;
    final id = await db.insert(
      'dependents',
      {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'birthDate': birthDate,
        'color': color,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.saveDependentToServer({
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'birthDate': birthDate,
        'color': color,
      });
    }
    return id;
  }

  /// Get all dependents
  Future<List<Map<String, dynamic>>> getAllDependents() async {
    final api = await _connectedApi();
    if (api != null) {
      final dependents = await api.getDependentsFromServer();
      if (dependents.isNotEmpty) {
        return dependents;
      }
    }

    final db = await database;
    return await db.query('dependents');
  }

  /// Delete dependent
  Future<int> deleteDependent(int id) async {
    final db = await database;
    final deleted = await db.delete(
      'dependents',
      where: 'id = ?',
      whereArgs: [id],
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.deleteDependentFromServer(id);
    }
    return deleted;
  }

  // ============= CARETAKER OPERATIONS =============

  /// Add caretaker
  Future<int> addCaretaker(Caretaker caretaker) async {
    final db = await database;
    final id = await db.insert('caretakers', {
      'ownerUserId': _currentUserId,
      'firstName': caretaker.firstName,
      'lastName': caretaker.lastName,
      'phoneNumber': caretaker.phoneNumber,
      'email': caretaker.email,
      'relationship': caretaker.relationship,
      'notifyViaSMS': caretaker.notifyViaSMS ? 1 : 0,
      'notifyViaEmail': caretaker.notifyViaEmail ? 1 : 0,
      'notifyViaNotification': caretaker.notifyViaNotification ? 1 : 0,
      'isActive': caretaker.isActive ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    final api = await _connectedApi();
    if (api != null) {
      await api.saveCaretakerToServer(caretaker.copyWith(id: id));
    }
    return id;
  }

  /// Get all caretakers
  Future<List<Caretaker>> getAllCaretakers() async {
    final api = await _connectedApi();
    if (api != null) {
      return api.getCaretakersFromServer();
    }

    final db = await database;
    final result = await db.query(
      'caretakers',
      where: 'ownerUserId = ?',
      whereArgs: [_currentUserId],
      orderBy: 'createdAt DESC',
    );
    return result.map((m) => Caretaker.fromMap(m)).toList();
  }

  /// Get active caretakers
  Future<List<Caretaker>> getActiveCaretakers() async {
    final all = await getAllCaretakers();
    return all.where((c) => c.isActive).toList();
  }

  /// Update caretaker
  Future<int> updateCaretaker(int id, Caretaker caretaker) async {
    final db = await database;
    final updated = await db.update(
        'caretakers',
        {
          'firstName': caretaker.firstName,
          'lastName': caretaker.lastName,
          'phoneNumber': caretaker.phoneNumber,
          'email': caretaker.email,
          'relationship': caretaker.relationship,
          'notifyViaSMS': caretaker.notifyViaSMS ? 1 : 0,
          'notifyViaEmail': caretaker.notifyViaEmail ? 1 : 0,
          'notifyViaNotification': caretaker.notifyViaNotification ? 1 : 0,
          'isActive': caretaker.isActive ? 1 : 0,
        },
        where: 'id = ? AND ownerUserId = ?',
        whereArgs: [id, _currentUserId]);
    final api = await _connectedApi();
    if (api != null) {
      await api.saveCaretakerToServer(caretaker.copyWith(id: id));
    }
    return updated;
  }

  /// Delete caretaker
  Future<int> deleteCaretaker(int id) async {
    final db = await database;
    final deleted = await db.delete(
      'caretakers',
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.deleteCaretakerFromServer(id);
    }
    return deleted;
  }

  /// Toggle caretaker status
  Future<int> toggleCaretakerStatus(int id, bool isActive) async {
    final db = await database;
    final updated = await db.update(
      'caretakers',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
    );
    final existing = await db.query(
      'caretakers',
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final api = await _connectedApi();
      if (api != null) {
        await api.saveCaretakerToServer(Caretaker.fromMap(existing.first));
      }
    }
    return updated;
  }

  // ============= MISSED MEDICINE ALERTS =============

  /// Log missed medicine alert
  Future<int> logMissedAlert(MissedMedicineAlert alert) async {
    final db = await database;
    return await db.insert('missed_medicine_alerts', {
      'medicineId': alert.medicineId,
      'medicineName': alert.medicineName,
      'scheduledTime': alert.scheduledTime.toIso8601String(),
      'detectedTime': alert.detectedTime.toIso8601String(),
      'notificationSent': alert.notificationSent ? 1 : 0,
      'caretakersNotified': alert.caretakersNotified,
      'status': alert.status,
      'notes': alert.notes,
    });
  }

  /// Get all missed alerts
  Future<List<MissedMedicineAlert>> getMissedAlerts() async {
    final db = await database;
    final result =
        await db.query('missed_medicine_alerts', orderBy: 'detectedTime DESC');
    return result.map((m) => MissedMedicineAlert.fromMap(m)).toList();
  }

  /// Get pending alerts
  Future<List<MissedMedicineAlert>> getPendingAlerts() async {
    final db = await database;
    final result = await db.query('missed_medicine_alerts',
        where: 'status = ?', whereArgs: ['pending']);
    return result.map((m) => MissedMedicineAlert.fromMap(m)).toList();
  }

  /// Update alert status
  Future<int> updateAlertStatus(int id, String status, int count) async {
    final db = await database;
    return await db.update('missed_medicine_alerts',
        {'status': status, 'notificationSent': 1, 'caretakersNotified': count},
        where: 'id = ?', whereArgs: [id]);
  }

  // ============= REMINDER OPERATIONS =============

  /// Add a reminder
  Future<int> addReminder(Reminder reminder) async {
    final db = await database;
    final id = await db.insert('reminders', {
      'ownerUserId': _currentUserId,
      'medicineId': reminder.medicineId,
      'medicineName': reminder.medicineName,
      'time': reminder.time,
      'daysOfWeek': reminder.daysOfWeek.join(','),
      'isActive': reminder.isActive ? 1 : 0,
      'lastNotifiedAt': reminder.lastNotifiedAt?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    final api = await _connectedApi();
    if (api != null) {
      await api.saveReminderToServer(reminder.copyWith(id: id));
    }
    return id;
  }

  /// Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    final api = await _connectedApi();
    if (api != null) {
      return api.getRemindersFromServer();
    }

    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'ownerUserId = ?',
      whereArgs: [_currentUserId],
      orderBy: 'time ASC',
    );
    return result.map((m) => Reminder.fromMap(m)).toList();
  }

  /// Get active reminders
  Future<List<Reminder>> getActiveReminders() async {
    final all = await getAllReminders();
    return all.where((r) => r.isActive).toList();
  }

  /// Get reminders by medicine ID
  Future<List<Reminder>> getRemindersByMedicineId(int medicineId) async {
    final all = await getAllReminders();
    return all.where((r) => r.medicineId == medicineId).toList();
  }

  /// Update reminder
  Future<int> updateReminder(int id, Reminder reminder) async {
    final db = await database;
    final updated = await db.update(
        'reminders',
        {
          'medicineName': reminder.medicineName,
          'time': reminder.time,
          'daysOfWeek': reminder.daysOfWeek.join(','),
          'isActive': reminder.isActive ? 1 : 0,
          'lastNotifiedAt': reminder.lastNotifiedAt?.toIso8601String(),
        },
        where: 'id = ? AND ownerUserId = ?',
        whereArgs: [id, _currentUserId]);
    final api = await _connectedApi();
    if (api != null) {
      await api.saveReminderToServer(reminder.copyWith(id: id));
    }
    return updated;
  }

  /// Delete reminder
  Future<int> deleteReminder(int id) async {
    final db = await database;
    final deleted = await db.delete(
      'reminders',
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
    );
    final api = await _connectedApi();
    if (api != null) {
      await api.deleteReminderFromServer(id);
    }
    return deleted;
  }

  /// Toggle reminder status
  Future<int> toggleReminderStatus(int id, bool isActive) async {
    final db = await database;
    final updated = await db.update('reminders', {'isActive': isActive ? 1 : 0},
        where: 'id = ? AND ownerUserId = ?', whereArgs: [id, _currentUserId]);
    final existing = await db.query(
      'reminders',
      where: 'id = ? AND ownerUserId = ?',
      whereArgs: [id, _currentUserId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final api = await _connectedApi();
      if (api != null) {
        await api.saveReminderToServer(Reminder.fromMap(existing.first));
      }
    }
    return updated;
  }

  // ============= ALARM LOG OPERATIONS =============

  /// Log alarm
  Future<int> logAlarm(AlarmLog log) async {
    final db = await database;
    final id = await db.insert('alarm_logs', {
      'medicineId': log.medicineId,
      'medicineName': log.medicineName,
      'scheduledTime': log.scheduledTime.toIso8601String(),
      'triggeredTime': log.triggeredTime?.toIso8601String(),
      'status': log.status,
      'snoozeCount': log.snoozeCount,
      'takenAt': log.takenAt?.toIso8601String(),
      'notes': log.notes,
    });
    final api = await _connectedApi();
    if (api != null) {
      await api.logAlarmToServer(log.copyWith(id: id));
    }
    return id;
  }

  /// Get all alarm logs
  Future<List<AlarmLog>> getAllAlarmLogs() async {
    final api = await _connectedApi();
    if (api != null) {
      return api.getAlarmLogsFromServer();
    }

    final db = await database;
    final result = await db.query('alarm_logs', orderBy: 'scheduledTime DESC');
    return result.map((m) => AlarmLog.fromMap(m)).toList();
  }

  /// Get alarm logs by medicine ID
  Future<List<AlarmLog>> getAlarmLogsByMedicineId(int medicineId) async {
    final all = await getAllAlarmLogs();
    return all.where((a) => a.medicineId == medicineId).toList();
  }

  /// Get today's alarm logs
  Future<List<AlarmLog>> getTodayAlarmLogs() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final all = await getAllAlarmLogs();
    return all
        .where((a) =>
            !a.scheduledTime.isBefore(todayStart) &&
            a.scheduledTime.isBefore(todayEnd))
        .toList();
  }

  /// Update alarm log status
  Future<int> updateAlarmLogStatus(int id, String status,
      {int? snoozeCount, DateTime? takenAt}) async {
    final db = await database;
    final updates = {
      'status': status,
      if (snoozeCount != null) 'snoozeCount': snoozeCount,
      if (takenAt != null) 'takenAt': takenAt.toIso8601String(),
    };
    final updated = await db
        .update('alarm_logs', updates, where: 'id = ?', whereArgs: [id]);

    final log = await db.query('alarm_logs',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (log.isNotEmpty) {
      final api = await _connectedApi();
      if (api != null) {
        await api.logAlarmToServer(AlarmLog.fromMap(log.first));
      }
    }
    return updated;
  }

  /// Increment snooze count
  Future<int> incrementSnoozeCount(int id) async {
    final db = await database;
    final log = await db.query('alarm_logs', where: 'id = ?', whereArgs: [id]);
    if (log.isNotEmpty) {
      final currentSnooze = (log.first['snoozeCount'] as int?) ?? 0;
      return await db.update('alarm_logs', {'snoozeCount': currentSnooze + 1},
          where: 'id = ?', whereArgs: [id]);
    }
    return 0;
  }

  /// Mark alarm as taken
  Future<int> markAlarmAsTaken(int id) async {
    final db = await database;
    return await db.update('alarm_logs',
        {'status': 'taken', 'takenAt': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Mark alarm as missed
  Future<int> markAlarmAsMissed(int id) async {
    final db = await database;
    return await db.update('alarm_logs', {'status': 'missed'},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Get missed alarms for today
  Future<List<AlarmLog>> getTodayMissedAlarms() async {
    final today = await getTodayAlarmLogs();
    return today.where((a) => a.status == 'missed').toList();
  }

  // ============= USER PROFILE OPERATIONS =============

  // ============= BARCODE CACHE OPERATIONS =============

  Future<Map<String, dynamic>?> getBarcodeLookupCache(String barcode) async {
    final key = barcode.trim();
    if (key.isEmpty) return null;

    if (kIsWeb) {
      await initializeHiveBoxes();
      final map = _barcodeCacheBox?.get(key) as Map?;
      if (map == null) return null;
      return Map<String, dynamic>.from(map);
    }

    final db = await database;
    final result = await db.query(
      'barcode_lookup_cache',
      where: 'barcode = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> upsertBarcodeLookupCache({
    required String barcode,
    required String name,
    required String dosage,
    required String category,
  }) async {
    final key = barcode.trim();
    if (key.isEmpty) return;

    final map = {
      'barcode': key,
      'name': name,
      'dosage': dosage,
      'category': category,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      await initializeHiveBoxes();
      await _barcodeCacheBox?.put(key, map);
      return;
    }

    final db = await database;
    await db.insert(
      'barcode_lookup_cache',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save or update user profile
  Future<int> saveUserProfile(UserProfile profile) async {
    final api = await _connectedApi();
    if (api != null) {
      await api.saveUserProfileToServer(profile);
    }

    final db = await database;
    final existing = await db.query('user_profiles', limit: 1);

    final data = {
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'gender': profile.gender,
      'birthDate': profile.birthDate,
      'zipCode': profile.zipCode,
      'phoneNumber': profile.phoneNumber,
      'email': profile.email,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    int result;
    if (existing.isEmpty) {
      data['createdAt'] = DateTime.now().toIso8601String();
      result = await db.insert('user_profiles', data);
    } else {
      result = await db.update('user_profiles', data);
    }
    return result;
  }

  /// Get user profile
  Future<UserProfile?> getUserProfileData() async {
    final api = await _connectedApi();
    if (api != null) {
      final profile = await api.getUserProfileFromServer(_currentUserId);
      if (profile != null) {
        return profile;
      }
    }

    final db = await database;
    final result = await db.query('user_profiles', limit: 1);
    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }

  /// Register a new user
  Future<int> registerUser(String email, String password) async {
    final db = await database;
    return await db.insert('users', {
      'email': email,
      'password_hash': password, // In real app, hash this
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all registered users as email -> password map
  Future<Map<String, String>> getRegisteredUsers() async {
    final db = await database;
    final result = await db.query('users');
    final users = <String, String>{};
    for (final row in result) {
      users[row['email'] as String] = row['password_hash'] as String;
    }
    return users;
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  /// Update user
  Future<int> updateUser(int id, {String? email, String? passwordHash}) async {
    final db = await database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String()
    };
    if (email != null) updates['email'] = email;
    if (passwordHash != null) updates['password_hash'] = passwordHash;
    return await db.update('users', updates, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete user
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('notification_history');
    await db.delete('medicines');
    await db.delete('user_profiles');
    await db.delete('dependents');
    await db.delete('settings');
    await db.delete('barcode_lookup_cache');
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
