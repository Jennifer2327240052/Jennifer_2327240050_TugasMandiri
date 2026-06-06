import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A5F7A);
  static const Color secondaryColor = Color(0xFF74C69D);
  static const Color neutralBackground = Color(0xFFF8F9FA);
  static const Color accentColor = Color(0xFFFF9F89);

  // Tema Terang
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: neutralBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: neutralBackground,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
      ),
    ),
  );

  // Tema Gelap
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.black87,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
  );
}

