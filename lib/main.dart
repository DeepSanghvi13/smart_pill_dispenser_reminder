import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'theme/theme_controller.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        return MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        );
      },
    );
  }
}
