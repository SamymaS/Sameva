import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/item_model.dart';
import './inventory_view_model.dart';

/// ViewModel pour l'équipement joueur.
/// Persisté localement via la Hive box 'equipment'.
///
/// Abonné aux streams [onSignedOut] et [onSignedIn] pour le lifecycle auth
/// uniforme (pattern identique à CatViewModel) :
/// - [onSignedOut] → [reset()] : vide tous les slots et purge les clés Hive fixes.
/// - [onSignedIn] → [loadEquipment()] : recharge (garde [_loaded] idempotente).
///
/// Note P1 : les clés Hive sont fixes ('equipment', 'cosmetics'), non per-user.
/// La migration vers des clés per-user est reportée en P1b (hors périmètre P1).
class EquipmentViewModel with ChangeNotifier {
  final Box _box;
  StreamSubscription<void>? _signedOutSub;
  StreamSubscription<void>? _signedInSub;

  /// Indique si [loadEquipment()] a déjà été exécuté au moins une fois
  /// (boot inclus). Remis à false par [reset()] au logout.
  /// Utilisé comme garde idempotente dans le handler [onSignedIn].
  bool _loaded = false;

  final Map<EquipmentSlot, Item?> _equipped = {
    for (final slot in EquipmentSlot.values) slot: null,
  };

  final Map<String, Item?> _cosmetics = {
    'hat': null,
    'outfit': null,
    'pants': null,
    'shoes': null,
    'aura': null,
  };

  static const List<String> cosmeticSlots = ['hat', 'outfit', 'pants', 'shoes', 'aura'];

  EquipmentViewModel(this._box, {Stream<void>? onSignedOut, Stream<void>? onSignedIn}) {
    if (onSignedOut != null) {
      _signedOutSub = onSignedOut.listen((_) => reset());
    }
    if (onSignedIn != null) {
      _signedInSub = onSignedIn.listen((_) {
        // Garde idempotente : si l'équipement a déjà été chargé au boot
        // (session persistée), ne pas recharger. Après onSignedOut (reset()),
        // _loaded == false → rechargement déclenché.
        if (_loaded) return;
        loadEquipment();
      });
    }
  }

  @override
  void dispose() {
    _signedOutSub?.cancel();
    _signedInSub?.cancel();
    super.dispose();
  }

  Map<EquipmentSlot, Item?> get equipped => Map.unmodifiable(_equipped);

  Item? getCosmeticSlot(String slot) => _cosmetics[slot];

  Item? getSlot(EquipmentSlot slot) => _equipped[slot];

  int get xpBonusPercent => _sumStat('xpBonus');
  int get goldBonusPercent => _sumStat('goldBonus');
  int get hpBonus => _sumStat('hpBonus');
  int get moralBonus => _sumStat('moralBonus');

  int _sumStat(String key) {
    int total = 0;
    for (final item in _equipped.values) {
      if (item != null) {
        total += item.stats[key] ?? 0;
      }
    }
    return total;
  }

  void loadEquipment() {
    try {
      final raw = _box.get('equipment');
      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        for (final slot in EquipmentSlot.values) {
          final itemData = map[slot.name];
          if (itemData != null) {
            _equipped[slot] =
                Item.fromJson(Map<String, dynamic>.from(itemData as Map));
          } else {
            _equipped[slot] = null;
          }
        }
      }
      final rawCosmetics = _box.get('cosmetics');
      if (rawCosmetics != null) {
        final cosMap = Map<String, dynamic>.from(rawCosmetics as Map);
        for (final slot in cosmeticSlots) {
          final itemData = cosMap[slot];
          if (itemData != null) {
            _cosmetics[slot] =
                Item.fromJson(Map<String, dynamic>.from(itemData as Map));
          } else {
            _cosmetics[slot] = null;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('EquipmentViewModel: erreur chargement: $e');
      notifyListeners();
    } finally {
      // Marque le chargement comme effectué (même sur erreur) pour éviter
      // les tentatives répétées via le handler onSignedIn.
      _loaded = true;
    }
  }

  void equip(Item item, EquipmentSlot slot, InventoryViewModel inventory) {
    final current = _equipped[slot];
    if (current != null) {
      inventory.addItem(current);
    }
    inventory.removeItem(item.id);
    _equipped[slot] = item;
    _save();
    notifyListeners();
  }

  void unequip(EquipmentSlot slot, InventoryViewModel inventory) {
    final item = _equipped[slot];
    if (item == null) return;
    inventory.addItem(item);
    _equipped[slot] = null;
    _save();
    notifyListeners();
  }

  void equipCosmetic(Item item, String slot, InventoryViewModel inventory) {
    final current = _cosmetics[slot];
    if (current != null) {
      inventory.addItem(current);
    }
    inventory.removeItem(item.id);
    _cosmetics[slot] = item;
    _save();
    notifyListeners();
  }

  void unequipCosmetic(String slot, InventoryViewModel inventory) {
    final item = _cosmetics[slot];
    if (item == null) return;
    inventory.addItem(item);
    _cosmetics[slot] = null;
    _save();
    notifyListeners();
  }

  /// Vide tous les slots équipement + cosmétiques en mémoire et dans Hive (changement de compte).
  /// Remet [_loaded] à false pour que le handler [onSignedIn] recharge au prochain login.
  Future<void> reset() async {
    for (final slot in EquipmentSlot.values) {
      _equipped[slot] = null;
    }
    for (final slot in cosmeticSlots) {
      _cosmetics[slot] = null;
    }
    _loaded = false;
    try {
      await _box.delete('equipment');
      await _box.delete('cosmetics');
    } catch (e) {
      debugPrint('EquipmentViewModel: erreur reset: $e');
    }
    notifyListeners();
  }

  void _save() {
    try {
      final map = <String, dynamic>{};
      for (final entry in _equipped.entries) {
        if (entry.value != null) {
          map[entry.key.name] = entry.value!.toJson();
        }
      }
      _box.put('equipment', map);

      final cosMap = <String, dynamic>{};
      for (final entry in _cosmetics.entries) {
        if (entry.value != null) {
          cosMap[entry.key] = entry.value!.toJson();
        }
      }
      _box.put('cosmetics', cosMap);
    } catch (e) {
      debugPrint('EquipmentViewModel: erreur sauvegarde: $e');
    }
  }
}
