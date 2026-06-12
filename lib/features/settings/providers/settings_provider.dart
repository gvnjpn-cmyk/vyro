import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/constants/app_constants.dart';

class SettingsNotifier extends StateNotifier<ThemeMode> {
  SettingsNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final saved =
        DatabaseService.settingsBox.get(AppConstants.themeKey, defaultValue: 0);
    switch (saved) {
      case 1:
        state = ThemeMode.light;
        break;
      case 2:
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    int val = 0;
    if (mode == ThemeMode.light) val = 1;
    if (mode == ThemeMode.dark) val = 2;
    await DatabaseService.settingsBox.put(AppConstants.themeKey, val);
  }
}

final themeModeProvider =
    StateNotifierProvider<SettingsNotifier, ThemeMode>((ref) {
  return SettingsNotifier();
});
