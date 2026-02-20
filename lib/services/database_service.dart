import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/medicine.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initializeDatabase() async {
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
  }

  // ============= MEDICINE OPERATIONS =============

  /// Add a new medicine
  Future<int> addMedicine(Medicine medicine) async {
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

  /// Get all medicines
  Future<List<Medicine>> getAllMedicines() async {
    final db = await database;
    final result = await db.query('medicines');
    return result.map((map) => Medicine.fromMap(map)).toList();
  }

  /// Get medicine by ID
  Future<Medicine?> getMedicineById(int id) async {
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

  /// Update medicine
  Future<int> updateMedicine(int id, Medicine medicine) async {
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

  /// Delete medicine
  Future<int> deleteMedicine(int id) async {
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

