// lib/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Traditional Hindu palette
  static const saffron = Color(0xFFFF9933);
  static const maroon = Color(0xFF800000);
  static const peacock = Color(0xFF1F6E8C);
  static const ivory = Color(0xFFFFF8E1);
  static const wood = Color(0xFF5D4037);

  static final light = ThemeData(
    primaryColor: saffron,
    scaffoldBackgroundColor: ivory,
    appBarTheme: const AppBarTheme(
      backgroundColor: saffron,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: maroon,
      selectedItemColor: saffron,
      unselectedItemColor: Colors.white70,
    ),
    fontFamily: 'Serif', // use an embedded Sanskrit‑style font
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: maroon,
    scaffoldBackgroundColor: wood,
    appBarTheme: const AppBarTheme(
      backgroundColor: maroon,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: wood,
      selectedItemColor: saffron,
      unselectedItemColor: Colors.white70,
    ),
    fontFamily: 'Serif',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}
