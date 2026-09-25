import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _prefsKey = 'theme_mode';

  /// Debe llamarse una vez al iniciar la app, antes de runApp().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    mode.value = ThemeMode.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> toggle() async {
    final isDark = mode.value == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    mode.value = newMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newMode.name);
  }

  static bool get isDark => mode.value == ThemeMode.dark;
}
