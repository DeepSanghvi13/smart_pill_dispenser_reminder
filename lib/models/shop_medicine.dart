import 'package:intl/intl.dart';

class ShopMedicine {
  final int? id;
  final int shopId;
  final String name;
  final String category;
  final String dosage;
  final String? manufacturer;
  final String? batchNumber;
  final double price;
  final int stockQuantity;
  final DateTime expiryDate;
  final String? imageUrl;
  final String? description;
  final String? sideEffects;
  final String? storageInstructions;
  final bool prescriptionRequired;
  final bool isAvailable;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ShopMedicine({
    this.id,
    required this.shopId,
    required this.name,
    this.category = 'Tablets',
    this.dosage = '500mg',
    this.manufacturer,
    this.batchNumber,
    this.price = 0.0,
    this.stockQuantity = 0,
    required this.expiryDate,
    this.imageUrl,
    this.description,
    this.sideEffects,
    this.storageInstructions,
    this.prescriptionRequired = false,
    this.isAvailable = true,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.createdAt,
    this.updatedAt,
  });

  String get medicineName => name;
  bool get requiresPrescription => prescriptionRequired;

  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expDay.isBefore(today);
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    if (expDay.isBefore(today)) return false;
    return expDay.difference(today).inDays <= 30;
  }

  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;
  bool get isOutOfStock => stockQuantity <= 0 || !isAvailable;

  String get formattedExpiryDate => DateFormat('dd/MM/yyyy').format(expiryDate);
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  ShopMedicine copyWith({
    int? id,
    int? shopId,
    String? name,
    String? category,
    String? dosage,
    String? manufacturer,
    String? batchNumber,
    double? price,
    int? stockQuantity,
    DateTime? expiryDate,
    String? imageUrl,
    String? description,
    String? sideEffects,
    String? storageInstructions,
    bool? prescriptionRequired,
    bool? isAvailable,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopMedicine(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      category: category ?? this.category,
      dosage: dosage ?? this.dosage,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sideEffects: sideEffects ?? this.sideEffects,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
      isAvailable: isAvailable ?? this.isAvailable,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'medicineName': name,
      'category': category,
      'dosage': dosage,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'price': price,
      'stockQuantity': stockQuantity,
      'expiryDate': expiryDate.toIso8601String(),
      'imageUrl': imageUrl,
      'description': description,
      'sideEffects': sideEffects,
      'storageInstructions': storageInstructions,
      'prescriptionRequired': prescriptionRequired ? 1 : 0,
      'requiresPrescription': prescriptionRequired ? 1 : 0,
      'isAvailable': isAvailable ? 1 : 0,
    };
  }

  factory ShopMedicine.fromMap(Map<String, dynamic> map) {
    final parsedExp = map['expiryDate'] != null
        ? (DateTime.tryParse(map['expiryDate'].toString()) ?? DateTime.now().add(const Duration(days: 90)))
        : DateTime.now().add(const Duration(days: 90));

    final nameVal = (map['medicineName'] ?? map['name'] ?? 'Medicine').toString();

    return ShopMedicine(
      id: map['id'] as int?,
      shopId: map['shopId'] as int? ?? 0,
      name: nameVal,
      category: map['category'] as String? ?? 'Tablets',
      dosage: map['dosage'] as String? ?? '500mg',
      manufacturer: map['manufacturer'] as String?,
      batchNumber: map['batchNumber'] as String?,
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      stockQuantity: int.tryParse(map['stockQuantity']?.toString() ?? '0') ?? 0,
      expiryDate: parsedExp,
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      sideEffects: map['sideEffects'] as String?,
      storageInstructions: map['storageInstructions'] as String?,
      prescriptionRequired: map['prescriptionRequired'] == 1 ||
          map['prescriptionRequired'] == true ||
          map['requiresPrescription'] == 1 ||
          map['requiresPrescription'] == true,
      isAvailable: map['isAvailable'] == null ? true : (map['isAvailable'] == 1 || map['isAvailable'] == true),
      shopName: map['shopName'] as String?,
      shopAddress: map['shopAddress'] as String?,
      shopPhone: map['shopPhone'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
    );
  }
}
