import 'lib/models/shop_medicine.dart';

void main() {
  final map = {
    'id': 1,
    'shopId': 1,
    'name': 'Paracetamol 500mg',
    'category': 'Tablets',
    'manufacturer': null,
    'batchNumber': null,
    'price': '15.00',
    'stockQuantity': 100,
    'expiryDate': '2028-12-30T18:30:00.000Z',
    'imageUrl': null,
    'description': null,
    'prescriptionRequired': 0,
    'isAvailable': 1,
    'createdAt': '2024-05-18T12:00:00.000Z',
    'shopName': 'Global Pharmacy Network',
    'ownerName': 'Owner 1',
    'shopPhone': '4441234001',
    'shopAddress': null,
    'shopLogo': null
  };
  
  try {
    final sm = ShopMedicine.fromMap(map);
    print('Parsed successfully: \${sm.name}');
  } catch (e, stack) {
    print('Error: \$e');
    print(stack);
  }
}
