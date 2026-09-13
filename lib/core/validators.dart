import 'package:flutter/services.dart';

class AppValidators {
  static final RegExp _gmailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@gmail\.com$',
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(r'^[0-9]{10}$');
  static final RegExp _licenseRegex = RegExp(r'^[0-9]{5}$');

  /// Known admin emails that bypass the Gmail-only restriction
  static const List<String> adminEmails = [
    'admin@smartpill.com',
    'admin@medisafe.com',
  ];

  /// Common input formatters for 10-digit numeric phone fields
  static List<TextInputFormatter> get phoneInputFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];

  /// Common input formatters for exactly 5-digit numeric doctor license fields
  static List<TextInputFormatter> get licenseInputFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ];

  /// Checks whether an email address is a valid Gmail address ending with @gmail.com
  static bool isValidGmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return _gmailRegex.hasMatch(trimmed);
  }

  /// Checks whether a phone number contains exactly 10 numeric digits
  static bool isValidPhone(String? phone) {
    if (phone == null) return false;
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return false;
    return _phoneRegex.hasMatch(trimmed);
  }

  /// Checks if an email is a predefined admin email
  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim().toLowerCase();
    return adminEmails.contains(trimmed) || trimmed.startsWith('admin@');
  }

  /// Form validator for Gmail fields
  static String? validateGmail(
    String? value, {
    bool isRequired = true,
    bool allowAdmin = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter your email' : null;
    }

    final trimmed = value.trim();

    if (allowAdmin && isAdminEmail(trimmed)) {
      return null;
    }

    if (!_gmailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid Gmail address ending with @gmail.com.';
    }

    return null;
  }

  /// Checks whether a medical license number contains exactly 5 numeric digits
  static bool isValidLicense(String? license) {
    if (license == null) return false;
    final trimmed = license.trim();
    if (trimmed.isEmpty) return false;
    return _licenseRegex.hasMatch(trimmed);
  }

  /// Form validator for 10-digit phone fields
  static String? validatePhone(
    String? value, {
    bool isRequired = true,
    String? requiredMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? (requiredMessage ?? 'Phone number must be exactly 10 digits.') : null;
    }

    final trimmed = value.trim();

    if (!_phoneRegex.hasMatch(trimmed)) {
      return 'Phone number must be exactly 10 digits.';
    }

    return null;
  }

  /// Form validator for 5-digit doctor license fields
  static String? validateLicense(
    String? value, {
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Medical license/registration number must be exactly 5 digits.' : null;
    }

    final trimmed = value.trim();

    if (!_licenseRegex.hasMatch(trimmed)) {
      return 'Medical license/registration number must be exactly 5 digits.';
    }

    return null;
  }
}
