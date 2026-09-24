import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lib/models/shop_medicine.dart';

void main() async {
  try {
    final res = await http.get(Uri.parse('http://localhost:3000/api/shop/catalog'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body)['data'] as List<dynamic>;
      print('Fetched \${list.length} items');
      final mapped = list.map((m) => ShopMedicine.fromMap(m as Map<String, dynamic>)).toList();
      print('Successfully mapped \${mapped.length} items');
    } else {
      print('Status Code: \${res.statusCode}');
    }
  } catch (e, stack) {
    print('Error: \$e');
    print(stack);
  }
}
