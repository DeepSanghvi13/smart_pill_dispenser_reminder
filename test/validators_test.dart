import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pill_reminder/core/validators.dart';

void main() {
  group('AppValidators - Gmail Validation', () {
    test('accepts valid Gmail addresses', () {
      expect(AppValidators.isValidGmail('example@gmail.com'), isTrue);
      expect(AppValidators.isValidGmail('deep123@gmail.com'), isTrue);
      expect(AppValidators.isValidGmail('test.user@gmail.com'), isTrue);
      expect(AppValidators.isValidGmail('user+tag@gmail.com'), isTrue);
      expect(AppValidators.isValidGmail('USER@GMAIL.COM'), isTrue);
    });

    test('rejects non-Gmail addresses', () {
      expect(AppValidators.isValidGmail('example@yahoo.com'), isFalse);
      expect(AppValidators.isValidGmail('example@hotmail.com'), isFalse);
      expect(AppValidators.isValidGmail('example@gmail.co'), isFalse);
      expect(AppValidators.isValidGmail('example@gmail'), isFalse);
      expect(AppValidators.isValidGmail('example@outlook.com'), isFalse);
      expect(AppValidators.isValidGmail('@gmail.com'), isFalse);
      expect(AppValidators.isValidGmail('example@gmail.com.com'), isFalse);
      expect(AppValidators.isValidGmail(''), isFalse);
      expect(AppValidators.isValidGmail(null), isFalse);
    });

    test('validateGmail returns correct error message', () {
      expect(
        AppValidators.validateGmail('example@yahoo.com'),
        equals('Please enter a valid Gmail address ending with @gmail.com.'),
      );
      expect(
        AppValidators.validateGmail('example@gmail.com'),
        isNull,
      );
      expect(
        AppValidators.validateGmail(''),
        equals('Please enter your email'),
      );
    });

    test('validateGmail allows admin emails when allowAdmin is true', () {
      expect(
        AppValidators.validateGmail('admin@smartpill.com', allowAdmin: true),
        isNull,
      );
      expect(
        AppValidators.validateGmail('admin@medisafe.com', allowAdmin: true),
        isNull,
      );
      expect(
        AppValidators.validateGmail('admin@smartpill.com', allowAdmin: false),
        equals('Please enter a valid Gmail address ending with @gmail.com.'),
      );
    });
  });

  group('AppValidators - Phone Number Validation', () {
    test('accepts exactly 10 numeric digits', () {
      expect(AppValidators.isValidPhone('9876543210'), isTrue);
      expect(AppValidators.isValidPhone('9012345678'), isTrue);
      expect(AppValidators.isValidPhone('0123456789'), isTrue);
    });

    test('rejects invalid phone numbers', () {
      expect(AppValidators.isValidPhone('987654321'), isFalse); // 9 digits
      expect(AppValidators.isValidPhone('98765432101'), isFalse); // 11 digits
      expect(AppValidators.isValidPhone('98765abc10'), isFalse); // letters
      expect(AppValidators.isValidPhone('98765-43210'), isFalse); // hyphen
      expect(AppValidators.isValidPhone('98765 43210'), isFalse); // space
      expect(AppValidators.isValidPhone(''), isFalse);
      expect(AppValidators.isValidPhone(null), isFalse);
    });

    test('validatePhone returns correct error message', () {
      expect(
        AppValidators.validatePhone('987654321'),
        equals('Phone number must be exactly 10 digits.'),
      );
      expect(
        AppValidators.validatePhone('98765432101'),
        equals('Phone number must be exactly 10 digits.'),
      );
      expect(
        AppValidators.validatePhone('98765abc10'),
        equals('Phone number must be exactly 10 digits.'),
      );
      expect(
        AppValidators.validatePhone('9876543210'),
        isNull,
      );
    });
  });
}
