import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication service to handle user login and admin access
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Current user state
  String? _currentUser;
  bool _isAdmin = false;
  bool _isLoggedIn = false;

  // Getters
  String? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _isLoggedIn;

  // Store registered users as email -> password in local preferences.
  static const String _usersStoreKey = 'registered_users';

  Future<Map<String, String>> _getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_usersStoreKey) ?? <String>[];
    final users = <String, String>{};
    for (final row in raw) {
      final parts = row.split('::');
      if (parts.length == 2) {
        users[parts[0]] = parts[1];
      }
    }
    return users;
  }

  Future<void> _saveRegisteredUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = users.entries.map((e) => '${e.key}::${e.value}').toList();
    await prefs.setStringList(_usersStoreKey, raw);
  }

  /// Register a new user (email/password).
  Future<bool> register(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty || password.length < 6) {
        return false;
      }

      if (normalizedEmail == 'admin@medisafe.com') {
        return false;
      }

      final users = await _getRegisteredUsers();
      if (users.containsKey(normalizedEmail)) {
        return false;
      }

      users[normalizedEmail] = password;
      await _saveRegisteredUsers(users);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login user with email and password
  /// For admin access, use email: admin@medisafe.com, password: admin123
  Future<bool> login(String email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 450));

      final normalizedEmail = email.trim().toLowerCase();

      // Check for admin credentials
      if (normalizedEmail == 'admin@medisafe.com' && password == 'admin123') {
        _currentUser = normalizedEmail;
        _isAdmin = true;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }

      // Check for registered user credentials
      final users = await _getRegisteredUsers();
      if (users[normalizedEmail] == password) {
        _currentUser = normalizedEmail;
        _isAdmin = false;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Login user with Google account (simulated)
  Future<bool> loginWithGoogle() async {
    try {
      // Simulate Google auth delay
      await Future.delayed(const Duration(milliseconds: 800));

      _currentUser = 'google.user@medisafe.com';
      _isAdmin = false;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout user
  void logout() {
    _currentUser = null;
    _isAdmin = false;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Check if user is admin
  bool checkAdminAccess() {
    return _isAdmin;
  }

  /// Check whether user is already registered.
  Future<bool> isRegistered(String email) async {
    final users = await _getRegisteredUsers();
    return users.containsKey(email.trim().toLowerCase());
  }
}

// Global instance
final authService = AuthService();

