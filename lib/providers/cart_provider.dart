import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/shop_medicine.dart';
import '../models/prescription.dart';
import '../models/medicine_order.dart';
import '../services/medical_shop_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  // Caretaker patient selection
  String? _selectedPatientEmail;
  int? _selectedPatientNumericId;
  String? _selectedPatientName;

  // Prescription selection
  Prescription? _selectedPrescription;

  String _deliveryAddress = '';
  String _paymentMethod = 'Cash on Delivery';
  String _notes = '';

  Map<int, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  int? get shopId =>
      _items.isNotEmpty ? _items.values.first.medicine.shopId : null;
  String? get shopName =>
      _items.isNotEmpty ? _items.values.first.medicine.shopName : null;

  String? get selectedPatientEmail => _selectedPatientEmail;
  int? get selectedPatientNumericId => _selectedPatientNumericId;
  String? get selectedPatientName => _selectedPatientName;
  Prescription? get selectedPrescription => _selectedPrescription;
  String get deliveryAddress => _deliveryAddress;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;

  bool get requiresPrescription =>
      _items.values.any((i) => i.medicine.prescriptionRequired);

  void setPatient({required String email, int? numericId, String? name}) {
    _selectedPatientEmail = email;
    _selectedPatientNumericId = numericId;
    _selectedPatientName = name;
    notifyListeners();
  }

  void setPrescription(Prescription? prescription) {
    _selectedPrescription = prescription;
    notifyListeners();
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setNotes(String note) {
    _notes = note;
    notifyListeners();
  }

  bool hasItem(int? medicineId) =>
      medicineId != null && _items.containsKey(medicineId);

  int getQuantity(int? medicineId) =>
      medicineId != null ? (_items[medicineId]?.quantity ?? 0) : 0;

  /// Add medicine to cart. Returns null on success or error string if constraint fails.
  String? addItem(ShopMedicine medicine, {int quantity = 1}) {
    if (medicine.id == null) return 'Invalid medicine item.';
    if (medicine.isExpired) return 'Cannot add expired medicine to cart.';
    if (medicine.isOutOfStock) {
      return 'This medicine is currently out of stock.';
    }

    // Check if adding from another shop
    if (_items.isNotEmpty && shopId != medicine.shopId) {
      return 'Cart already contains items from another medical shop. Please checkout or clear your cart first.';
    }

    final medId = medicine.id!;
    if (_items.containsKey(medId)) {
      final currentQty = _items[medId]!.quantity;
      final newQty = currentQty + quantity;
      if (newQty > medicine.stockQuantity) {
        return 'Cannot add more. Available stock limit is ${medicine.stockQuantity}.';
      }
      _items[medId]!.quantity = newQty;
    } else {
      if (quantity > medicine.stockQuantity) {
        return 'Available stock limit is ${medicine.stockQuantity}.';
      }
      _items[medId] = CartItem(medicine: medicine, quantity: quantity);
    }

    notifyListeners();
    return null;
  }

  void updateQuantity(int medicineId, int quantity) {
    if (!_items.containsKey(medicineId)) return;

    final item = _items[medicineId]!;
    if (quantity <= 0) {
      _items.remove(medicineId);
    } else {
      final clamped = quantity > item.medicine.stockQuantity
          ? item.medicine.stockQuantity
          : quantity;
      item.quantity = clamped;
    }
    notifyListeners();
  }

  void incrementQuantity(int medicineId) {
    if (!_items.containsKey(medicineId)) return;
    final item = _items[medicineId]!;
    if (item.quantity < item.medicine.stockQuantity) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int medicineId) {
    if (!_items.containsKey(medicineId)) return;
    final item = _items[medicineId]!;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(medicineId);
    }
    notifyListeners();
  }

  void decrementItem(int? medicineId) {
    if (medicineId != null) {
      decrementQuantity(medicineId);
    }
  }

  void removeItem(int medicineId) {
    if (_items.containsKey(medicineId)) {
      _items.remove(medicineId);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedPrescription = null;
    notifyListeners();
  }

  void clear() => clearCart();

  Future<MedicineOrder?> checkout({
    required dynamic patientId,
    String? deliveryAddress,
    int? prescriptionId,
    String? notes,
  }) async {
    if (_items.isEmpty) return null;
    if (shopId == null) return null;

    final addr = deliveryAddress ?? _deliveryAddress;
    final prescId = prescriptionId ?? _selectedPrescription?.id;
    final orderNotes = notes ?? _notes;

    final itemPayloads = _items.values.map((item) {
      return {
        'shopMedicineId': item.medicine.id,
        'quantity': item.quantity,
      };
    }).toList();

    final res = await medicalShopService.submitOrder(
      patientId: patientId,
      shopId: shopId!,
      prescriptionId: prescId,
      deliveryAddress: addr,
      paymentMethod: _paymentMethod,
      notes: orderNotes,
      items: itemPayloads,
    );

    if (res['ok'] == true && res['order'] != null) {
      final createdOrder =
          MedicineOrder.fromMap(Map<String, dynamic>.from(res['order'] as Map));
      clearCart();
      return createdOrder;
    }

    return null;
  }
}
