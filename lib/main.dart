import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
=======
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io' show Platform;
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'services/auth_service.dart';
import 'providers/sync_provider.dart';
import 'theme/theme_controller.dart';
<<<<<<< HEAD
import 'screens/client/home/home_screen.dart';
import 'screens/client/alarm/alarm_display_screen.dart';
import 'screens/admin/admin_webpage_screen.dart';
import 'screens/client/auth/login_screen.dart';
=======
import 'screens/home/home_screen.dart';
import 'screens/alarm/alarm_display_screen.dart';
import 'screens/admin/admin_webpage_screen.dart';
import 'screens/auth/login_screen.dart';

// For desktop (Windows, Linux, macOS) support with sqflite
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  // Initialize API-backed data service.
  try {
    await DatabaseService().database;
=======
  // Initialize sqflite for desktop platforms (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
  } catch (e) {
    // ignore: avoid_print
    print('Database initialization error: $e');
  }

  runApp(const MyApp());

  // Defer non-critical startup work so first frame appears sooner.
  Future.microtask(() async {
    try {
      await NotificationService.init();
      await NotificationService.requestPermissions();
    } catch (e) {
      // ignore: avoid_print
      print('Notification service error (may be expected on web): $e');
    }

    // Restore login session in background; provider notifies UI when ready.
    try {
      await AuthService().loadSession();
    } catch (e) {
      // ignore: avoid_print
      print('Session restore error: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AlarmService()),
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(
              create: (_) {
                final provider = SyncProvider();
                // Defer sync connectivity checks so core UI is interactive first.
                Future.delayed(const Duration(seconds: 2), provider.initialize);
                return provider;
              },
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                // If user is logged in as admin, show admin dashboard.
                if (authService.isLoggedIn && authService.isAdmin) {
                  return const AdminWebpageScreen();
                }

                // If regular user is logged in, show home + alarm screens.
                if (authService.isLoggedIn) {
                  return Stack(
                    children: [
                      HomeScreen(
                          key: ValueKey(authService.currentUser ?? 'guest')),
                      const AlarmDisplayScreen(),
                    ],
                  );
                }
                // Otherwise show login screen
                return const LoginScreen();
              },
            ),
          ),
        );
      },
    );
  }
}
