import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'services/auth_service.dart';
import 'providers/sync_provider.dart';
import 'providers/medicine_provider.dart';
import 'routes/app_routes.dart';
import 'theme/theme_controller.dart';
import 'screens/client/home/home_screen.dart';
import 'screens/client/alarm/alarm_display_screen.dart';
import 'screens/admin/admin_webpage_screen.dart';
import 'screens/client/auth/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database service (handles both web and native)
  try {
    await DatabaseService().database;
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

          final authService = context.read<AuthService>();
          if (!authService.isCaretaker) {
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
            ChangeNotifierProvider(create: (_) => MedicineProvider()),
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
            navigatorKey: navigatorKey,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                // If user is logged in as caretaker, show caretaker dashboard.
                if (authService.isLoggedIn && authService.isCaretaker) {
                  return const Stack(
                    children: [
                      CaretakerWebpageScreen(),
                      AlarmDisplayScreen(),
                    ],
                  );
                }

                // If regular user is logged in, show home screen only.
                if (authService.isLoggedIn) {
                  return HomeScreen(
                      key: ValueKey(authService.currentUser ?? 'guest'));
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
