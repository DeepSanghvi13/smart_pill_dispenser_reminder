import 'package:flutter/material.dart';
import 'database_service.dart';

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
  int? _currentUserId;

  // Getters
  String? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _isLoggedIn;
  int? get currentUserId => _currentUserId;

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

      final users = await DatabaseService().getRegisteredUsers();
      if (users.containsKey(normalizedEmail)) {
        return false;
      }

      await DatabaseService().registerUser(normalizedEmail, password);
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
      final users = await DatabaseService().getRegisteredUsers();
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
    final users = await DatabaseService().getRegisteredUsers();
    return users.containsKey(email.trim().toLowerCase());
  }
}

// Global instance
final authService = AuthService();

