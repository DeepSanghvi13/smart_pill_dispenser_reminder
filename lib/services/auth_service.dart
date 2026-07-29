import 'package:flutter/material.dart';
import 'hive_service.dart';
import 'mysql_api_service.dart';
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

  /// Register a new user — saves locally AND sends to MySQL database
  Future<String?> registerWithMessage(String name, String email, String password, {String role = 'patient'}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        return 'Email cannot be empty.';
      }
      if (name.trim().isEmpty) {
        return 'Full name cannot be empty.';
      }
      if (password.length < 6) {
        return 'Password must be at least 6 characters.';
      }

      final box = HiveService().usersBox;
      if (box.containsKey(normalizedEmail)) {
        return 'Email already registered. Please login.';
      }

      // 1. Save locally in Hive
      final newUser = User(
        fullName: name.trim(),
        email: normalizedEmail,
        password: password,
        role: role,
      );
      await box.put(normalizedEmail, newUser);

      String? connectionCode;
      if (role == 'patient') {
        connectionCode = 'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
      }

      final profileBox = HiveService().profilesBox;
      final defaultProfile = UserProfile(
        email: normalizedEmail,
        fullName: name.trim(),
        connectionCode: connectionCode,
      );
      await profileBox.put(normalizedEmail, defaultProfile);
      final settings = HiveService().settingsBox;
      await settings.put(_sessionKey, normalizedEmail);
      _currentUser = normalizedEmail;
      _isLoggedIn = true;
      await DatabaseService().setCurrentUser(normalizedEmail);
      notifyListeners();

      // 2. Connect to MySQL Database via backend API
      try {
        await MySQLApiService().registerUser(
          email: normalizedEmail,
          password: password,
          fullName: name.trim(),
          role: role,
        );
        await MySQLApiService().saveUserProfileToServer(defaultProfile);
      } catch (e) {
        debugPrint('MySQL registration error: $e');
      }

      return null; // Success
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  /// Restore session from Hive settings box
  Future<void> loadSession() async {
    try {
      final usersBox = HiveService().usersBox;
      if (!usersBox.containsKey('admin@smartpill.com')) {
        final defaultAdmin = User(
          fullName: 'System Admin',
          email: 'admin@smartpill.com',
          password: 'adminpassword',
          role: 'admin',
          createdBy: 'system',
          updatedBy: 'system',
        );
        await usersBox.put('admin@smartpill.com', defaultAdmin);
        
        final defaultProfile = UserProfile(
          email: 'admin@smartpill.com',
          fullName: 'System Admin',
          createdBy: 'system',
          updatedBy: 'system',
        );
        await HiveService().profilesBox.put('admin@smartpill.com', defaultProfile);
      }

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

  /// Login — authenticates with MySQL backend, falls back to Hive local database
  Future<bool> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Try MySQL server login first
      final sessionData = await MySQLApiService().loginUser(normalizedEmail, password);
      if (sessionData != null && sessionData['ok'] == true) {
        final token = sessionData['token'] as String?;
        final settings = HiveService().settingsBox;
        if (token != null) await settings.put('jwt_token', token);

        final userData = sessionData['data'] as Map<String, dynamic>? ?? {};
        final userRole = userData['role'] as String? ?? 'patient';
        final fullName = userData['fullName'] as String? ?? normalizedEmail;

        final box = HiveService().usersBox;
        final localUser = User(
          fullName: fullName,
          email: normalizedEmail,
          password: password,
          role: userRole,
        );
        await box.put(normalizedEmail, localUser);

        final profileBox = HiveService().profilesBox;
        if (!profileBox.containsKey(normalizedEmail)) {
          final defaultProfile = UserProfile(
            email: normalizedEmail,
            fullName: fullName,
          );
          await profileBox.put(normalizedEmail, defaultProfile);
        }

        _currentUser = normalizedEmail;
        _isLoggedIn = true;
        await settings.put(_sessionKey, normalizedEmail);
        await DatabaseService().setCurrentUser(normalizedEmail);
        notifyListeners();
        return true;
      }

      // 2. Offline / local fallback
      final box = HiveService().usersBox;
      if (!box.containsKey(normalizedEmail)) {
        return false;
      }

      final user = box.get(normalizedEmail);
      if (user != null && user.password == password) {
        _currentUser = normalizedEmail;
        _isLoggedIn = true;
        
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
    final settings = HiveService().settingsBox;
    final flag = settings.get('${_currentUser}_profile_created');
    return flag == true;
  }

  /// Marks profile as completed
  Future<void> markProfileAsCompleted() async {
    if (_currentUser == null) return;
    final settings = HiveService().settingsBox;
    await settings.put('${_currentUser}_profile_created', true);
  }

  /// Logout
  Future<void> logout() async {
    try {
      await MySQLApiService().logoutUser();
    } catch (_) {}

    _currentUser = null;
    _isLoggedIn = false;
    
    final settings = HiveService().settingsBox;
    await settings.delete(_sessionKey);
    await settings.delete('jwt_token');

    await DatabaseService().setCurrentUser(null);
    notifyListeners();
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    final email = _currentUser!;
    final isCare = isCaretaker;

    final usersBox = HiveService().usersBox;
    final profilesBox = HiveService().profilesBox;
    final medicinesBox = HiveService().medicinesBox;
    final connectionsBox = HiveService().connectionsBox;
    final settings = HiveService().settingsBox;

    // Cancel all notifications
    await NotificationService.cancelAllNotifications();

    if (!isCare) {
      // Patient Account Deletion
      // Delete patient medicines
      final userMedicineKeys = medicinesBox.keys.where((k) {
        final m = medicinesBox.get(k);
        return m?.userId == email || m?.patientId == email;
      }).toList();
      for (final key in userMedicineKeys) {
        await medicinesBox.delete(key);
      }

      // Remove all caretaker connections involving this patient
      final patientConnKeys = connectionsBox.keys.where((k) {
        final c = connectionsBox.get(k);
        return c != null && c['patientId'] == email;
      }).toList();
      for (final key in patientConnKeys) {
        await connectionsBox.delete(key);
      }

      // Delete profile
      await profilesBox.delete(email);
      await settings.delete('${email}_profile_created');
      await usersBox.delete(email);
    } else {
      // Caretaker Account Deletion
      // Remove all patient connections involving this caretaker
      final caretakerConnKeys = connectionsBox.keys.where((k) {
        final c = connectionsBox.get(k);
        return c != null && c['caretakerId'] == email;
      }).toList();
      for (final key in caretakerConnKeys) {
        await connectionsBox.delete(key);
      }

      // Delete profile
      await profilesBox.delete(email);
      await settings.delete('${email}_profile_created');
      await usersBox.delete(email);
    }

    await logout();
  }

  // Caretaker connections helpers
  bool get isCaretaker {
    if (_currentUser == null) return false;
    final user = HiveService().usersBox.get(_currentUser);
    return user?.role == 'caretaker';
  }

  bool get isAdmin {
    if (_currentUser == null) return false;
    final user = HiveService().usersBox.get(_currentUser);
    return user?.role == 'admin';
  }

  Future<void> adminResetPassword(String email, String newPassword) async {
    final normalized = email.trim().toLowerCase();
    final box = HiveService().usersBox;
    final user = box.get(normalized);
    if (user != null) {
      final updated = user.copyWith(
        password: newPassword,
        updatedBy: _currentUser ?? 'admin',
        updatedAt: DateTime.now(),
      );
      await box.put(normalized, updated);
      notifyListeners();
    }
  }

  Future<void> adminToggleUserStatus(String email, bool isActive) async {
    final normalized = email.trim().toLowerCase();
    final box = HiveService().usersBox;
    final user = box.get(normalized);
    if (user != null) {
      final updated = user.copyWith(
        isActive: isActive,
        updatedBy: _currentUser ?? 'admin',
        updatedAt: DateTime.now(),
      );
      await box.put(normalized, updated);
      notifyListeners();
    }
  }

  Future<void> adminDeleteUser(String email) async {
    final normalized = email.trim().toLowerCase();
    final usersBox = HiveService().usersBox;
    final profilesBox = HiveService().profilesBox;
    final medicinesBox = HiveService().medicinesBox;
    final connectionsBox = HiveService().connectionsBox;
    final settings = HiveService().settingsBox;

    final userMedicineKeys = medicinesBox.keys.where((k) {
      final m = medicinesBox.get(k);
      return m?.userId == normalized || m?.patientId == normalized;
    }).toList();
    for (final key in userMedicineKeys) {
      await medicinesBox.delete(key);
    }

    final connKeys = connectionsBox.keys.where((k) {
      final c = connectionsBox.get(k);
      return c != null && (c['patientId'] == normalized || c['caretakerId'] == normalized);
    }).toList();
    for (final key in connKeys) {
      await connectionsBox.delete(key);
    }

    await profilesBox.delete(normalized);
    await settings.delete('${normalized}_profile_created');
    await usersBox.delete(normalized);
    notifyListeners();
  }

  Future<void> adminLinkCaretakerAndPatient(String patientEmail, String caretakerEmail) async {
    final connectionsBox = HiveService().connectionsBox;
    final connId = 'conn_${patientEmail}_$caretakerEmail';
    final connData = {
      'connectionId': connId,
      'patientId': patientEmail,
      'caretakerId': caretakerEmail,
      'connectionCode': 'ADMIN-LINK',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await connectionsBox.put(connId, connData);
    notifyListeners();
  }

  Future<void> adminUnlinkCaretakerAndPatient(String connectionId) async {
    final connectionsBox = HiveService().connectionsBox;
    await connectionsBox.delete(connectionId);
    notifyListeners();
  }

  Future<String?> adminCreateUser(String name, String email, String password, String role) async {
    final normalized = email.trim().toLowerCase();
    final box = HiveService().usersBox;
    if (box.containsKey(normalized)) {
      return 'Email already exists.';
    }
    
    final newUser = User(
      fullName: name,
      email: normalized,
      password: password,
      role: role,
      createdBy: _currentUser ?? 'admin',
      updatedBy: _currentUser ?? 'admin',
    );
    await box.put(normalized, newUser);

    String? connectionCode;
    if (role == 'patient') {
      connectionCode = 'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
    }

    final defaultProfile = UserProfile(
      email: normalized,
      fullName: name,
      connectionCode: connectionCode,
      createdBy: _currentUser ?? 'admin',
      updatedBy: _currentUser ?? 'admin',
    );
    await HiveService().profilesBox.put(normalized, defaultProfile);

    // Sync to MySQL Database
    MySQLApiService().registerUser(
      email: normalized,
      password: password,
      fullName: name,
      role: role,
    ).then((_) {}).catchError((_) => null);

    notifyListeners();
    return null;
  }

  Future<String?> connectPatient(String input1, [String? input2]) async {
    if (_currentUser == null) return 'Must be logged in.';

    final val1 = input1.trim();
    final val2 = input2?.trim() ?? '';

    if (val2.isEmpty) {
      // Connect by Connection Code (e.g. SPD-XXXXXX)
      final cleanCode = val1.toUpperCase();
      if (cleanCode.isEmpty) return 'Code cannot be empty.';

      // Find patient profile with connectionCode == cleanCode
      final profilesBox = HiveService().profilesBox;
      UserProfile? patientProfile;
      for (final p in profilesBox.values) {
        if (p.connectionCode == cleanCode) {
          patientProfile = p;
          break;
        }
      }

      if (patientProfile == null) {
        return 'Invalid Connection Code.';
      }

      final patientEmail = patientProfile.email;
      final caretakerEmail = _currentUser!;

      if (patientEmail == caretakerEmail) {
        return 'Cannot connect to your own account.';
      }

      // Save to connections box
      final connectionsBox = HiveService().connectionsBox;
      final connId = 'conn_${patientEmail}_$caretakerEmail';

      final newConnection = {
        'connectionId': connId,
        'patientId': patientEmail,
        'caretakerId': caretakerEmail,
        'connectionCode': cleanCode,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await connectionsBox.put(connId, newConnection);
      notifyListeners();
      return null; // Success
    } else {
      // Connect by Email and Phone
      final cleanEmail = val1.toLowerCase();
      final cleanPhone = val2;

      // Find patient profile with matching email
      final profilesBox = HiveService().profilesBox;
      final patientProfile = profilesBox.get(cleanEmail);

      if (patientProfile == null) {
        return 'No patient profile found with this email.';
      }

      // Verify phone number (mobileNumber or emergencyContact)
      final profilePhone = patientProfile.mobileNumber?.trim() ?? '';
      final profileEmergency = patientProfile.emergencyContact?.trim() ?? '';
      if (profilePhone != cleanPhone && profileEmergency != cleanPhone) {
        return 'Phone number does not match this patient profile.';
      }

      final patientEmail = patientProfile.email;
      final caretakerEmail = _currentUser!;

      if (patientEmail == caretakerEmail) {
        return 'Cannot connect to your own account.';
      }

      // Save to connections box
      final connectionsBox = HiveService().connectionsBox;
      final connId = 'conn_${patientEmail}_$caretakerEmail';

      final newConnection = {
        'connectionId': connId,
        'patientId': patientEmail,
        'caretakerId': caretakerEmail,
        'connectionCode': patientProfile.connectionCode ?? 'N/A',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await connectionsBox.put(connId, newConnection);
      notifyListeners();
      return null; // Success
    }
  }

  List<UserProfile> getConnectedPatients() {
    if (_currentUser == null) return [];
    final caretakerEmail = _currentUser!;
    final connectionsBox = HiveService().connectionsBox;
    final profilesBox = HiveService().profilesBox;

    final patientEmails = connectionsBox.values
        .where((c) => c['caretakerId'] == caretakerEmail)
        .map((c) => c['patientId'] as String)
        .toList();

    return profilesBox.values
        .where((p) => patientEmails.contains(p.email))
        .toList();
  }

  List<UserProfile> getConnectedCaretakers() {
    if (_currentUser == null) return [];
    final patientEmail = _currentUser!;
    final connectionsBox = HiveService().connectionsBox;
    final profilesBox = HiveService().profilesBox;

    final caretakerEmails = connectionsBox.values
        .where((c) => c['patientId'] == patientEmail)
        .map((c) => c['caretakerId'] as String)
        .toList();

    return profilesBox.values
        .where((p) => caretakerEmails.contains(p.email))
        .toList();
  }

  Future<void> disconnectPatient(String patientEmail) async {
    if (_currentUser == null) return;
    final caretakerEmail = _currentUser!;
    final connectionsBox = HiveService().connectionsBox;
    final connId = 'conn_${patientEmail}_$caretakerEmail';
    await connectionsBox.delete(connId);
    notifyListeners();
  }

  Future<void> disconnectCaretaker(String caretakerEmail) async {
    if (_currentUser == null) return;
    final patientEmail = _currentUser!;
    final connectionsBox = HiveService().connectionsBox;
    final connId = 'conn_${patientEmail}_$caretakerEmail';
    await connectionsBox.delete(connId);
    notifyListeners();
  }
}

final authService = AuthService();
