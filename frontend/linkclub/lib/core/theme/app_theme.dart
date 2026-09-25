import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Colores de LinkClub
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color brandPurple = Color(0xFF7C3AED);

  // Colores del Modo Claro (Light Theme)
  static const Color backgroundLight = Color(0xFFF7F6F2);
  static const Color surfaceLight = Colors.white;
  static const Color textMainLight = Color(0xFF1F2937);

  // Colores del Modo Oscuro (Dark Theme)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E24);
  static const Color textMainDark = Color(0xFFF3F4F6);

  // Modo claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'DMSans',
      colorScheme: const ColorScheme.light(
        primary: brandBlue,
        onPrimary: Colors.white,
        secondary: brandPurple,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textMainLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textMainLight,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textMainLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textMainLight,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textMainLight),
      ),
    );
  }

  // Modo oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'DMSans',
      colorScheme: const ColorScheme.dark(
        primary: brandBlue,
        onPrimary: Colors.white,
        secondary: brandPurple,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textMainDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textMainDark,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textMainDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textMainDark,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textMainDark),
      ),
    );
  }
}
