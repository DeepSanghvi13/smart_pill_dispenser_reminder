import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/shop_medicine.dart';
import '../models/shop_profile.dart';
import '../models/prescription.dart';
import '../models/medicine_order.dart';
import 'mysql_api_service.dart';

class MedicalShopService extends ChangeNotifier {
  static final MedicalShopService _instance = MedicalShopService._internal();
  factory MedicalShopService() => _instance;
  MedicalShopService._internal();

  // State
  List<ShopMedicine> _catalogMedicines = [];
  List<ShopMedicine> _inventoryMedicines = [];
  List<MedicineOrder> _myOrders = [];
  List<MedicineOrder> _shopOrders = [];
  List<Prescription> _activePrescriptions = [];
  List<Prescription> _doctorPrescriptions = [];
  ShopProfile? _shopProfile;
  Map<String, dynamic>? _shopStats;

  bool _isLoading = false;
  String? _errorMessage;

  List<ShopMedicine> get catalogMedicines => _catalogMedicines;
  List<ShopMedicine> get inventoryMedicines => _inventoryMedicines;
  List<MedicineOrder> get myOrders => _myOrders;
  List<MedicineOrder> get shopOrders => _shopOrders;
  List<Prescription> get activePrescriptions => _activePrescriptions;
  List<Prescription> get doctorPrescriptions => _doctorPrescriptions;
  ShopProfile? get shopProfile => _shopProfile;
  Map<String, dynamic>? get shopStats => _shopStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  // ============= CATALOG (Patient & Caretaker) =============

  Future<List<ShopMedicine>> getCatalog({String? search, String? category, int? shopId}) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final rawList = await MySQLApiService().getShopCatalog(
        search: search,
        category: category,
        shopId: shopId,
      );
      _catalogMedicines = rawList.map((m) => ShopMedicine.fromMap(m)).toList();
      _errorMessage = null;
      _isLoading = false;
      _safeNotifyListeners();
      return _catalogMedicines;
    } catch (e) {
      _catalogMedicines = [];
      _errorMessage = 'Failed to load medicines from shop: $e';
      _isLoading = false;
      _safeNotifyListeners();
      return [];
    }
  }

  // ============= PHARMACY OWNER INVENTORY & PROFILE =============

  Future<ShopProfile?> getPharmacyProfile() async {
    try {
      final map = await MySQLApiService().getPharmacyProfile();
      if (map != null) {
        _shopProfile = ShopProfile.fromMap(map);
        _safeNotifyListeners();
        return _shopProfile;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPharmacyStats() async {
    try {
      _shopStats = await MySQLApiService().getPharmacyStats();
      _safeNotifyListeners();
      return _shopStats;
    } catch (_) {
      return null;
    }
  }

  Future<List<ShopMedicine>> getPharmacyInventory() async {
    try {
      final list = await MySQLApiService().getPharmacyInventory();
      _inventoryMedicines = list.map((m) => ShopMedicine.fromMap(m)).toList();
      _safeNotifyListeners();
      return _inventoryMedicines;
    } catch (_) {
      return [];
    }
  }

  Future<List<MedicineOrder>> getShopOrders() async {
    try {
      final list = await MySQLApiService().getShopOrders();
      _shopOrders = list.map((o) => MedicineOrder.fromMap(o)).toList();
      _safeNotifyListeners();
      return _shopOrders;
    } catch (_) {
      return [];
    }
  }

  Future<ShopMedicine?> addMedicineToInventory(Map<String, dynamic> data) async {
    try {
      final id = await MySQLApiService().addPharmacyMedicine(data);
      if (id != null && id > 0) {
        await getPharmacyInventory();
        await getPharmacyStats();
        return ShopMedicine.fromMap({...data, 'id': id});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateInventoryMedicine(int id, Map<String, dynamic> data) async {
    try {
      final success = await MySQLApiService().updatePharmacyMedicine(id, data);
      if (success) {
        await getPharmacyInventory();
        await getPharmacyStats();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteInventoryMedicine(int id) async {
    try {
      final success = await MySQLApiService().deletePharmacyMedicine(id);
      if (success) {
        _inventoryMedicines.removeWhere((m) => m.id == id);
        _safeNotifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<ShopProfile?> savePharmacyProfile(Map<String, dynamic> data) async {
    try {
      final success = await MySQLApiService().savePharmacyProfile(data);
      if (success) {
        return await getPharmacyProfile();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============= DOCTOR PRESCRIPTIONS =============

  Future<Prescription?> createPrescription({
    required dynamic patientId,
    required String medicineName,
    required String dosage,
    required String frequency,
    required String duration,
    required int quantity,
    String? diagnosis,
    String? instructions,
    DateTime? validUntil,
  }) async {
    try {
      final res = await MySQLApiService().createPrescription({
        'patientId': patientId,
        'medicineName': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'quantity': quantity,
        'diagnosis': diagnosis,
        'instructions': instructions,
        'validUntil': validUntil?.toIso8601String(),
      });
      if (res['ok'] == true && res['prescription'] != null) {
        await getDoctorPrescriptions();
        return Prescription.fromMap(res['prescription'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Prescription>> getDoctorPrescriptions() async {
    try {
      final rawList = await MySQLApiService().getDoctorPrescriptions();
      _doctorPrescriptions = rawList.map((p) => Prescription.fromMap(p)).toList();
      _safeNotifyListeners();
      return _doctorPrescriptions;
    } catch (_) {
      return [];
    }
  }

  Future<List<Prescription>> getPrescriptionsForPatient(dynamic patientId) async {
    try {
      final rawList = await MySQLApiService().getMyPrescriptions(patientId: patientId);
      _activePrescriptions = rawList.map((p) => Prescription.fromMap(p)).toList();
      _safeNotifyListeners();
      return _activePrescriptions;
    } catch (_) {
      return [];
    }
  }

  // ============= ORDERS =============

  Future<Map<String, dynamic>> submitOrder({
    required dynamic patientId,
    required int shopId,
    int? prescriptionId,
    String? deliveryAddress,
    String? paymentMethod,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await MySQLApiService().placeOrder({
        'patientId': patientId,
        'shopId': shopId,
        'prescriptionId': prescriptionId,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod ?? 'Cash on Delivery',
        'notes': notes,
        'items': items,
      });
      if (res['ok'] == true) {
        await getMyOrders();
      }
      return res;
    } catch (e) {
      return {'ok': false, 'message': 'Failed to place order: $e'};
    }
  }

  Future<List<MedicineOrder>> getMyOrders() async {
    try {
      final rawList = await MySQLApiService().getMyOrders();
      _myOrders = rawList.map((o) => MedicineOrder.fromMap(o)).toList();
      _safeNotifyListeners();
      return _myOrders;
    } catch (_) {
      return [];
    }
  }

  Future<MedicineOrder?> getOrderById(int? orderId) async {
    if (orderId == null) return null;
    try {
      final map = await MySQLApiService().getOrderById(orderId);
      if (map != null) {
        return MedicineOrder.fromMap(map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final success = await MySQLApiService().updateOrderStatus(orderId, newStatus);
      if (success) {
        await getShopOrders();
        await getPharmacyStats();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final medicalShopService = MedicalShopService();
