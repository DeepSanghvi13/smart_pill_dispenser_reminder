import 'package:intl/intl.dart';

enum MedicineOrderStatus {
  pending('Pending'),
  accepted('Accepted'),
  packed('Packed'),
  ready('Ready'),
  delivered('Delivered'),
  rejected('Rejected');

  final String label;
  const MedicineOrderStatus(this.label);

  static MedicineOrderStatus fromString(String val) {
    return MedicineOrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => MedicineOrderStatus.pending,
    );
  }
}

class OrderItem {
  final int? id;
  final int? orderId;
  final int shopMedicineId;
  final String medicineName;
  final String? dosage;
  final double price;
  final int quantity;
  final double subtotal;
  final String? imageUrl;
  final String? category;
  final int? currentStock;
  final DateTime? expiryDate;

  OrderItem({
    this.id,
    this.orderId,
    required this.shopMedicineId,
    required this.medicineName,
    this.dosage,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
    this.category,
    this.currentStock,
    this.expiryDate,
  });

  double get unitPrice => price;
  double get totalPrice => subtotal;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'shopMedicineId': shopMedicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['orderId'] as int?,
      shopMedicineId: map['shopMedicineId'] as int? ?? 0,
      medicineName: map['medicineName'] as String? ?? 'Medicine',
      dosage: map['dosage'] as String?,
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0.0,
      imageUrl: map['imageUrl'] as String?,
      category: map['category'] as String?,
      currentStock: int.tryParse(map['currentStock']?.toString() ?? ''),
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate'].toString()) : null,
    );
  }
}

class MedicineOrder {
  final int? id;
  final String orderNumber;
  final dynamic patientId;
  final dynamic caretakerId;
  final int shopId;
  final int? prescriptionId;
  final double totalAmount;
  final String status;
  final String? deliveryAddress;
  final String paymentMethod;
  final String? notes;
  final String? shopName;
  final String? shopPhone;
  final String? shopAddress;
  final String? patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? caretakerName;
  final String? caretakerPhone;
  final String? prescribedMedicineName;
  final String? prescribedDosage;
  final String? prescribedFrequency;
  final String? prescribedDuration;
  final String? prescribedDoctorName;
  final String? prescribedDoctorPhone;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicineOrder({
    this.id,
    required this.orderNumber,
    required this.patientId,
    this.caretakerId,
    required this.shopId,
    this.prescriptionId,
    required this.totalAmount,
    this.status = 'pending',
    this.deliveryAddress,
    this.paymentMethod = 'Cash on Delivery',
    this.notes,
    this.shopName,
    this.shopPhone,
    this.shopAddress,
    this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.caretakerName,
    this.caretakerPhone,
    this.prescribedMedicineName,
    this.prescribedDosage,
    this.prescribedFrequency,
    this.prescribedDuration,
    this.prescribedDoctorName,
    this.prescribedDoctorPhone,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  MedicineOrderStatus get orderStatus => MedicineOrderStatus.fromString(status);
  String get statusDisplayName => orderStatus.label;

  String get formattedTotal => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedDate => createdAt != null
      ? DateFormat('dd/MM/yyyy, hh:mm a').format(createdAt!)
      : 'Recently';
  String get formattedOrderDate => formattedDate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'patientId': patientId,
      'caretakerId': caretakerId,
      'shopId': shopId,
      'prescriptionId': prescriptionId,
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  factory MedicineOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i as Map))).toList();

    return MedicineOrder(
      id: map['id'] as int?,
      orderNumber: map['orderNumber'] as String? ?? 'ORD-0000',
      patientId: map['patientId'] as int? ?? 0,
      caretakerId: map['caretakerId'] as int?,
      shopId: map['shopId'] as int? ?? 0,
      prescriptionId: map['prescriptionId'] as int?,
      totalAmount: double.tryParse(map['totalAmount']?.toString() ?? '0') ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      deliveryAddress: map['deliveryAddress'] as String?,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash on Delivery',
      notes: map['notes'] as String?,
      shopName: map['shopName'] as String?,
      shopPhone: map['shopPhone'] as String?,
      shopAddress: map['shopAddress'] as String?,
      patientName: map['patientName'] as String?,
      patientEmail: map['patientEmail'] as String?,
      patientPhone: map['patientPhone'] as String?,
      caretakerName: map['caretakerName'] as String?,
      caretakerPhone: map['caretakerPhone'] as String?,
      prescribedMedicineName: map['prescribedMedicineName'] as String?,
      prescribedDosage: map['prescribedDosage'] as String?,
      prescribedFrequency: map['prescribedFrequency'] as String?,
      prescribedDuration: map['prescribedDuration'] as String?,
      prescribedDoctorName: map['prescribedDoctorName'] as String?,
      prescribedDoctorPhone: map['prescribedDoctorPhone'] as String?,
      items: parsedItems,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
    );
  }
}
