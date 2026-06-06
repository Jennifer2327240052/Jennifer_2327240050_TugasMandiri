import 'package:flutter/material.dart';

class AppTheme {
  // Tema Terang
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.brown, // Warna tema untuk kedai kopi
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.brown,
      foregroundColor: Colors.white,
    ),
  );

  // Tema Gelap
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.brown,
    scaffoldBackgroundColor: Colors.black87,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
  );
}
