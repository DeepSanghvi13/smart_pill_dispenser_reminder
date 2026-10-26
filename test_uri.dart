import 'dart:developer' as developer;

void main() {
  final uri = Uri.parse('http://10.0.2.2:3000/api/shop/catalog')
      .replace(queryParameters: null);
  developer.log(uri.toString());
}
