import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medicine.dart';
import 'mysql_api_service.dart';


enum BarcodeLookupSource { backendApi, onlineApi, localCache, localFallback }

class BarcodeLookupResult {
  final String barcode;
  final String name;
  final String dosage;
  final MedicineCategory category;
  final BarcodeLookupSource source;

  const BarcodeLookupResult({
    required this.barcode,
    required this.name,
    required this.dosage,
    required this.category,
    required this.source,
  });
}

class MedicineBarcodeLookupService {
  static const String _openFdaBaseUrl = String.fromEnvironment(
    'OPENFDA_BASE_URL',
    defaultValue: 'https://api.fda.gov',
  );
  static const String _openFdaApiKey = String.fromEnvironment(
    'OPENFDA_API_KEY',
    defaultValue: '',
  );

  // Local fallback for offline mode and API misses.
  static const Map<String, BarcodeLookupResult> _barcodeMap = {
    '8901234567890': BarcodeLookupResult(
      barcode: '8901234567890',
      name: 'Paracetamol',
      dosage: '500 MG',
      category: MedicineCategory.tablets,
      source: BarcodeLookupSource.localFallback,
    ),
    '012345678905': BarcodeLookupResult(
      barcode: '012345678905',
      name: 'Cetirizine',
      dosage: '10 MG',
      category: MedicineCategory.tablets,
      source: BarcodeLookupSource.localFallback,
    ),
    '4902430780006': BarcodeLookupResult(
      barcode: '4902430780006',
      name: 'Cough Syrup',
      dosage: '5 ML',
      category: MedicineCategory.syrup,
      source: BarcodeLookupSource.localFallback,
    ),
  };

  static Future<BarcodeLookupResult?> lookupByBarcode(
    String barcode, {
    http.Client? client,
    Future<Map<String, dynamic>?> Function(String barcode)? cacheReader,
    Future<void> Function(BarcodeLookupResult result)? cacheWriter,
    Future<BarcodeLookupResult?> Function(String barcode)? backendLookup,
  }) async {
    final digits = _digitsOnly(barcode);
    if (digits.isEmpty) {
      return null;
    }

    if (cacheReader != null) {
      for (final candidate in _barcodeCandidates(digits)) {
        final cached = await cacheReader(candidate);
        if (cached != null) {
          final name = (cached['name'] as String? ?? '').trim();
          final dosage = (cached['dosage'] as String? ?? '').trim();
          final categoryName = (cached['category'] as String? ?? 'tablets').trim();
          if (name.isNotEmpty && dosage.isNotEmpty) {
            return BarcodeLookupResult(
              barcode: candidate,
              name: name,
              dosage: dosage,
              category: MedicineCategory.fromString(categoryName),
              source: BarcodeLookupSource.localCache,
            );
          }
        }
      }
    }

    final backendResult = await (backendLookup ?? _lookupFromBackendProxy)(digits);
    if (backendResult != null) {
      if (cacheWriter != null) {
        await cacheWriter(backendResult);
      }
      return backendResult;
    }

    final onlineResult = await _lookupFromOpenFda(digits, client: client);
    if (onlineResult != null) {
      if (cacheWriter != null) {
        await cacheWriter(onlineResult);
      }
      return onlineResult;
    }

    for (final candidate in _barcodeCandidates(digits)) {
      final local = _barcodeMap[candidate];
      if (local != null) {
        return local;
      }
    }

    return null;
  }

  static Future<BarcodeLookupResult?> _lookupFromBackendProxy(String digits) async {
    try {
      final data = await MySQLApiService().lookupBarcodeFromServer(digits);
      if (data == null) {
        return null;
      }

      final name = (data['name'] as String? ?? '').trim();
      final dosage = (data['dosage'] as String? ?? '').trim();
      final categoryName = (data['category'] as String? ?? 'tablets').trim();
      if (name.isEmpty || dosage.isEmpty) {
        return null;
      }

      return BarcodeLookupResult(
        barcode: (data['barcode'] as String? ?? digits).trim(),
        name: name,
        dosage: dosage,
        category: MedicineCategory.fromString(categoryName),
        source: BarcodeLookupSource.backendApi,
      );
    } catch (_) {
      return null;
    }
  }

  static String _digitsOnly(String barcode) {
    return barcode.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static List<String> _barcodeCandidates(String digits) {
    final set = <String>{digits};
    if (digits.length == 14 && digits.startsWith('0')) {
      set.add(digits.substring(1));
    }
    if (digits.length == 13 && digits.startsWith('0')) {
      set.add(digits.substring(1));
    }
    if (digits.length == 12) {
      set.add('0$digits');
    }
    return set.toList();
  }

  static List<String> _ndcCandidates(String digits) {
    final ndc = <String>{};

    // Common 11-digit zero-padded NDC represented as 5-4-2.
    if (digits.length == 11) {
      ndc.add('${digits.substring(0, 5)}-${digits.substring(5, 9)}-${digits.substring(9, 11)}');
    }

    // Common 10-digit variants.
    if (digits.length >= 10) {
      final tail10 = digits.substring(digits.length - 10);
      ndc.add('${tail10.substring(0, 4)}-${tail10.substring(4, 8)}-${tail10.substring(8, 10)}');
      ndc.add('${tail10.substring(0, 5)}-${tail10.substring(5, 8)}-${tail10.substring(8, 10)}');
      ndc.add('${tail10.substring(0, 5)}-${tail10.substring(5, 9)}-${tail10.substring(9, 10)}');
    }

    return ndc.toList();
  }

  static Future<BarcodeLookupResult?> _lookupFromOpenFda(
    String digits, {
    http.Client? client,
  }) async {
    final ownClient = client == null;
    final requestClient = client ?? http.Client();

    try {
      for (final ndc in _ndcCandidates(digits)) {
        final query = 'product_ndc:"$ndc"+OR+package_ndc:"$ndc"';
        final uri = Uri.parse('$_openFdaBaseUrl/drug/ndc.json').replace(
          queryParameters: {
            if (_openFdaApiKey.isNotEmpty) 'api_key': _openFdaApiKey,
            'search': query,
            'limit': '1',
          },
        );

        final response = await requestClient
            .get(uri)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          continue;
        }

        final dynamic body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) {
          continue;
        }

        final results = body['results'];
        if (results is! List || results.isEmpty || results.first is! Map) {
          continue;
        }

        final first = results.first as Map<String, dynamic>;
        final name = (first['brand_name'] as String?)?.trim().isNotEmpty == true
            ? (first['brand_name'] as String).trim()
            : ((first['generic_name'] as String?)?.trim().isNotEmpty == true
                ? (first['generic_name'] as String).trim()
                : ((first['labeler_name'] as String?)?.trim().isNotEmpty == true
                    ? (first['labeler_name'] as String).trim()
                    : 'Unknown medicine'));

        final activeIngredients = first['active_ingredients'];
        String dosage = 'N/A';
        if (activeIngredients is List && activeIngredients.isNotEmpty) {
          final ingredient = activeIngredients.first;
          if (ingredient is Map<String, dynamic>) {
            dosage = (ingredient['strength'] as String?)?.trim().isNotEmpty == true
                ? (ingredient['strength'] as String).trim()
                : dosage;
          }
        }

        final dosageForm = (first['dosage_form'] as String? ?? '').toLowerCase();
        final category = dosageForm.contains('inject')
            ? MedicineCategory.injection
            : (dosageForm.contains('solution') ||
                    dosageForm.contains('syrup') ||
                    dosageForm.contains('liquid'))
                ? MedicineCategory.syrup
                : MedicineCategory.tablets;

        return BarcodeLookupResult(
          barcode: digits,
          name: name,
          dosage: dosage,
          category: category,
          source: BarcodeLookupSource.onlineApi,
        );
      }
    } catch (_) {
      // Network/API failures should not break barcode flow; fallback handles this.
    } finally {
      if (ownClient) {
        requestClient.close();
      }
    }

    return null;
  }
}


