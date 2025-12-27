import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/item.dart';

class InventoryProvider with ChangeNotifier {
  Box get _inventoryBox => Hive.box('inventory');

  List<InventorySlot> _items = [];
  int _maxSlots = 50; // Nombre maximum de slots d'inventaire

  List<InventorySlot> get items => _items;
  int get maxSlots => _maxSlots;
  int get usedSlots => _items.length;
  bool get isFull => _items.length >= _maxSlots;

  void _loadInventoryFromBox() {
    try {
      final itemsList = _inventoryBox.get('items', defaultValue: <Map>[]);
      _items = (itemsList as List)
          .map((json) {
            // Convertir dynamiquement en Map<String, dynamic>
            if (json is Map) {
              return InventorySlot.fromJson(
                Map<String, dynamic>.from(
                  json.map((key, value) => MapEntry(key.toString(), value))
                )
              );
            }
            throw Exception('Format invalide pour l\'item: $json');
          })
          .toList();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement de l\'inventaire: $e');
      _items = [];
      notifyListeners();
    }
  }

  Future<void> _saveInventoryToBox() async {
    try {
      final itemsJson = _items.map((slot) => slot.toJson()).toList();
      await _inventoryBox.put('items', itemsJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'inventaire: $e');
    }
  }

  Future<void> loadInventory(String userId) async {
    _loadInventoryFromBox();
  }

  Future<void> saveInventory(String userId) async {
    await _saveInventoryToBox();
  }

  /// Ajoute un item à l'inventaire
  Future<bool> addItem(String userId, Item item, {int quantity = 1}) async {
    if (isFull && !_hasItem(item.id)) {
      return false; // Inventaire plein
    }

    // Vérifier si l'item existe déjà et est empilable
    final existingIndex = _items.indexWhere((slot) => slot.item.id == item.id);
    
    if (existingIndex != -1 && item.stackSize > 1) {
      // Empiler l'item
      final existingSlot = _items[existingIndex];
      final newQuantity = existingSlot.quantity + quantity;
      
      if (newQuantity <= item.stackSize) {
        _items[existingIndex] = existingSlot.copyWith(quantity: newQuantity);
      } else {
        // Slot plein, créer un nouveau slot si possible
        if (_items.length >= _maxSlots) {
          return false;
        }
        final remaining = newQuantity - item.stackSize;
        _items[existingIndex] = existingSlot.copyWith(quantity: item.stackSize);
        _items.add(InventorySlot(item: item, quantity: remaining));
      }
    } else {
      // Nouvel item ou item non-empilable
      if (existingIndex == -1) {
        if (_items.length >= _maxSlots) {
          return false;
        }
        _items.add(InventorySlot(item: item, quantity: quantity));
      } else {
        // Item non-empilable, créer un nouveau slot
        if (_items.length >= _maxSlots) {
          return false;
        }
        _items.add(InventorySlot(item: item, quantity: quantity));
      }
    }

    notifyListeners();
    await saveInventory(userId);
    return true;
  }

  /// Retire un item de l'inventaire
  Future<bool> removeItem(String userId, String itemId, {int quantity = 1}) async {
    final index = _items.indexWhere((slot) => slot.item.id == itemId);
    
    if (index == -1) {
      return false;
    }

    final slot = _items[index];
    
    if (slot.quantity <= quantity) {
      // Retirer tout le slot
      _items.removeAt(index);
    } else {
      // Réduire la quantité
      _items[index] = slot.copyWith(quantity: slot.quantity - quantity);
    }

    notifyListeners();
    await saveInventory(userId);
    return true;
  }

  /// Vérifie si l'inventaire contient un item
  bool _hasItem(String itemId) {
    return _items.any((slot) => slot.item.id == itemId);
  }

  /// Obtient la quantité d'un item dans l'inventaire
  int getItemQuantity(String itemId) {
    final slot = _items.firstWhere(
      (slot) => slot.item.id == itemId,
      orElse: () => InventorySlot(item: Item(name: '', description: '', type: ItemType.material, rarity: ItemRarity.common, value: 0), quantity: 0),
    );
    return slot.quantity;
  }

  /// Obtient un item par son ID
  Item? getItemById(String itemId) {
    try {
      final slot = _items.firstWhere((slot) => slot.item.id == itemId);
      return slot.item;
    } catch (e) {
      return null;
    }
  }

  /// Obtient tous les items d'un type spécifique
  List<InventorySlot> getItemsByType(ItemType type) {
    return _items.where((slot) => slot.item.type == type).toList();
  }

  /// Obtient tous les items équipables
  List<InventorySlot> getEquippableItems() {
    return _items.where((slot) => slot.item.isEquippable).toList();
  }

  /// Vide l'inventaire (pour tests)
  Future<void> clearInventory(String userId) async {
    _items.clear();
    notifyListeners();
    await saveInventory(userId);
  }
}







