import 'package:flutter_tts/flutter_tts.dart';

class VoiceReminderService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> _init() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _isInitialized = true;
  }

  static Future<void> speakReminder({
    required String medicineName,
    required String dosage,
  }) async {
    await _init();
    await _tts.stop();
    await _tts.speak('Medication reminder. Please take $medicineName, dosage $dosage now.');
  }

  static Future<void> speakMessage(String message) async {
    await _init();
    await _tts.stop();
    await _tts.speak(message);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}

