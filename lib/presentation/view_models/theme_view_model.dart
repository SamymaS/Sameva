import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ViewModel pour la préférence de thème (light/dark/system).
/// Persisté dans la Hive box 'settings'.
class ThemeViewModel with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final Box _box;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeViewModel(this._box) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // ignore: deprecated_member_use
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _loadThemeMode() {
    final saved = _box.get(_themeKey);
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _box.put(_themeKey, mode.toString());
    notifyListeners();
  }
}
