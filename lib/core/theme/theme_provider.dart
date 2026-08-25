import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_initialMode());

  static ThemeMode _initialMode() {
    // Defaults to light regardless of the phone's own system setting — the
    // Settings screen only ever exposes an explicit light/dark switch, never
    // a "follow system" option, so falling back to ThemeMode.system here
    // just meant a fresh install silently inherited the OS theme instead of
    // showing what the app actually looks like by default.
    final cached = LocalStorage.getThemeMode();
    if (cached == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
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
