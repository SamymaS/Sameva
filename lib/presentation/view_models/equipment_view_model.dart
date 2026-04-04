import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/item_model.dart';
import './inventory_view_model.dart';

/// ViewModel pour l'équipement joueur.
/// Persisté localement via la Hive box 'equipment'.
class EquipmentViewModel with ChangeNotifier {
  final Box _box;

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

  EquipmentViewModel(this._box);

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
