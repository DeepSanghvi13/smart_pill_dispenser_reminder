import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'services/auth_service.dart';
import 'services/hive_service.dart';
import 'providers/sync_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/photo_provider.dart';
import 'routes/app_routes.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'theme/theme_controller.dart';
import 'screens/client/auth/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize database service (Hive local boxes)
  try {
    await DatabaseService().initializeHiveBoxes();
    
    // Load theme settings from Hive
    final settingsBox = HiveService().settingsBox;
    final savedTheme = settingsBox.get('theme_mode') as String?;
    if (savedTheme != null) {
      themeNotifier.value = ThemeMode.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeMode.light,
      );
    }
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }

  runApp(const MyApp());

  // Defer non-critical startup work so first frame appears sooner.
  Future.microtask(() async {
    try {
      await NotificationService.init();
      await NotificationService.requestPermissions();
      NotificationService.setPayloadHandler((payload) {
        try {
          final decoded = jsonDecode(payload);
          if (decoded is! Map<String, dynamic>) {
            return;
          }
          if (decoded['type'] != 'alarm') {
            return;
          }

          final context = navigatorKey.currentContext;
          if (context == null) {
            return;
          }

          final alarmService = context.read<AlarmService>();
          alarmService.triggerAlarm(
            medicineId: '${decoded['id'] ?? ''}',
            medicineName: (decoded['name'] as String? ?? '').trim(),
            medicineDosage: (decoded['dosage'] as String? ?? '').trim(),
          );
        } catch (_) {
          // Ignore malformed payloads.
        }
      });
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }

    // Restore login session in background; provider notifies UI when ready.
    try {
      await AuthService().loadSession();
    } catch (e) {
      debugPrint('Session restore error: $e');
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
            ChangeNotifierProvider(create: (_) => MedicineProvider()),
            ChangeNotifierProvider(create: (_) => PhotoProvider()),
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
            title: 'Smart Pill Reminder',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF0D4F8B),
              brightness: Brightness.light,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50.withValues(alpha: 0.3),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF0D4F8B),
              brightness: Brightness.dark,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade900.withValues(alpha: 0.3),
              ),
            ),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
