import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';
import '../models/medicine.dart';
import '../models/caretaker.dart';
import '../models/missed_medicine_alert.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static Box<dynamic>? _medicinesBox;
  static Box<dynamic>? _userBox;
  static Box<dynamic>? _dependentsBox;
  static Box<dynamic>? _caretakersBox;
  static Box<dynamic>? _remindersBox;
  static Box<dynamic>? _settingsBox;
  static int _medicineIdCounter = 0;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Initialize Hive boxes for web
  Future<void> initializeHiveBoxes() async {
    if (kIsWeb) {
      try {
        _medicinesBox = await Hive.openBox('medicines');
        _userBox = await Hive.openBox('user_profile');
        _dependentsBox = await Hive.openBox('dependents');
        _caretakersBox = await Hive.openBox('caretakers');
        _remindersBox = await Hive.openBox('reminders');
        _settingsBox = await Hive.openBox('settings');

        // Initialize counter if not exists
        if (!_medicinesBox!.containsKey('_idCounter')) {
          _medicinesBox!.put('_idCounter', 0);
        }
        _medicineIdCounter = _medicinesBox!.get('_idCounter', defaultValue: 0) ?? 0;
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
    );
  }


  /// Create all tables
  Future<void> _createTables(Database db, int version) async {
    // Medicine table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        category TEXT DEFAULT 'tablets',
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
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'category': medicine.category.name,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _medicinesBox!.put('med_$_medicineIdCounter', medicineMap);
      await _medicinesBox!.put('_idCounter', _medicineIdCounter);
      return _medicineIdCounter;
    }

    // Native implementation using SQLite
    final db = await database;
    return await db.insert(
      'medicines',
      {
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get all medicines (works on web and native)
  Future<List<Medicine>> getAllMedicines() async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      final medicines = <Medicine>[];
      for (var key in _medicinesBox!.keys) {
        if (key == '_idCounter') continue; // Skip counter
        final data = _medicinesBox!.get(key) as Map?;
        if (data != null) {
          medicines.add(Medicine(
            id: data['id'] as int?,
            name: data['name'] as String,
            dosage: data['dosage'] as String,
            time: data['time'] as String,
            category: MedicineCategory.fromString(data['category'] as String? ?? 'tablets'),
          ));
        }
      }
      return medicines;
    }

    // Native implementation using SQLite
    final db = await database;
    final result = await db.query('medicines');
    return result.map((map) => Medicine.fromMap(map)).toList();
  }

  /// Get medicine by ID (works on web and native)
  Future<Medicine?> getMedicineById(int id) async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      final data = _medicinesBox!.get('med_$id') as Map?;
      if (data != null) {
        return Medicine(
          id: data['id'] as int?,
          name: data['name'] as String,
          dosage: data['dosage'] as String,
          time: data['time'] as String,
          category: MedicineCategory.fromString(data['category'] as String? ?? 'tablets'),
        );
      }
      return null;
    }

    // Native implementation using SQLite
    final db = await database;
    final result = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
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
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
        'category': medicine.category.name,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _medicinesBox!.put('med_$id', medicineMap);
      return 1; // Return 1 to indicate success
    }

    // Native implementation using SQLite
    final db = await database;
    return await db.update(
      'medicines',
      {
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': medicine.time,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete medicine (works on web and native)
  Future<int> deleteMedicine(int id) async {
    if (kIsWeb) {
      // Web implementation using Hive
      await initializeHiveBoxes();
      await _medicinesBox!.delete('med_$id');
      return 1; // Return 1 to indicate success
    }

    // Native implementation using SQLite
    final db = await database;
    return await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= SETTINGS OPERATIONS =============

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
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
    return await db.query('notification_history', orderBy: 'scheduledTime DESC');
  }

  // ============= USER PROFILE OPERATIONS =============

  /// Save user profile
  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    String? gender,
    String? birthDate,
    String? zipCode,
  }) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'birthDate': birthDate,
        'zipCode': zipCode,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;
    final result = await db.query('user_profiles', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
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
    return await db.insert(
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
  }

  /// Get all dependents
  Future<List<Map<String, dynamic>>> getAllDependents() async {
    final db = await database;
    return await db.query('dependents');
  }

  /// Delete dependent
  Future<int> deleteDependent(int id) async {
    final db = await database;
    return await db.delete(
      'dependents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= CARETAKER OPERATIONS =============

  /// Add caretaker
  Future<int> addCaretaker(Caretaker caretaker) async {
    final db = await database;
    return await db.insert('caretakers', {
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
  }

  /// Get all caretakers
  Future<List<Caretaker>> getAllCaretakers() async {
    final db = await database;
    final result = await db.query('caretakers', orderBy: 'createdAt DESC');
    return result.map((m) => Caretaker.fromMap(m)).toList();
  }

  /// Get active caretakers
  Future<List<Caretaker>> getActiveCaretakers() async {
    final db = await database;
    final result = await db.query('caretakers', where: 'isActive = ?', whereArgs: [1]);
    return result.map((m) => Caretaker.fromMap(m)).toList();
  }

  /// Update caretaker
  Future<int> updateCaretaker(int id, Caretaker caretaker) async {
    final db = await database;
    return await db.update('caretakers', {
      'firstName': caretaker.firstName,
      'lastName': caretaker.lastName,
      'phoneNumber': caretaker.phoneNumber,
      'email': caretaker.email,
      'relationship': caretaker.relationship,
      'notifyViaSMS': caretaker.notifyViaSMS ? 1 : 0,
      'notifyViaEmail': caretaker.notifyViaEmail ? 1 : 0,
      'notifyViaNotification': caretaker.notifyViaNotification ? 1 : 0,
      'isActive': caretaker.isActive ? 1 : 0,
    }, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete caretaker
  Future<int> deleteCaretaker(int id) async {
    final db = await database;
    return await db.delete('caretakers', where: 'id = ?', whereArgs: [id]);
  }

  /// Toggle caretaker status
  Future<int> toggleCaretakerStatus(int id, bool isActive) async {
    final db = await database;
    return await db.update('caretakers', {'isActive': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
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
    final result = await db.query('missed_medicine_alerts', orderBy: 'detectedTime DESC');
    return result.map((m) => MissedMedicineAlert.fromMap(m)).toList();
  }

  /// Get pending alerts
  Future<List<MissedMedicineAlert>> getPendingAlerts() async {
    final db = await database;
    final result = await db.query('missed_medicine_alerts', where: 'status = ?', whereArgs: ['pending']);
    return result.map((m) => MissedMedicineAlert.fromMap(m)).toList();
  }

  /// Update alert status
  Future<int> updateAlertStatus(int id, String status, int count) async {
    final db = await database;
    return await db.update('missed_medicine_alerts',
      {'status': status, 'notificationSent': 1, 'caretakersNotified': count},
      where: 'id = ?', whereArgs: [id]);
  }


  // ============= DATABASE CLEANUP =============

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('notification_history');
    await db.delete('medicines');
    await db.delete('user_profiles');
    await db.delete('dependents');
    await db.delete('settings');
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

