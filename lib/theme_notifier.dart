
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This will generate the .g.dart file
part 'theme_notifier.g.dart';

// The annotation will create the "themeNotifierProvider" for us
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _themePrefKey = 'themeMode';

  // The build method is where we create the initial state.
  @override
  ThemeMode build() {
    // We return a default value here and load the real one asynchronously.
    _loadTheme();
    return ThemeMode.system; 
  }

  // Load the saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  // Method to toggle and save the theme
  Future<void> toggleTheme() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, state.index);
  }
}
