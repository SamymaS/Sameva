import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ViewModel pour la préférence de thème.
/// Toggle thème désactivé pour MVP — dark mode uniquement.
/// Réactiver via FeatureFlag en Phase 2.
class ThemeViewModel with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final Box _box;

  ThemeViewModel(this._box);

  /// Toujours dark pour le MVP.
  ThemeMode get themeMode => ThemeMode.dark;

  bool get isDarkMode => true;

  /// Conservée pour compatibilité future, sans effet pour le MVP.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(_themeKey, mode.toString());
    // Pas de notifyListeners — themeMode est fixe.
  }
}
