import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io' show Platform;
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'theme/theme_controller.dart';
import 'screens/home/home_screen.dart';
import 'screens/alarm/alarm_display_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for web and cross-platform storage
  try {
    await Hive.initFlutter();
  } catch (e) {
    // ignore: avoid_print
    print('Hive initialization error: $e');
  }

  // Initialize database service (handles both web and native)
  try {
    // Don't await database getter on web, just create the instance
    if (!kIsWeb) {
      await DatabaseService().database;
    } else {
      // On web, just initialize Hive boxes without calling database getter
      final dbService = DatabaseService();
      await dbService.initializeHiveBoxes();
    }
  } catch (e) {
    // ignore: avoid_print
    print('Database initialization error: $e');
  }

  // Initialize notifications
  try {
    await NotificationService.init();
    await NotificationService.requestPermissions();
  } catch (e) {
    // ignore: avoid_print
    print('Notification service error (may be expected on web): $e');
  }

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
