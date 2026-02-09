import 'dart:io';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/alarm_restore_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await NotificationService.init();
    await NotificationService.requestPermissions();
  }

  /// Restore alarms automatically
  await AlarmRestoreService.restoreAllAlarms();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Pill Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
