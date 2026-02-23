import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'theme/theme_controller.dart';
import 'screens/home/home_screen.dart';
import 'screens/alarm/alarm_display_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_common_ffi for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database first (data persistence)
  await DatabaseService().database;

  // Initialize notifications
  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ChangeNotifierProvider(
          create: (_) => AlarmService(),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: Stack(
              children: [
                const HomeScreen(),
                const AlarmDisplayScreen(),
              ],
            ),
          ),
        );
      },
    );
  }
}
