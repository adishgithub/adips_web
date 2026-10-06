import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Persists the chosen theme mode. Dark is the ADIPS primary identity,
/// so it is the default until the user picks something else.
class ThemeModeStore {
  ThemeModeStore._();

  static const _key = 'theme_mode';
  static final _box = GetStorage();

  static ThemeMode load() => switch (_box.read<String>(_key)) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  static void set(ThemeMode mode) {
    _box.write(_key, mode.name);
    Get.changeThemeMode(mode);
  }

  static void toggle() => set(
      Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
}
