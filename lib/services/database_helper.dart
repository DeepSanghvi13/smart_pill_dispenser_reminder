// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/alarm_log.dart';
import '../models/user_profile.dart';
import '../models/caretaker.dart';
import '../services/medicine_repository.dart';

/// Helper class for database operations and testing
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final MedicineRepository _repo = MedicineRepository();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // ============= INITIALIZATION & SETUP =============

  /// Initialize app with sample data for testing
  /// Call this in main() only for development/testing
  Future<void> initializeSampleData() async {
    print('🔄 Initializing sample data...');

    try {
      // Check if data already exists
      final existing = await _repo.getAllMedicines();
      if (existing.isNotEmpty) {
        print('✅ Data already exists, skipping initialization');
        return;
      }

      // Create sample medicines
      final medicines = await _createSampleMedicines();

      // Create sample reminders
      await _createSampleReminders(medicines);

      // Create sample user profile
      await _createSampleUserProfile();

      // Create sample caretakers
      await _createSampleCaretakers();

      print('✅ Sample data initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
    }
  }

  /// Create sample medicines
  Future<List<int>> _createSampleMedicines() async {
    final medicines = [
      Medicine(
        name: 'Aspirin',
        dosage: '500mg',
        time: '09:00',
        category: MedicineCategory.tablets,
      ),
      Medicine(
        name: 'Cough Syrup',
        dosage: '10ml',
        time: '12:00',
        category: MedicineCategory.syrup,
      ),
      Medicine(
        name: 'Insulin',
        dosage: '10 units',
        time: '08:00',
        category: MedicineCategory.injection,
      ),
      Medicine(
        name: 'Vitamin D',
        dosage: '1000 IU',
        time: '18:00',
        category: MedicineCategory.tablets,
      ),
    ];

    List<int> ids = [];
    for (final med in medicines) {
      final id = await _repo.addMedicine(med);
      ids.add(id);
      print('✓ Added medicine: ${med.name} (ID: $id)');
    }

    return ids;
  }

  /// Create sample reminders
  Future<void> _createSampleReminders(List<int> medicineIds) async {
    final reminders = [
      Reminder(
        medicineId: medicineIds[0],
        medicineName: 'Aspirin',
        time: '09:00',
        daysOfWeek: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        isActive: true,
      ),
      Reminder(
        medicineId: medicineIds[1],
        medicineName: 'Cough Syrup',
        time: '12:00',
        daysOfWeek: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        isActive: true,
      ),
      Reminder(
        medicineId: medicineIds[2],
        medicineName: 'Insulin',
        time: '08:00',
        daysOfWeek: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        isActive: true,
      ),
    ];

    for (final reminder in reminders) {
      final id = await _repo.addReminder(reminder);
      print(
          '✓ Added reminder: ${reminder.medicineName} at ${reminder.time} (ID: $id)');
    }
  }

  /// Create sample user profile
  Future<void> _createSampleUserProfile() async {
    final profile = UserProfile(
      firstName: 'John',
      lastName: 'Doe',
      gender: 'Male',
      birthDate: '1980-01-15',
      zipCode: '12345',
      phoneNumber: '+1-555-0123',
      email: 'john.doe@example.com',
    );

    await _repo.saveUserProfile(profile);
    print('✓ Added user profile: ${profile.fullName}');
  }

  /// Create sample caretakers
  Future<void> _createSampleCaretakers() async {
    final caretakers = [
      Caretaker(
        firstName: 'Jane',
        lastName: 'Smith',
        phoneNumber: '+1-555-0456',
        email: 'jane.smith@example.com',
        relationship: 'Daughter',
        notifyViaSMS: true,
        notifyViaEmail: true,
        notifyViaNotification: true,
        isActive: true,
      ),
      Caretaker(
        firstName: 'Dr.',
        lastName: 'Johnson',
        phoneNumber: '+1-555-0789',
        email: 'dr.johnson@example.com',
        relationship: 'Doctor',
        notifyViaSMS: true,
        notifyViaEmail: true,
        notifyViaNotification: false,
        isActive: true,
      ),
    ];

    for (final caretaker in caretakers) {
      await _repo.addCaretaker(caretaker);
      print(
          '✓ Added caretaker: ${caretaker.fullName} (${caretaker.relationship})');
    }
  }

  // ============= TESTING & DEBUGGING =============

  /// Print all medicines to console
  Future<void> printAllMedicines() async {
    print('\n📋 ===== ALL MEDICINES =====');
    final medicines = await _repo.getAllMedicines();
    for (final med in medicines) {
      print('  ID: ${med.id}');
      print('  Name: ${med.name}');
      print('  Dosage: ${med.dosage}');
      print('  Time: ${med.time}');
      print('  Category: ${med.category.label} ${med.category.emoji}');
      print('  ---');
    }
    print('Total: ${medicines.length} medicines\n');
  }

  /// Print all reminders to console
  Future<void> printAllReminders() async {
    print('\n🔔 ===== ALL REMINDERS =====');
    final reminders = await _repo.getAllReminders();
    for (final rem in reminders) {
      print('  ID: ${rem.id}');
      print('  Medicine: ${rem.medicineName}');
      print('  Time: ${rem.time}');
      print('  Days: ${rem.daysOfWeek.join(", ")}');
      print('  Active: ${rem.isActive}');
      print('  ---');
    }
    print('Total: ${reminders.length} reminders\n');
  }

  /// Print today's alarms
  Future<void> printTodayAlarms() async {
    print('\n⏰ ===== TODAY\'S ALARMS =====');
    final alarms = await _repo.getTodayAlarmLogs();
    for (final alarm in alarms) {
      print('  ID: ${alarm.id}');
      print('  Medicine: ${alarm.medicineName}');
      print('  Scheduled: ${alarm.scheduledTime}');
      print('  Status: ${alarm.status}');
      print('  Snooze Count: ${alarm.snoozeCount}');
      print('  ---');
    }
    print('Total: ${alarms.length} alarms\n');
  }

  /// Print missed alarms
  Future<void> printMissedAlarms() async {
    print('\n❌ ===== MISSED ALARMS =====');
    final missed = await _repo.getTodayMissedAlarms();
    for (final alarm in missed) {
      print('  ID: ${alarm.id}');
      print('  Medicine: ${alarm.medicineName}');
      print('  Scheduled: ${alarm.scheduledTime}');
      print('  ---');
    }
    print('Total: ${missed.length} missed\n');
  }

  /// Print user profile
  Future<void> printUserProfile() async {
    print('\n👤 ===== USER PROFILE =====');
    final profile = await _repo.getUserProfile();
    if (profile != null) {
      print('  Name: ${profile.fullName}');
      print('  Email: ${profile.email}');
      print('  Phone: ${profile.phoneNumber}');
      print('  Birth Date: ${profile.birthDate}');
      print('  Gender: ${profile.gender}');
      print('  Zip Code: ${profile.zipCode}');
    } else {
      print('  No profile found');
    }
    print('');
  }

  /// Print all caretakers
  Future<void> printAllCaretakers() async {
    print('\n👥 ===== ALL CARETAKERS =====');
    final caretakers = await _repo.getAllCaretakers();
    for (final ct in caretakers) {
      print('  ID: ${ct.id}');
      print('  Name: ${ct.fullName}');
      print('  Relationship: ${ct.relationship}');
      print('  Email: ${ct.email}');
      print('  Phone: ${ct.phoneNumber}');
      print('  Active: ${ct.isActive}');
      print('  ---');
    }
    print('Total: ${caretakers.length} caretakers\n');
  }

  /// Print database statistics
  Future<void> printDatabaseStats() async {
    print('\n📊 ===== DATABASE STATISTICS =====');

    final medicines = await _repo.getAllMedicines();
    print('Medicines: ${medicines.length}');

    final reminders = await _repo.getAllReminders();
    print('Reminders: ${reminders.length}');

    final todayAlarms = await _repo.getTodayAlarmLogs();
    print('Today\'s Alarms: ${todayAlarms.length}');

    final missedAlarms = await _repo.getTodayMissedAlarms();
    print('Missed Alarms: ${missedAlarms.length}');

    final caretakers = await _repo.getAllCaretakers();
    print('Caretakers: ${caretakers.length}');

    final profile = await _repo.getUserProfile();
    print('User Profile: ${profile != null ? 'Yes' : 'No'}');

    print('');
  }

  /// Full database dump
  Future<void> fullDump() async {
    print('\n' + '=' * 50);
    print('📂 FULL DATABASE DUMP');
    print('=' * 50);

    await printUserProfile();
    await printAllMedicines();
    await printAllReminders();
    await printAllCaretakers();
    await printTodayAlarms();
    await printMissedAlarms();
    await printDatabaseStats();

    print('=' * 50 + '\n');
  }

  // ============= UTILITY METHODS =============

  /// Create test alarm log
  Future<int?> createTestAlarm(int medicineId, String medicineName) async {
    final now = DateTime.now();
    final alarm = AlarmLog(
      medicineId: medicineId,
      medicineName: medicineName,
      scheduledTime: now,
      triggeredTime: now,
      status: 'triggered',
    );
    return await _repo.logAlarm(alarm);
  }

  /// Get medicine statistics
  Future<Map<String, dynamic>> getMedicineStats() async {
    final medicines = await _repo.getAllMedicines();
    final categories = <String, int>{};

    for (final med in medicines) {
      categories.update(med.category.label, (v) => v + 1, ifAbsent: () => 1);
    }

    return {
      'total': medicines.length,
      'categories': categories,
    };
  }

  /// Get today's summary
  Future<Map<String, dynamic>> getTodaySummary() async {
    final todayAlarms = await _repo.getTodayAlarmLogs();
    final missedAlarms = await _repo.getTodayMissedAlarms();

    final taken = todayAlarms.where((a) => a.status == 'taken').length;
    final pending = todayAlarms.where((a) => a.status == 'triggered').length;
    final snoozed = todayAlarms.where((a) => a.status == 'snoozed').length;

    return {
      'total': todayAlarms.length,
      'taken': taken,
      'pending': pending,
      'snoozed': snoozed,
      'missed': missedAlarms.length,
      'adherenceRate': todayAlarms.isEmpty
          ? 0
          : (taken / todayAlarms.length * 100).toStringAsFixed(2),
    };
  }

  /// Health check
  Future<Map<String, bool>> healthCheck() async {
    try {
      final medicines = await _repo.getAllMedicines();
      final reminders = await _repo.getAllReminders();
      final profile = await _repo.getUserProfile();
      final caretakers = await _repo.getAllCaretakers();

      return {
        'databaseOk': true,
        'hasMedicines': medicines.isNotEmpty,
        'hasReminders': reminders.isNotEmpty,
        'hasProfile': profile != null,
        'hasCaretakers': caretakers.isNotEmpty,
      };
    } catch (e) {
      print('Health check failed: $e');
      return {
        'databaseOk': false,
        'hasMedicines': false,
        'hasReminders': false,
        'hasProfile': false,
        'hasCaretakers': false,
      };
    }
  }
}
