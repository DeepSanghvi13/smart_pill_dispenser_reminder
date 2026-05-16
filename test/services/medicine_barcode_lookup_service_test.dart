import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_pill_reminder/services/medicine_barcode_lookup_service.dart';

void main() {
  test('uses online API result when available', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"results":[{"brand_name":"TestMed","dosage_form":"TABLET","active_ingredients":[{"strength":"250 MG"}]}]}',
        200,
      );
    });

    final result = await MedicineBarcodeLookupService.lookupByBarcode(
      '12345678901',
      client: client,
      backendLookup: (_) async => null,
    );

    expect(result, isNotNull);
    expect(result!.name, 'TestMed');
    expect(result.dosage, '250 MG');
    expect(result.source, BarcodeLookupSource.onlineApi);
  });

  test('falls back to local map when API misses', () async {
    final client = MockClient((request) async {
      return http.Response('{"error":"not found"}', 404);
    });

    final result = await MedicineBarcodeLookupService.lookupByBarcode(
      '8901234567890',
      client: client,
      backendLookup: (_) async => null,
    );

    expect(result, isNotNull);
    expect(result!.name, 'Paracetamol');
    expect(result.source, BarcodeLookupSource.localFallback);
  });
}

