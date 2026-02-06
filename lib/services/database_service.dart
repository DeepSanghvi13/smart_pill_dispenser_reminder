import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseService {

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {

    /// Desktop initialization
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'smart_pill.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medicine_name TEXT,
            dosage TEXT,
            reminder_time TEXT
          )
        ''');

      },
    );
  }

  Future<void> insertMedicine({
    required String name,
    required String dosage,
    required String time,
  }) async {

    final db = await database;

    await db.insert('medicines', {
      'medicine_name': name,
      'dosage': dosage,
      'reminder_time': time,
    });
  }

}
