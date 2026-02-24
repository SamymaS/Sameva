import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/item_model.dart';
import 'inventory_provider.dart';

class EquipmentProvider with ChangeNotifier {
  Box get _box => Hive.box('equipment');

  Map<EquipmentSlot, Item?> _equipped = {
    for (final slot in EquipmentSlot.values) slot: null,
  };

  Map<EquipmentSlot, Item?> get equipped => Map.unmodifiable(_equipped);

  Item? getSlot(EquipmentSlot slot) => _equipped[slot];

  // Agrégats de stats de tous les items équipés
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
      notifyListeners();
    } catch (e) {
      debugPrint('EquipmentProvider: erreur chargement: $e');
      notifyListeners();
    }
  }

  /// Équipe [item] dans [slot]. Si slot occupé, l'ancien item retourne dans l'inventaire.
  /// Retire l'item équipé de l'inventaire.
  void equip(Item item, EquipmentSlot slot, InventoryProvider inventory) {
    final current = _equipped[slot];
    if (current != null) {
      inventory.addItem(current);
    }
    inventory.removeItem(item.id);
    _equipped[slot] = item;
    _save();
    notifyListeners();
  }

  /// Déséquipe [slot] et remet l'item dans l'inventaire.
  void unequip(EquipmentSlot slot, InventoryProvider inventory) {
    final item = _equipped[slot];
    if (item == null) return;
    inventory.addItem(item);
    _equipped[slot] = null;
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
    } catch (e) {
      debugPrint('EquipmentProvider: erreur sauvegarde: $e');
    }
  }
}
