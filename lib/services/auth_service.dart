import 'package:flutter/material.dart';

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

  /// Login user with email and password
  /// For admin access, use email: admin@medisafe.com, password: admin123
  Future<bool> login(String email, String password) async {
    try {
      // Simulate async operation (in real app, this would be API call)
      await Future.delayed(const Duration(seconds: 1));

      // Check for admin credentials
      if (email == 'admin@medisafe.com' && password == 'admin123') {
        _currentUser = email;
        _isAdmin = true;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }

      // Check for regular user credentials
      if (email.isNotEmpty && password.isNotEmpty && password.length >= 6) {
        _currentUser = email;
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
}

// Global instance
final authService = AuthService();

