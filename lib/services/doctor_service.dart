import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/doctor_connection.dart';
import '../models/appointment.dart';
import 'mysql_api_service.dart';

class DoctorService extends ChangeNotifier {
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;
  DoctorService._internal();

  List<DoctorModel> _searchResults = [];
  List<DoctorConnectionItem> _incomingRequests = [];
  List<DoctorModel> _myDoctors = [];
  List<Map<String, dynamic>> _myPatients = [];
  List<Map<String, dynamic>> _myCaretakers = [];
  
  List<Appointment> _patientAppointments = [];
  List<Appointment> _doctorAppointments = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<DoctorModel> get searchResults => _searchResults;
  List<DoctorConnectionItem> get incomingRequests => _incomingRequests;
  List<DoctorModel> get myDoctors => _myDoctors;
  List<Map<String, dynamic>> get myPatients => _myPatients;
  List<Map<String, dynamic>> get myCaretakers => _myCaretakers;
  
  List<Appointment> get patientAppointments => _patientAppointments;
  List<Appointment> get doctorAppointments => _doctorAppointments;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Search doctors strictly from the backend database (No hardcoded/dummy doctors)
  Future<void> searchDoctors({String query = '', String specialization = 'All'}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final specFilter = (specialization == 'All' || specialization.isEmpty) ? null : specialization;
      final serverResults = await MySQLApiService().searchDoctors(
        search: query.isEmpty ? null : query,
        specialization: specFilter,
      );

      _searchResults = serverResults.map((map) => DoctorModel.fromMap(map)).toList();
      _errorMessage = null;
    } catch (e) {
      _searchResults = [];
      _errorMessage = 'Unable to load doctors. Please try again.';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void filterVerifiedOnly() {
    _searchResults = _searchResults.where((d) => d.isVerified).toList();
    _safeNotifyListeners();
  }

  /// Send connection request to doctor (Patient or Caretaker -> Doctor)
  Future<String?> sendConnectionRequest(int? doctorId, {String? doctorEmail}) async {
    if (doctorId == null || doctorId <= 0) {
      return 'Valid Doctor ID is required.';
    }

    try {
      final res = await MySQLApiService().sendDoctorConnectionRequest(doctorId);
      if (res['ok'] == true) {
        // Update local status in search results
        final idx = _searchResults.indexWhere((d) => d.id == doctorId);
        if (idx != -1) {
          _searchResults[idx] = _searchResults[idx].copyWith(connectionStatus: 'pending');
          _safeNotifyListeners();
        }
        return null; // Success
      } else {
        return res['message'] as String? ?? 'Failed to send request.';
      }
    } catch (e) {
      return 'Failed to send connection request: $e';
    }
  }

  /// Load all data for logged-in Doctor
  Future<void> loadAllDoctorData() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      await Future.wait([
        loadIncomingRequests(silent: true),
        loadDoctorPatients(silent: true),
        loadDoctorCaretakers(silent: true),
        loadDoctorAppointments(silent: true),
      ]);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Load incoming connection requests for logged-in Doctor
  Future<void> loadIncomingRequests({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _safeNotifyListeners();
    }

    try {
      final rawList = await MySQLApiService().getDoctorRequests();
      _incomingRequests = rawList.map((map) => DoctorConnectionItem.fromMap(map)).toList();
    } catch (_) {
      _incomingRequests = [];
    } finally {
      if (!silent) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  /// Accept incoming connection request
  Future<String?> acceptRequest(int connectionId) async {
    try {
      final res = await MySQLApiService().acceptDoctorRequest(connectionId);
      if (res['ok'] == true) {
        await loadAllDoctorData();
        return null;
      }
      return res['message'] as String? ?? 'Failed to accept request';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Reject incoming connection request
  Future<String?> rejectRequest(int connectionId) async {
    try {
      final res = await MySQLApiService().rejectDoctorRequest(connectionId);
      if (res['ok'] == true) {
        await loadAllDoctorData();
        return null;
      }
      return res['message'] as String? ?? 'Failed to reject request';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Remove/Delete a connection request (Doctor removes request)
  Future<bool> removeRequest(int connectionId) async {
    try {
      final success = await MySQLApiService().removeDoctorConnection(connectionId);
      if (success) {
        await loadAllDoctorData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Load connected doctors for logged-in Patient/Caretaker
  Future<void> loadMyDoctors() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final rawList = await MySQLApiService().getMyDoctors();
      _myDoctors = rawList.map((map) => DoctorModel.fromMap(map)).toList();
      await loadPatientAppointments(silent: true);
    } catch (_) {
      _myDoctors = [];
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Load connected patients for logged-in Doctor
  Future<void> loadDoctorPatients({bool silent = false}) async {
    try {
      _myPatients = await MySQLApiService().getDoctorPatients();
      if (!silent) _safeNotifyListeners();
    } catch (_) {
      _myPatients = [];
      if (!silent) _safeNotifyListeners();
    }
  }

  /// Load connected caretakers for logged-in Doctor
  Future<void> loadDoctorCaretakers({bool silent = false}) async {
    try {
      _myCaretakers = await MySQLApiService().getDoctorCaretakers();
      if (!silent) _safeNotifyListeners();
    } catch (_) {
      _myCaretakers = [];
      if (!silent) _safeNotifyListeners();
    }
  }

  /// Remove or cancel doctor connection (Patient, Caretaker, or Doctor)
  Future<bool> removeConnection(int connectionId) async {
    try {
      final success = await MySQLApiService().removeDoctorConnection(connectionId);
      if (success) {
        await Future.wait([
          loadMyDoctors(),
          loadAllDoctorData(),
        ]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
  // ---- Appointments ----

  Future<String?> bookAppointment(int doctorId, String date, String time, String reason) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final res = await MySQLApiService().bookAppointment(
        doctorId: doctorId,
        appointmentDate: date,
        appointmentTime: time,
        reason: reason,
      );
      if (res['ok'] == true) {
        return null; // Success
      }
      return res['message'] as String? ?? 'Failed to book appointment.';
    } catch (e) {
      return 'Error: $e';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadPatientAppointments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _safeNotifyListeners();
    }
    try {
      final rawList = await MySQLApiService().getPatientAppointments();
      _patientAppointments = rawList.map((m) => Appointment.fromJson(m)).toList();
    } catch (_) {
      _patientAppointments = [];
    } finally {
      if (!silent) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> loadDoctorAppointments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _safeNotifyListeners();
    }
    try {
      final rawList = await MySQLApiService().getDoctorAppointments();
      _doctorAppointments = rawList.map((m) => Appointment.fromJson(m)).toList();
    } catch (_) {
      _doctorAppointments = [];
    } finally {
      if (!silent) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<String?> updateAppointmentStatus(int appointmentId, String status) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final res = await MySQLApiService().updateAppointmentStatus(appointmentId, status);
      if (res['ok'] == true) {
        await loadDoctorAppointments(silent: true);
        return null;
      }
      return res['message'] as String? ?? 'Failed to update status.';
    } catch (e) {
      return 'Error: $e';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
}

final doctorService = DoctorService();
