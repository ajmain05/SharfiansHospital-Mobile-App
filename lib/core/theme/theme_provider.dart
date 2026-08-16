import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_initialMode());

  static ThemeMode _initialMode() {
    final cached = LocalStorage.getThemeMode();
    if (cached == 'light') return ThemeMode.light;
    if (cached == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void toggle() {
    if (state == ThemeMode.light || state == ThemeMode.system) {
      state = ThemeMode.dark;
      LocalStorage.saveThemeMode('dark');
    } else {
      state = ThemeMode.light;
      LocalStorage.saveThemeMode('light');
    }
  }

  void setMode(ThemeMode mode) {
    state = mode;
    final String modeStr = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
    LocalStorage.saveThemeMode(modeStr);
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
