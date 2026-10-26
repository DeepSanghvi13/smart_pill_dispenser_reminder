import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pill_reminder/models/medicine.dart';
import 'package:smart_pill_reminder/models/reminder.dart';
import 'package:smart_pill_reminder/services/auth_service.dart';

void main() {
  group('Bug 1: Prescribed Dose Times', () {
    test('doseTimes correctly parses single dose time', () {
      final med = Medicine(
        id: 1,
        userId: 'test@gmail.com',
        name: 'Paracetamol',
        type: 'Tablets',
        dosage: '500mg',
        quantity: '1',
        frequency: 'Daily',
        time: '08:00 AM',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(med.doseTimes, ['08:00 AM']);
    });

    test('doseTimes parses multiple prescribed dose times without assumptions', () {
      final medTwice = Medicine(
        id: 2,
        userId: 'test@gmail.com',
        name: 'Amoxicillin',
        type: 'Tablets',
        dosage: '250mg',
        quantity: '1',
        frequency: 'Twice a day',
        time: '09:00 AM, 09:00 PM',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(medTwice.doseTimes, ['09:00 AM', '09:00 PM']);

      final medThree = Medicine(
        id: 3,
        userId: 'test@gmail.com',
        name: 'Metformin',
        type: 'Tablets',
        dosage: '500mg',
        quantity: '1',
        frequency: 'Three times a day',
        time: '08:00 AM, 02:00 PM, 08:00 PM',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      expect(medThree.doseTimes, ['08:00 AM', '02:00 PM', '08:00 PM']);
    });

    test('doseTimes handles trimming and empty strings safely', () {
      final med = Medicine(
        id: 4,
        userId: 'test@gmail.com',
        name: 'Aspirin',
        type: 'Tablets',
        dosage: '100mg',
        quantity: '1',
        frequency: 'Twice a day',
        time: '  08:00 AM , , 08:00 PM  ',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(med.doseTimes, ['08:00 AM', '08:00 PM']);
    });
  });

  group('Bug 2: Reminder Weekdays & Model Integration', () {
    test('Reminder stores days of week and time accurately', () {
      final reminder = Reminder(
        id: 10,
        medicineId: 1,
        medicineName: 'Paracetamol',
        time: '08:30 AM',
        daysOfWeek: ['Mon', 'Wed', 'Fri'],
        isActive: true,
      );

      expect(reminder.time, '08:30 AM');
      expect(reminder.daysOfWeek, ['Mon', 'Wed', 'Fri']);
      expect(reminder.isActive, isTrue);

      final map = reminder.toMap();
      expect(map['daysOfWeek'], 'Mon,Wed,Fri');

      final fromMap = Reminder.fromMap(map);
      expect(fromMap.daysOfWeek, ['Mon', 'Wed', 'Fri']);
      expect(fromMap.time, '08:30 AM');
      expect(fromMap.isActive, isTrue);
    });
  });

  group('Bug 4 & Password Security: Password Hashing & Verification', () {
    test('hashPassword generates valid SHA-256 hash', () {
      final hash1 = AuthService.hashPassword('securepassword123');
      final hash2 = AuthService.hashPassword('securepassword123');
      final hashDiff = AuthService.hashPassword('differentpassword');

      expect(hash1.length, 64);
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDiff)));
    });

    test('verifyPassword authenticates both hashed and legacy plaintext passwords', () {
      final plain = 'patientPassword2026';
      final hashed = AuthService.hashPassword(plain);

      // Verify hashed password
      expect(AuthService.verifyPassword(plain, hashed), isTrue);
      expect(AuthService.verifyPassword('wrongPassword', hashed), isFalse);

      // Verify legacy plaintext fallback
      expect(AuthService.verifyPassword('legacyPass', 'legacyPass'), isTrue);
      expect(AuthService.verifyPassword('wrongLegacy', 'legacyPass'), isFalse);
    });
  });

  group('Bug 6: Expiry Status Classification', () {
    test('Correctly identifies expired medicines', () {
      final expiredMed = Medicine(
        id: 5,
        userId: 'test@gmail.com',
        name: 'Old Cough Syrup',
        type: 'Syrup',
        dosage: '10ml',
        quantity: '1',
        frequency: 'Daily',
        time: '08:00 AM',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(expiredMed.isExpired, isTrue);
      expect(expiredMed.expiryStatus, equals(MedicineExpiryStatus.expired));
    });

    test('Correctly identifies expiring soon medicines', () {
      final expiringMed = Medicine(
        id: 6,
        userId: 'test@gmail.com',
        name: 'Antibiotic Drop',
        type: 'Drops',
        dosage: '2 drops',
        quantity: '1',
        frequency: 'Daily',
        time: '08:00 AM',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );

      expect(expiringMed.isExpiringSoon, isTrue);
      expect(expiringMed.isExpired, isFalse);
      expect(expiringMed.expiryStatus, equals(MedicineExpiryStatus.expiringSoon));
    });

    test('Correctly identifies active medicines with far expiry', () {
      final activeMed = Medicine(
        id: 7,
        userId: 'test@gmail.com',
        name: 'Vitamin D3',
        type: 'Tablets',
        dosage: '1000 IU',
        quantity: '1',
        frequency: 'Daily',
        time: '08:00 AM',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 180)),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
      );

      expect(activeMed.isExpired, isFalse);
      expect(activeMed.isExpiringSoon, isFalse);
      expect(activeMed.expiryStatus, equals(MedicineExpiryStatus.active));
    });
  });
}
