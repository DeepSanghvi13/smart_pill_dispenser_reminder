import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class MedicineScanResult {
  final String? medicineName;
  final String? dosage;
  final DateTime? expiryDate;
  final String? healthCondition;
  final String extractedText;
  final String imagePath;

  const MedicineScanResult({
    required this.medicineName,
    required this.dosage,
    required this.expiryDate,
    required this.healthCondition,
    required this.extractedText,
    required this.imagePath,
  });
}

class MedicineScanService {
  static final ImagePicker _picker = ImagePicker();

  static Future<MedicineScanResult?> scanMedicineFromImage() async {
    if (kIsWeb) {
      return null;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return null;
    }

    final String text = await _recognizeText(image.path);
    final parsed = parseMedicineText(text);

    return MedicineScanResult(
      medicineName: parsed.medicineName,
      dosage: parsed.dosage,
      expiryDate: parsed.expiryDate,
      healthCondition: parsed.healthCondition,
      extractedText: text,
      imagePath: image.path,
    );
  }

  static Future<String> _recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  static ParsedMedicineText parseMedicineText(String text) {
    final normalized = text
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final dosageRegex = RegExp(
      r'(\d+(?:\.\d+)?\s?(?:mg|mcg|g|ml|iu))',
      caseSensitive: false,
    );

    String? dosage;
    for (final line in normalized) {
      final match = dosageRegex.firstMatch(line);
      if (match != null) {
        dosage = match.group(1)?.toUpperCase();
        break;
      }
    }

    DateTime? expiryDate = _extractExpiryDate(normalized);
    String? healthCondition = _extractHealthCondition(normalized, dosageRegex);

    String? medicineName;
    for (final line in normalized) {
      final lower = line.toLowerCase();
      if (dosageRegex.hasMatch(line)) {
        continue;
      }
      if (lower.contains('tablet') ||
          lower.contains('capsule') ||
          lower.contains('syrup') ||
          lower.contains('injection')) {
        medicineName = line;
        break;
      }
    }

    medicineName ??= normalized.isNotEmpty ? normalized.first : null;

    return ParsedMedicineText(
      medicineName: medicineName,
      dosage: dosage,
      expiryDate: expiryDate,
      healthCondition: healthCondition,
    );
  }

  static DateTime? _extractExpiryDate(List<String> lines) {
    final dateRegex = RegExp(
      r'(\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4}|\d{4}[\/-]\d{1,2}[\/-]\d{1,2})',
    );
    final labelRegex = RegExp(
      r'(exp|expiry|use by|best before|expires)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (!labelRegex.hasMatch(line) && !dateRegex.hasMatch(line)) {
        continue;
      }
      final match = dateRegex.firstMatch(line);
      if (match == null) {
        continue;
      }
      final parsed = _parseDateString(match.group(1) ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static DateTime? _parseDateString(String raw) {
    final sanitized = raw.replaceAll(RegExp(r'[^0-9\/-]'), '');
    if (sanitized.isEmpty) return null;

    if (sanitized.contains('/')) {
      final parts = sanitized.split('/');
      return _parseDateParts(parts);
    }
    if (sanitized.contains('-')) {
      final parts = sanitized.split('-');
      return _parseDateParts(parts);
    }
    return null;
  }

  static DateTime? _parseDateParts(List<String> parts) {
    if (parts.length != 3) return null;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) {
      return null;
    }

    int year;
    int month;
    int day;

    if (parts[0].length == 4) {
      year = first;
      month = second;
      day = third;
    } else if (parts[2].length == 4) {
      year = third;
      if (first > 12) {
        day = first;
        month = second;
      } else if (second > 12) {
        day = second;
        month = first;
      } else {
        day = first;
        month = second;
      }
    } else {
      year = 2000 + third;
      day = first;
      month = second;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static String? _extractHealthCondition(
    List<String> lines,
    RegExp dosageRegex,
  ) {
    final conditionRegex = RegExp(
      r'(indication|use|used for|for|treats?|relief)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (!conditionRegex.hasMatch(line)) {
        continue;
      }
      if (dosageRegex.hasMatch(line)) {
        continue;
      }
      final cleaned = line
          .replaceAll(
              RegExp(r'^(indication|use|used for|for|treats?|relief)[:\s-]*',
                  caseSensitive: false),
              '')
          .trim();
      if (cleaned.isNotEmpty && cleaned.length <= 80) {
        return cleaned;
      }
    }

    return null;
  }
}

class ParsedMedicineText {
  final String? medicineName;
  final String? dosage;
  final DateTime? expiryDate;
  final String? healthCondition;

  const ParsedMedicineText({
    required this.medicineName,
    required this.dosage,
    required this.expiryDate,
    required this.healthCondition,
  });
}
