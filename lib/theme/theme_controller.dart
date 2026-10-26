import 'package:flutter/material.dart';
import '../services/hive_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> setThemeMode(ThemeMode mode) async {
  themeNotifier.value = mode;
  await HiveService().settingsBox.put('theme_mode', mode.name);
}
