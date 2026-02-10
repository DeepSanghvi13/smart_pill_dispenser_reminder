import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: Color(0xff4CAF50),
    scaffoldBackgroundColor: Color(0xffF8FAFC),
    useMaterial3: true,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
