import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cat_model.dart';
import '../../data/models/quest_model.dart';

/// Provider gérant les chats compagnons du joueur.
/// Stockage JSON dans la boîte Hive 'cats'.
class CatProvider extends ChangeNotifier {
  static const _boxName = 'cats';
  static const _catsKey = 'cats_list';

  List<CatStats> _cats = [];
  String? _error;
  bool _loading = false;

  List<CatStats> get cats => List.unmodifiable(_cats);
  String? get error => _error;
  bool get loading => _loading;

  /// Chat principal du joueur (isMain == true).
  CatStats? get mainCat {
    try {
      return _cats.firstWhere((c) => c.isMain);
    } catch (_) {
      return _cats.isNotEmpty ? _cats.first : null;
    }
  }

  // ──────────────────────────────────────────────
  // Chargement
  // ──────────────────────────────────────────────

  /// Charge les chats depuis Hive.
  void loadCats() {
    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_catsKey);
      if (raw == null) {
        _cats = [];
      } else {
        final list = raw as List<dynamic>;
        _cats = list
            .map((e) => CatStats.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      _error = 'Erreur chargement chats : $e';
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Création
  // ──────────────────────────────────────────────

  /// Crée le chat principal du joueur (appelé à la fin de l'onboarding).
  Future<void> createMainCat(String race, String name) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Désigner tous les chats existants comme non-principaux
      _cats = _cats.map((c) => c.copyWith(isMain: false)).toList();

      final cat = CatStats(
        id: const Uuid().v4(),
        name: name.trim().isEmpty ? _defaultNameForRace(race) : name.trim(),
        race: race,
        rarity: 'common',
        isMain: true,
        obtainedAt: DateTime.now(),
      );

      _cats.add(cat);
      await _persist();
    } catch (e) {
      _error = 'Erreur création chat : $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // Cosmétiques
  // ──────────────────────────────────────────────

  /// Équipe un cosmétique sur un chat.
  /// [slot] : 'hat' | 'outfit' | 'aura' | 'accessory' | 'title'
  Future<void> equipCosmetic(
      String catId, String slot, String? cosmeticId) async {
    _error = null;
    try {
      final index = _cats.indexWhere((c) => c.id == catId);
      if (index == -1) return;

      final cat = _cats[index];
      final updated = switch (slot) {
        'hat'       => cat.copyWith(equippedHat: cosmeticId),
        'outfit'    => cat.copyWith(equippedOutfit: cosmeticId),
        'aura'      => cat.copyWith(equippedAura: cosmeticId),
        'accessory' => cat.copyWith(equippedAccessory: cosmeticId),
        'title'     => cat.copyWith(equippedTitle: cosmeticId),
        _           => cat,
      };

      _cats[index] = updated;
      await _persist();
    } catch (e) {
      _error = 'Erreur équipement cosmétique : $e';
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Renommage
  // ──────────────────────────────────────────────

  Future<void> renameCat(String catId, String newName) async {
    _error = null;
    try {
      final index = _cats.indexWhere((c) => c.id == catId);
      if (index == -1) return;
      _cats[index] = _cats[index].copyWith(name: newName.trim());
      await _persist();
    } catch (e) {
      _error = 'Erreur renommage : $e';
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Gacha de chats
  // ──────────────────────────────────────────────

  /// Génère et ajoute un nouveau chat à la collection via le gacha.
  /// La race est déterminée par la rareté [rarity].
  /// Retourne le nouveau [CatStats] créé.
  Future<CatStats> addRolledCat(QuestRarity rarity) async {
    final race = _raceForRarity(rarity);
    final cat = CatStats(
      id: const Uuid().v4(),
      name: _defaultNameForRace(race),
      race: race,
      rarity: rarity.name,
      isMain: false,
      obtainedAt: DateTime.now(),
    );
    _cats.add(cat);
    await _persist();
    notifyListeners();
    return cat;
  }

  /// Définit un chat comme chat principal.
  Future<void> setMainCat(String catId) async {
    _cats = _cats.map((c) => c.copyWith(isMain: c.id == catId)).toList();
    await _persist();
    notifyListeners();
  }

  /// Sélectionne une race de chat selon la rareté du tirage.
  static String _raceForRarity(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.mythic:
      case QuestRarity.legendary:
        // Races mystiques — cosmos ou sakura avec une chance aléatoire
        return _rnd(['cosmos', 'sakura', 'cosmos', 'sakura', 'cosmos']);
      case QuestRarity.epic:
        return _rnd(['cosmos', 'sakura']);
      case QuestRarity.rare:
        return _rnd(['braise', 'lune']);
      case QuestRarity.uncommon:
        return _rnd(['braise', 'lune', 'michi', 'neige']);
      case QuestRarity.common:
        return _rnd(['michi', 'neige']);
    }
  }

  static String _rnd(List<String> choices) {
    choices.shuffle();
    return choices.first;
  }

  // ──────────────────────────────────────────────
  // Expression / humeur
  // ──────────────────────────────────────────────

  /// Retourne l'expression idle du chat selon le moral et le streak.
  String getCatMoodExpression(double moral, int streak) {
    if (streak >= 7 && moral >= 0.8) return 'excited';
    if (moral >= 0.7) return 'happy';
    if (moral >= 0.4) return 'neutral';
    if (moral >= 0.2) return 'sad';
    return 'sleepy';
  }

  // ──────────────────────────────────────────────
  // Persistance
  // ──────────────────────────────────────────────

  Future<void> _persist() async {
    final box = Hive.box(_boxName);
    await box.put(_catsKey, _cats.map((c) => c.toJson()).toList());
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  String _defaultNameForRace(String race) => switch (race) {
        'michi'  => 'Michi',
        'lune'   => 'Luna',
        'braise' => 'Braise',
        'neige'  => 'Flocon',
        'cosmos' => 'Cosmos',
        'sakura' => 'Sakura',
        _        => 'Chat',
      };
}
