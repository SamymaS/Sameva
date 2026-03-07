import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/character_model.dart';

/// Provider gérant l'apparence du personnage (genre, peau, cheveux).
/// Persiste dans la boîte Hive 'settings'.
class CharacterProvider with ChangeNotifier {
  Box get _box => Hive.box('settings');

  late CharacterAppearance _appearance;
  CharacterAppearance get appearance => _appearance;

  CharacterProvider() {
    _load();
  }

  void _load() {
    try {
      final raw = _box.get('character_appearance');
      if (raw != null) {
        _appearance = CharacterAppearance.fromJson(
            Map<String, dynamic>.from(raw as Map));
      } else {
        _appearance = const CharacterAppearance();
      }
    } catch (e) {
      debugPrint('CharacterProvider: erreur chargement: $e');
      _appearance = const CharacterAppearance();
    }
  }

  void updateAppearance(CharacterAppearance newAppearance) {
    _appearance = newAppearance;
    _save();
    notifyListeners();
  }

  void setGender(CharacterGender gender) =>
      updateAppearance(_appearance.copyWith(gender: gender));

  void setSkinTone(SkinTone tone) =>
      updateAppearance(_appearance.copyWith(skinTone: tone));

  void setHairColor(Color color) =>
      updateAppearance(_appearance.copyWith(hairColor: color));

  void setHairStyle(HairStyle style) =>
      updateAppearance(_appearance.copyWith(hairStyle: style));

  void _save() {
    try {
      _box.put('character_appearance', _appearance.toJson());
    } catch (e) {
      debugPrint('CharacterProvider: erreur sauvegarde: $e');
    }
  }
}
