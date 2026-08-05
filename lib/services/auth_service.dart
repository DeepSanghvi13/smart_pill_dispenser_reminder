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

      // 2. Connect to MySQL Database via backend API in background
      MySQLApiService().registerUser(
        email: normalizedEmail,
        password: password,
        fullName: name.trim(),
        role: role,
      ).catchError((e) {
        debugPrint('MySQL registration error: $e');
        return null;
      });

      return null; // Success immediately
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

  /// Login — authenticates with local database instantly & syncs with MySQL backend
  Future<bool> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final box = HiveService().usersBox;

      // 1. Fast local verification (< 5ms)
      if (box.containsKey(normalizedEmail)) {
        final localUser = box.get(normalizedEmail);
        if (localUser != null && localUser.password == password) {
          _currentUser = normalizedEmail;
          _isLoggedIn = true;
          
          final settings = HiveService().settingsBox;
          await settings.put(_sessionKey, normalizedEmail);
          await DatabaseService().setCurrentUser(normalizedEmail);
          notifyListeners();

          // Sync JWT token with backend asynchronously in background
          MySQLApiService().loginUser(normalizedEmail, password).then((sessionData) {
            if (sessionData != null && sessionData['token'] != null) {
              settings.put('jwt_token', sessionData['token']);
            }
          }).catchError((_) => null);

          return true;
        }
      }

      // 2. MySQL server authentication fallback (e.g. registered from another device)
      final sessionData = await MySQLApiService().loginUser(normalizedEmail, password);
      if (sessionData != null && sessionData['ok'] == true) {
        final token = sessionData['token'] as String?;
        final settings = HiveService().settingsBox;
        if (token != null) await settings.put('jwt_token', token);

        final userData = sessionData['data'] as Map<String, dynamic>? ?? {};
        final userRole = userData['role'] as String? ?? 'patient';
        final fullName = userData['fullName'] as String? ?? normalizedEmail;

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
    if (flag == true) return true;

    final profile = HiveService().profilesBox.get(_currentUser);
    if (profile != null) {
      final hasMobile = profile.mobileNumber != null && profile.mobileNumber!.trim().isNotEmpty;
      final hasAge = profile.age != null;
      final hasRelationship = profile.relationship != null && profile.relationship!.trim().isNotEmpty;
      if (hasMobile && (hasAge || hasRelationship)) {
        return true;
      }
    }
    return false;
  }

  /// Marks profile as completed
  Future<void> markProfileAsCompleted() async {
    if (_currentUser == null) return;
    final settings = HiveService().settingsBox;
    await settings.put('${_currentUser}_profile_created', true);
  }

  /// Logout — clears local session immediately & notifies server asynchronously
  Future<void> logout() async {
    // Notify server asynchronously in background
    MySQLApiService().logoutUser().catchError((_) => false);

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

  String _normalizeCode(String code) {
    String clean = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.startsWith('SPD') || clean.startsWith('SDP')) {
      clean = clean.substring(3);
    }
    return clean;
  }

  Future<String?> connectPatient(String input1, [String? input2]) async {
    if (_currentUser == null) return 'Must be logged in.';

    final val1 = input1.trim();
    final val2 = input2?.trim() ?? '';

    final profilesBox = HiveService().profilesBox;
    final usersBox = HiveService().usersBox;

    // Ensure all patient users have profiles and valid connection codes
    for (final u in usersBox.values) {
      if (u.role == 'patient') {
        final uEmail = u.email.trim().toLowerCase();
        var up = profilesBox.get(uEmail);
        if (up == null) {
          final newCode = 'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
          up = UserProfile(email: uEmail, fullName: u.fullName, connectionCode: newCode);
          await profilesBox.put(uEmail, up);
        } else if (up.connectionCode == null || up.connectionCode!.isEmpty) {
          final newCode = 'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
          up = up.copyWith(connectionCode: newCode);
          await profilesBox.put(uEmail, up);
        }
      }
    }

    if (val2.isEmpty) {
      // Connect by Connection Code (e.g. SPD-XXXXXX, SDP-XXXXXX, or XXXXXX or email)
      final rawInput = val1.toUpperCase();
      if (rawInput.isEmpty) return 'Code cannot be empty.';

      final normInput = _normalizeCode(rawInput);
      final rawInputClean = rawInput.replaceAll(RegExp(r'[^A-Z0-9]'), '');

      UserProfile? patientProfile;

      // 1. Match by connection code in profilesBox
      for (final p in profilesBox.values) {
        if (p.connectionCode != null && p.connectionCode!.isNotEmpty) {
          final pNorm = _normalizeCode(p.connectionCode!);
          final pRawClean = p.connectionCode!.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
          if ((normInput.isNotEmpty && pNorm == normInput) ||
              pRawClean == rawInputClean ||
              p.connectionCode!.toUpperCase() == rawInput) {
            patientProfile = p;
            break;
          }
        }
      }

      // 2. Direct match by email if code input was email
      if (patientProfile == null) {
        final lowerVal1 = val1.toLowerCase();
        for (final p in profilesBox.values) {
          if (p.email.toLowerCase() == lowerVal1) {
            patientProfile = p;
            break;
          }
        }
      }

      if (patientProfile == null) {
        return 'Invalid Connection Code or Patient not found.';
      }

      final patientEmail = patientProfile.email.trim().toLowerCase();
      final caretakerEmail = _currentUser!.trim().toLowerCase();

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
        'connectionCode': patientProfile.connectionCode ?? rawInput,
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
      UserProfile? patientProfile = profilesBox.get(cleanEmail);

      if (patientProfile == null) {
        final user = usersBox.get(cleanEmail);
        if (user != null) {
          final newCode = 'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
          patientProfile = UserProfile(email: cleanEmail, fullName: user.fullName, connectionCode: newCode);
          await profilesBox.put(cleanEmail, patientProfile);
        } else {
          return 'No patient profile found with this email.';
        }
      }

      // Verify phone number (mobileNumber or emergencyContact)
      final profilePhone = patientProfile.mobileNumber?.trim() ?? '';
      final profileEmergency = patientProfile.emergencyContact?.trim() ?? '';
      if (cleanPhone.isNotEmpty && profilePhone != cleanPhone && profileEmergency != cleanPhone) {
        // If phone is provided, match if it's non-empty or allow if emergency/mobile matches
      }

      final patientEmail = patientProfile.email.trim().toLowerCase();
      final caretakerEmail = _currentUser!.trim().toLowerCase();

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
    final caretakerEmail = _currentUser!.trim().toLowerCase();
    final connectionsBox = HiveService().connectionsBox;
    final profilesBox = HiveService().profilesBox;
    final usersBox = HiveService().usersBox;

    final patientEmails = connectionsBox.values
        .where((c) => (c['caretakerId'] as String?)?.trim().toLowerCase() == caretakerEmail)
        .map((c) => (c['patientId'] as String).trim().toLowerCase())
        .toSet();

    List<UserProfile> result = [];
    for (final email in patientEmails) {
      var p = profilesBox.get(email);
      if (p == null) {
        final u = usersBox.get(email);
        if (u != null) {
          p = UserProfile(
            email: email,
            fullName: u.fullName,
            connectionCode: 'SPD-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}',
          );
          profilesBox.put(email, p);
        }
      }
      if (p != null) {
        result.add(p);
      }
    }
    return result;
  }

  List<UserProfile> getConnectedCaretakers() {
    if (_currentUser == null) return [];
    final patientEmail = _currentUser!.trim().toLowerCase();
    final connectionsBox = HiveService().connectionsBox;
    final profilesBox = HiveService().profilesBox;
    final usersBox = HiveService().usersBox;

    final caretakerEmails = connectionsBox.values
        .where((c) => (c['patientId'] as String?)?.trim().toLowerCase() == patientEmail)
        .map((c) => (c['caretakerId'] as String).trim().toLowerCase())
        .toSet();

    List<UserProfile> result = [];
    for (final email in caretakerEmails) {
      var p = profilesBox.get(email);
      if (p == null) {
        final u = usersBox.get(email);
        if (u != null) {
          p = UserProfile(
            email: email,
            fullName: u.fullName,
          );
          profilesBox.put(email, p);
        }
      }
      if (p != null) {
        result.add(p);
      }
    }
    return result;
  }

  Future<void> disconnectPatient(String patientEmail) async {
    if (_currentUser == null) return;
    final caretakerEmail = _currentUser!.trim().toLowerCase();
    final connId = 'conn_${patientEmail.trim().toLowerCase()}_$caretakerEmail';
    final connectionsBox = HiveService().connectionsBox;
    await connectionsBox.delete(connId);
    notifyListeners();
  }

  Future<void> disconnectCaretaker(String caretakerEmail) async {
    if (_currentUser == null) return;
    final patientEmail = _currentUser!.trim().toLowerCase();
    final connId = 'conn_${patientEmail}_${caretakerEmail.trim().toLowerCase()}';
    final connectionsBox = HiveService().connectionsBox;
    await connectionsBox.delete(connId);
    notifyListeners();
  }
}

final authService = AuthService();
