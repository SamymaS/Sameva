import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/item_model.dart';

class InventoryProvider with ChangeNotifier {
  static const int _maxSlots = 50;

  Box get _box => Hive.box('inventory');

  List<Item> _items = [];

  List<Item> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isFull => _items.length >= _maxSlots;

  List<Item> getItemsByType(ItemType type) =>
      _items.where((i) => i.type == type).toList();

  void loadInventory() {
    try {
      final raw = _box.get('items');
      if (raw != null) {
        final list = (raw as List).cast<Map>();
        _items = list
            .map((m) => Item.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      } else {
        _items = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('InventoryProvider: erreur chargement: $e');
      _items = [];
      notifyListeners();
    }
  }

  /// Ajoute un item. Empile si stackable et existe déjà. Retourne false si plein.
  bool addItem(Item item) {
    if (item.stackable) {
      final idx = _items.indexWhere(
          (i) => i.name == item.name && i.type == item.type);
      if (idx >= 0) {
        _items[idx] =
            _items[idx].copyWith(quantity: _items[idx].quantity + item.quantity);
        _save();
        notifyListeners();
        return true;
      }
    }

    if (_items.length >= _maxSlots) return false;

    _items.add(item);
    _save();
    notifyListeners();
    return true;
  }

  /// Retire [quantity] unités de l'item [id]. Supprime si quantité = 0.
  void removeItem(String id, {int quantity = 1}) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;

    final current = _items[idx];
    if (current.quantity <= quantity) {
      _items.removeAt(idx);
    } else {
      _items[idx] = current.copyWith(quantity: current.quantity - quantity);
    }
    _save();
    notifyListeners();
  }

  void _save() {
    try {
      _box.put('items', _items.map((i) => i.toJson()).toList());
    } catch (e) {
      debugPrint('InventoryProvider: erreur sauvegarde: $e');
    }
  }
}
