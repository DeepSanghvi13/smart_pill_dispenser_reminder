class ShopProfile {
  final int? id;
  final int? userId;
  final String shopName;
  final String ownerName;
  final String? phoneNumber;
  final String email;
  final String? address;
  final String? licenseNumber;
  final String? gstNumber;
  final String? imageUrl;
  final String? openingHours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ShopProfile({
    this.id,
    this.userId,
    required this.shopName,
    required this.ownerName,
    this.phoneNumber,
    required this.email,
    this.address,
    this.licenseNumber,
    this.gstNumber,
    this.imageUrl,
    this.openingHours,
    this.createdAt,
    this.updatedAt,
  });

  ShopProfile copyWith({
    int? id,
    int? userId,
    String? shopName,
    String? ownerName,
    String? phoneNumber,
    String? email,
    String? address,
    String? licenseNumber,
    String? gstNumber,
    String? imageUrl,
    String? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'shopName': shopName,
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'licenseNumber': licenseNumber,
      'gstNumber': gstNumber,
      'imageUrl': imageUrl,
      'openingHours': openingHours,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ShopProfile.fromMap(Map<String, dynamic> map) {
    return ShopProfile(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      shopName: map['shopName'] as String? ?? 'Medical Shop',
      ownerName: map['ownerName'] as String? ?? 'Shop Owner',
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String? ?? '',
      address: map['address'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      gstNumber: map['gstNumber'] as String?,
      imageUrl: map['imageUrl'] as String?,
      openingHours: map['openingHours'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}
