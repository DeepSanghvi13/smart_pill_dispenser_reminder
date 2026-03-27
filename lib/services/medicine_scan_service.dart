import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class MedicineScanResult {
  final String? medicineName;
  final String? dosage;
  final String extractedText;
  final String imagePath;

  const MedicineScanResult({
    required this.medicineName,
    required this.dosage,
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

    return ParsedMedicineText(medicineName: medicineName, dosage: dosage);
  }
}

class ParsedMedicineText {
  final String? medicineName;
  final String? dosage;

  const ParsedMedicineText({required this.medicineName, required this.dosage});
}
<<<<<<< HEAD

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
