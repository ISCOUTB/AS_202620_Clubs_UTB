import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Colores de LinkClub (Tonos modernos y vibrantes)
  static const Color primaryBlue = Color(
    0xFF1E3A8A,
  ); // Azul muy oscuro (Para títulos)
  static const Color brandBlue = Color(
    0xFF2563EB,
  ); // Azul vibrante (Botones y acentos)
  static const Color brandPurple = Color(
    0xFF7C3AED,
  ); // Morado (Detalles secundarios)

  // Colores del Modo Claro (Light Theme)
  // Ajuste premium: Fondo ligeramente gris/azulado (Slate 50) para que las tarjetas blancas resalten.
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white; // Tarjetas puramente blancas
  static const Color textMainLight = Color(
    0xFF0F172A,
  ); // Slate 900 (Negro suave)
  static const Color textSecondaryLight = Color(
    0xFF64748B,
  ); // Slate 500 (Gris para subtítulos)

  // Colores del Modo Oscuro (Dark Theme)
  static const Color backgroundDark = Color(
    0xFF0B0F19,
  ); // Azul casi negro muy profundo
  static const Color surfaceDark = Color(0xFF111827);
  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ---------------------------------------------------------
  // MODO CLARO
  // ---------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: brandBlue,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'DMSans',
      colorScheme: const ColorScheme.light(
        primary: brandBlue,
        onPrimary: Colors.white,
        secondary: brandPurple,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textMainLight,
        // Usado para fondos sutiles de íconos o avatares
        surfaceContainerHighest: Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight, // Se funde limpiamente con el fondo
        foregroundColor: textMainLight,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation:
            0, // Evita que la AppBar se ponga gris al hacer scroll (Comportamiento de M3)
        iconTheme: IconThemeData(color: textMainLight),
      ),
      textTheme: const TextTheme(
        // letterSpacing negativo en títulos grandes da un look muy moderno (estilo Apple/SaaS)
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textMainLight,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textMainLight,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textMainLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textMainLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryLight,
        ), // Gris para textos secundarios
      ),
      // TEMA DE INPUTS: Bordes suaves que cambian a azul al hacer tap
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondaryLight),
        labelStyle: const TextStyle(color: textSecondaryLight),
        prefixIconColor: textSecondaryLight,
      ),
      // TEMA DE BOTONES: Consistentes, sin sombra (flat design) y bordes redondeados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'DMSans',
          ),
        ),
      ),
      // TEMA DE TARJETAS: Reemplaza el gris de tu captura por blanco puro con un borde ultra fino
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // MODO OSCURO
  // ---------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: brandBlue,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'DMSans',
      colorScheme: const ColorScheme.dark(
        primary: brandBlue,
        onPrimary: Colors.white,
        secondary: brandPurple,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textMainDark,
        surfaceContainerHighest: Color(0xFF334155),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textMainDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textMainDark,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textMainDark,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textMainDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textMainDark,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 222, 50, 50),
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(color: textSecondaryDark),
        labelStyle: const TextStyle(color: textSecondaryDark),
        prefixIconColor: textSecondaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'DMSans',
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
    );
  }
}
