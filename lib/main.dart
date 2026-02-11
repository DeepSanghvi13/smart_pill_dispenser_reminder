import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'screens/home/home_screen.dart';

void main() {
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
          home: const HomeScreen(),
        );
      },
    );
  }
}
