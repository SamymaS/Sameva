import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cat_model.dart';
import '../../data/models/quest_model.dart';

/// ViewModel gérant les chats compagnons du joueur.
/// Stockage JSON dans la boîte Hive 'cats', avec clés isolées par user_id.
class CatViewModel extends ChangeNotifier {
  // Clé de migration conservée pour référence uniquement (non utilisée en écriture).
  // @deprecated Remplacée par _catsListKeyFor(userId) depuis le 15/05/26.
  // ignore: unused_field
  static const _catsKeyLegacy = 'cats_list';

  final Box _box;

  /// Injecté en test pour contourner l'accès à Supabase.instance.
  /// En production, laissé null → accès via Supabase.instance.client.
  final String? _overrideUserId;

  StreamSubscription<void>? _signedOutSub;
  StreamSubscription<void>? _signedInSub;

  List<CatStats> _cats = [];
  String? _error;
  bool _loading = false;

  CatViewModel(
    this._box, {
    Stream<void>? onSignedOut,
    Stream<void>? onSignedIn,
    String? testUserId,
  }) : _overrideUserId = testUserId {
    if (onSignedOut != null) {
      _signedOutSub = onSignedOut.listen((_) => reset());
    }
    if (onSignedIn != null) {
      // Recharge les chats après connexion (retour login ou changement de compte).
      _signedInSub = onSignedIn.listen((_) => loadCats());
    }
  }

  /// Retourne l'identifiant de l'utilisateur courant.
  /// En production : Supabase.instance.client.auth.currentUser?.id.
  /// En test : valeur injectée via testUserId (évite l'accès à Supabase.instance).
  String? get _currentUserId {
    if (_overrideUserId != null) return _overrideUserId;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase non initialisé (environnement de test sans testUserId).
      return null;
    }
  }

  /// Clé Hive isolée par user_id.
  /// Si userId est inconnu (utilisateur non connecté), retourne null → no-op.
  String? get _hiveKey {
    final uid = _currentUserId;
    if (uid == null) return null;
    return 'cats_list_$uid';
  }

  @override
  void dispose() {
    _signedOutSub?.cancel();
    _signedInSub?.cancel();
    super.dispose();
  }

  List<CatStats> get cats => List.unmodifiable(_cats);
  String? get error => _error;
  bool get loading => _loading;

  CatStats? get mainCat {
    try {
      return _cats.firstWhere((c) => c.isMain);
    } catch (_) {
      return _cats.isNotEmpty ? _cats.first : null;
    }
  }

  void loadCats() {
    // Idempotent : si les chats sont déjà en mémoire, ne pas écraser.
    // Évite un double-load au boot initial quand onSignedIn se déclenche
    // juste après le loadCats() appelé dans main.dart.
    if (_cats.isNotEmpty) return;

    final key = _hiveKey;
    if (key == null) {
      // Utilisateur non connecté → no-op propre, aucun accès Hive.
      return;
    }

    try {
      final raw = _box.get(key);
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

  Future<void> createMainCat(String race, String name) async {
    final key = _hiveKey;
    if (key == null) return; // Utilisateur non connecté → no-op propre.

    // Garde idempotente : relit Hive en synchrone pour couvrir le cas où
    // _cats est vide en mémoire mais Hive contient déjà un compagnon principal
    // (ex. : appel avant loadCats(), ou rechargement suite à reset() partiel).
    if (_cats.isEmpty) {
      final raw = _box.get(key);
      if (raw != null) {
        final list = raw as List<dynamic>;
        _cats = list
            .map((e) => CatStats.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }
    if (_cats.any((c) => c.isMain)) {
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
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

  Future<void> equipCosmetic(String catId, String slot, String? cosmeticId) async {
    _error = null;
    try {
      final index = _cats.indexWhere((c) => c.id == catId);
      if (index == -1) return;

      final cat = _cats[index];
      final updated = switch (slot) {
        'hat'       => cat.copyWith(equippedHat: cosmeticId),
        'outfit'    => cat.copyWith(equippedOutfit: cosmeticId),
        'pants'     => cat.copyWith(equippedPants: cosmeticId),
        'shoes'     => cat.copyWith(equippedShoes: cosmeticId),
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

  /// Retire tous les cosmétiques équipés du chat.
  Future<void> clearAllCosmetics(String catId) async {
    _error = null;
    try {
      final index = _cats.indexWhere((c) => c.id == catId);
      if (index == -1) return;
      _cats[index] = _cats[index].copyWith(
        equippedHat: null,
        equippedOutfit: null,
        equippedPants: null,
        equippedShoes: null,
        equippedAura: null,
        equippedAccessory: null,
        equippedTitle: null,
      );
      await _persist();
    } catch (e) {
      _error = 'Erreur retrait cosmétiques : $e';
    }
    notifyListeners();
  }

  /// Équipe une combinaison aléatoire de cosmétiques parmi ceux fournis.
  /// [bySlot] : map slot → liste d'IDs disponibles. Slot vide = inchangé.
  Future<void> randomizeCosmetics(
      String catId, Map<String, List<String>> bySlot) async {
    _error = null;
    try {
      final index = _cats.indexWhere((c) => c.id == catId);
      if (index == -1) return;
      String? pick(String slot) {
        final ids = bySlot[slot];
        if (ids == null || ids.isEmpty) return null;
        ids.shuffle();
        return ids.first;
      }
      _cats[index] = _cats[index].copyWith(
        equippedHat: pick('hat'),
        equippedOutfit: pick('outfit'),
        equippedPants: pick('pants'),
        equippedShoes: pick('shoes'),
        equippedAura: pick('aura'),
        equippedAccessory: pick('accessory'),
        equippedTitle: pick('title'),
      );
      await _persist();
    } catch (e) {
      _error = 'Erreur randomisation : $e';
    }
    notifyListeners();
  }

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

  Future<void> setMainCat(String catId) async {
    _cats = _cats.map((c) => c.copyWith(isMain: c.id == catId)).toList();
    await _persist();
    notifyListeners();
  }

  String getCatMoodExpression(double moral, int streak) {
    if (streak >= 7 && moral >= 0.8) return 'excited';
    if (moral >= 0.7) return 'happy';
    if (moral >= 0.4) return 'neutral';
    if (moral >= 0.2) return 'sad';
    return 'sleepy';
  }

  static String _raceForRarity(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.mythic:
      case QuestRarity.legendary:
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

  /// Vide uniquement le state in-memory au logout.
  // Pas de purge Hive : les clés cats_list_$userId isolent les données par user.
  // Le reset() ici ne vide que le state in-memory pour forcer un reload propre
  // au prochain login (15/05/26)
  void reset() {
    _cats = [];
    _error = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    final key = _hiveKey;
    if (key == null) return; // Utilisateur non connecté → no-op propre.
    await _box.put(key, _cats.map((c) => c.toJson()).toList());
  }

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
