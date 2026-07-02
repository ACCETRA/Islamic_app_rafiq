import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current [ThemeMode] so any screen can switch it
/// live (e.g. the Dark Mode toggle in Settings) and have [MyApp]
/// react immediately, without a state management package.
class ThemeController {
  ThemeController._();

  static const String _prefsKey = 'dark_mode';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.system);

  /// Loads any previously saved override. Leaves [mode] at
  /// [ThemeMode.system] if the user has never toggled it.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefsKey);
    if (isDark != null) {
      mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  static Future<void> setDarkMode(bool isDark) async {
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }
}
