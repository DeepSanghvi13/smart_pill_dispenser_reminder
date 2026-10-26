import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'lib/models/shop_medicine.dart';

void main() async {
  try {
    final res = await http.get(Uri.parse('http://localhost:3000/api/shop/catalog'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body)['data'] as List<dynamic>;
      developer.log('Fetched ${list.length} items');
      final mapped = list.map((m) => ShopMedicine.fromMap(m as Map<String, dynamic>)).toList();
      developer.log('Successfully mapped ${mapped.length} items');
    } else {
      developer.log('Status Code: ${res.statusCode}');
    }
  } catch (e, stack) {
    developer.log('Error: $e');
    developer.log(stack.toString());
  }
}
