import 'shop_medicine.dart';

class CartItem {
  final ShopMedicine medicine;
  int quantity;

  CartItem({
    required this.medicine,
    this.quantity = 1,
  });

  double get subtotal => medicine.price * quantity;
  double get totalPrice => subtotal;
  double get unitPrice => medicine.price;

  CartItem copyWith({
    ShopMedicine? medicine,
    int? quantity,
  }) {
    return CartItem(
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
    );
  }
}
