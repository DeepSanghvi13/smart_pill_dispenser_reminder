import 'package:flutter/material.dart';
import 'hive_service.dart';
import 'database_service.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Current user session details
  String? _currentUser;
  bool _isLoggedIn = false;

  String? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Key for session storage in Hive settings box
  static const String _sessionKey = 'current_user_session';

  /// Register a new user locally.
  Future<String?> registerWithMessage(String name, String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        return 'Email cannot be empty.';
      }
      if (password.length < 8) {
        return 'Password must be at least 8 characters.';
      }

      final box = HiveService().usersBox;
      if (box.containsKey(normalizedEmail)) {
        return 'Email already registered. Please login.';
      }

      final newUser = User(
        fullName: name,
        email: normalizedEmail,
        password: password,
      );
      await box.put(normalizedEmail, newUser);

      // Create a default profile automatically with the provided name
      final profileBox = HiveService().profilesBox;
      final defaultProfile = UserProfile(
        email: normalizedEmail,
        fullName: name,
      );
      await profileBox.put(normalizedEmail, defaultProfile);

      return null; // Success
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  /// Restore session from Hive settings box
  Future<void> loadSession() async {
    try {
      final settings = HiveService().settingsBox;
      final email = settings.get(_sessionKey) as String?;
      if (email != null && email.isNotEmpty) {
        _currentUser = email;
        _isLoggedIn = true;
        await DatabaseService().setCurrentUser(email);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Login local user
  Future<bool> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final box = HiveService().usersBox;
      
      if (!box.containsKey(normalizedEmail)) {
        return false;
      }

      final user = box.get(normalizedEmail);
      if (user != null && user.password == password) {
        _currentUser = normalizedEmail;
        _isLoggedIn = true;
        
        // Save session
        final settings = HiveService().settingsBox;
        await settings.put(_sessionKey, normalizedEmail);

        await DatabaseService().setCurrentUser(normalizedEmail);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the logged-in user has created/completed their profile
  bool hasCompletedProfile() {
    if (_currentUser == null) return false;
    final profile = HiveService().profilesBox.get(_currentUser);
    if (profile == null) return false;
    
    // We track completion using a flag in the settings box
    final settings = HiveService().settingsBox;
    return settings.get('${_currentUser}_profile_created') == true;
  }

  /// Marks profile as completed
  Future<void> markProfileAsCompleted() async {
    if (_currentUser == null) return;
    final settings = HiveService().settingsBox;
    await settings.put('${_currentUser}_profile_created', true);
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    
    final settings = HiveService().settingsBox;
    await settings.delete(_sessionKey);

    await DatabaseService().setCurrentUser(null);
    notifyListeners();
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    final email = _currentUser!;

    final usersBox = HiveService().usersBox;
    final profilesBox = HiveService().profilesBox;
    final medicinesBox = HiveService().medicinesBox;
    final settings = HiveService().settingsBox;

    // 1. Cancel all notifications
    await NotificationService.cancelAllNotifications();

    // 2. Delete user medicines
    final userMedicineKeys = medicinesBox.keys.where((k) {
      final m = medicinesBox.get(k);
      return m?.userId == email;
    }).toList();
    for (final key in userMedicineKeys) {
      await medicinesBox.delete(key);
    }

    // 3. Delete profile
    await profilesBox.delete(email);
    await settings.delete('${email}_profile_created');

    // 4. Delete user account
    await usersBox.delete(email);

    // 5. Clear session
    await logout();
  }
  
  // Compatibility getter
  bool get isCaretaker => false;
}

final authService = AuthService();
