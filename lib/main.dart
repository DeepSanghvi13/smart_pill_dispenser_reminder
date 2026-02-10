import 'package:flutter/material.dart';

// ✅ CORRECT RELATIVE IMPORT
import 'screens/home/home_screen.dart';
import 'core/app_theme.dart';

void main() {
  runApp(MedisafeApp());
}

class MedisafeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Pill Reminder',
      theme: AppTheme.lightTheme,
      home: HomeScreen(), // ✅ now visible
    );
  }
}
