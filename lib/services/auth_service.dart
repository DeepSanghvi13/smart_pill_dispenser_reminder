import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'mysql_api_service.dart';
import 'mysql_sync_helper.dart';

/// Authentication service to handle user login and admin access
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static const String _keyPendingSync = 'pending_mysql_sync';

  // SharedPreferences keys
  static const String _keyEmail = 'session_email';
  static const String _keyIsAdmin = 'session_is_admin';
  static const String _keyLoggedIn = 'session_logged_in';

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Current user state
  String? _currentUser;
  bool _isAdmin = false;
  bool _isLoggedIn = false;
  int? _currentUserId;
  bool _isSyncingBackground = false;

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

      final api = MySQLApiService();
      final exists = await api.isEmailRegistered(normalizedEmail);
      if (exists) {
        return false;
      }

      return await api.registerUser(normalizedEmail, password);
    } catch (_) {
      return false;
    }
  }

  /// Restore a previously saved session from SharedPreferences.
  /// Call this once in main() before runApp().
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      if (!loggedIn) return;

      final email = prefs.getString(_keyEmail);
      final isAdmin = prefs.getBool(_keyIsAdmin) ?? false;

      if (email == null || email.isEmpty) return;

      _currentUser = email;
      _isAdmin = isAdmin;
      _isLoggedIn = true;
      await _configureAndSync(email);
      notifyListeners();
    } catch (_) {
      // Ignore — fresh start is fine
    }
  }

  /// Checks whether any user (by any email) is registered on this device.
  Future<bool> hasAnyRegisteredUser() async {
    try {
      final totalUsers = await MySQLApiService().getTotalRegisteredUsers();
      return totalUsers > 0;
    } catch (_) {
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
        _currentUserId = null;
        await _saveSession(normalizedEmail, isAdmin: true);
        await _configureAndSync(normalizedEmail);
        notifyListeners();
        return true;
      }

      final response =
          await MySQLApiService().loginUser(normalizedEmail, password);
      if (response != null) {
        _currentUser = response['email'] as String? ?? normalizedEmail;
        _isAdmin = response['isAdmin'] == true;
        _isLoggedIn = true;
        _currentUserId = response['id'] as int?;
        await _saveSession(_currentUser!, isAdmin: _isAdmin);
        await _configureAndSync(_currentUser!);
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
      await Future.delayed(const Duration(milliseconds: 800));

      _currentUser = 'google.user@medisafe.com';
      _isAdmin = false;
      _isLoggedIn = true;
      await _saveSession(_currentUser!, isAdmin: false);
      await _configureAndSync(_currentUser!);
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
    _clearSession();
    DatabaseService().setCurrentUser(null);
    MySQLApiService().configure(userId: 'guest', authToken: null);
    notifyListeners();
  }

  // ---- private helpers ----

  Future<void> _saveSession(String email, {required bool isAdmin}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, email);
      await prefs.setBool(_keyIsAdmin, isAdmin);
      await prefs.setBool(_keyLoggedIn, true);
    } catch (_) {}
  }

  void _clearSession() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_keyEmail);
      prefs.remove(_keyIsAdmin);
      prefs.remove(_keyLoggedIn);
    }).catchError((_) {});
  }

  Future<void> _configureAndSync(String userId) async {
    // Tell the MySQL service which user this is
    await DatabaseService().setCurrentUser(userId);
    final api = MySQLApiService();
    api.configure(userId: userId);

    if (_isSyncingBackground) return;

    // Bulk sync in background — errors are swallowed inside syncAll
    Future.microtask(() async {
      _isSyncingBackground = true;
      final db = DatabaseService();
      try {
        final prefs = await SharedPreferences.getInstance();
        final isServerAvailable = await api.checkServerConnection();
        if (!isServerAvailable) {
          await prefs.setBool(_keyPendingSync, true);
          return;
        }

        final medicines = await db.getAllMedicines();
        final reminders = await db.getAllReminders();
        final alarmLogs = await db.getAllAlarmLogs();
        final caretakers = await db.getAllCaretakers();
        final profile = await db.getUserProfileData();

        final synced = await MySQLSyncHelper.syncAll(
          userId: userId,
          medicines: medicines,
          reminders: reminders,
          alarmLogs: alarmLogs,
          caretakers: caretakers,
          userProfile: profile,
        );
        await prefs.setBool(_keyPendingSync, !synced);
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyPendingSync, true);
        // ignore — offline is fine
      } finally {
        _isSyncingBackground = false;
      }
    });
  }

  /// Check if user is admin
  bool checkAdminAccess() {
    return _isAdmin;
  }

  /// Check whether user is already registered.
  Future<bool> isRegistered(String email) async {
    return MySQLApiService().isEmailRegistered(email.trim().toLowerCase());
  }
}

// Global instance
final authService = AuthService();
