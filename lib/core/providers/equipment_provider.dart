import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/equipment.dart';
import '../models/item.dart';

class EquipmentProvider with ChangeNotifier {
  Box get _equipmentBox => Hive.box('equipment');

  PlayerEquipment? _playerEquipment;
  Companion? _companion;

  PlayerEquipment? get playerEquipment => _playerEquipment;
  Companion? get companion => _companion;

  void _loadEquipmentFromBox() {
    try {
      final equipmentJson = _equipmentBox.get('playerEquipment');
      if (equipmentJson != null) {
        _playerEquipment = PlayerEquipment.fromJson(
          Map<String, dynamic>.from(equipmentJson as Map),
        );
      } else {
        _playerEquipment = PlayerEquipment();
      }

      final companionJson = _equipmentBox.get('companion');
      if (companionJson != null) {
        _companion = Companion.fromJson(
          Map<String, dynamic>.from(companionJson as Map),
        );
      }
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement de l\'équipement: $e');
      _playerEquipment = PlayerEquipment();
      notifyListeners();
    }
  }

  Future<void> _saveEquipmentToBox() async {
    try {
      if (_playerEquipment != null) {
        await _equipmentBox.put('playerEquipment', _playerEquipment!.toJson());
      }
      if (_companion != null) {
        await _equipmentBox.put('companion', _companion!.toJson());
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'équipement: $e');
    }
  }

  Future<void> loadEquipment(String userId) async {
    _loadEquipmentFromBox();
  }

  Future<void> saveEquipment(String userId) async {
    await _saveEquipmentToBox();
  }

  /// Équipe un item au joueur
  Future<bool> equipItem(String userId, Item item) async {
    if (!item.isEquippable) {
      return false;
    }

    if (_playerEquipment == null) {
      _playerEquipment = PlayerEquipment();
    }

    switch (item.type) {
      case ItemType.weapon:
        _playerEquipment = _playerEquipment!.copyWith(weaponId: item.id);
        break;
      case ItemType.armor:
        _playerEquipment = _playerEquipment!.copyWith(armorId: item.id);
        break;
      case ItemType.helmet:
        _playerEquipment = _playerEquipment!.copyWith(helmetId: item.id);
        break;
      case ItemType.shield:
        _playerEquipment = _playerEquipment!.copyWith(shieldId: item.id);
        break;
      case ItemType.cosmetic:
        // Déterminer si c'est une tenue ou une aura selon les métadonnées
        final isOutfit = item.metadata?['subtype'] == 'outfit';
        if (isOutfit) {
          _playerEquipment = _playerEquipment!.copyWith(outfitId: item.id);
        } else {
          _playerEquipment = _playerEquipment!.copyWith(auraId: item.id);
        }
        break;
      default:
        return false;
    }

    notifyListeners();
    await saveEquipment(userId);
    return true;
  }

  /// Déséquipe un item du joueur
  Future<bool> unequipItem(String userId, ItemType type) async {
    if (_playerEquipment == null) {
      return false;
    }

    switch (type) {
      case ItemType.weapon:
        _playerEquipment = _playerEquipment!.copyWith(weaponId: null);
        break;
      case ItemType.armor:
        _playerEquipment = _playerEquipment!.copyWith(armorId: null);
        break;
      case ItemType.helmet:
        _playerEquipment = _playerEquipment!.copyWith(helmetId: null);
        break;
      case ItemType.shield:
        _playerEquipment = _playerEquipment!.copyWith(shieldId: null);
        break;
      case ItemType.cosmetic:
        // Déséquiper tenue et aura
        _playerEquipment = _playerEquipment!.copyWith(
          outfitId: null,
          auraId: null,
        );
        break;
      default:
        return false;
    }

    notifyListeners();
    await saveEquipment(userId);
    return true;
  }

  /// Obtient l'item équipé d'un type donné
  String? getEquippedItemId(ItemType type) {
    if (_playerEquipment == null) {
      return null;
    }

    switch (type) {
      case ItemType.weapon:
        return _playerEquipment!.weaponId;
      case ItemType.armor:
        return _playerEquipment!.armorId;
      case ItemType.helmet:
        return _playerEquipment!.helmetId;
      case ItemType.shield:
        return _playerEquipment!.shieldId;
      case ItemType.cosmetic:
        return _playerEquipment!.outfitId ?? _playerEquipment!.auraId;
      default:
        return null;
    }
  }

  /// Équipe une tenue au compagnon
  Future<bool> equipCompanionOutfit(String userId, Item item) async {
    if (item.type != ItemType.cosmetic || _companion == null) {
      return false;
    }

    _companion = _companion!.copyWith(equippedOutfitId: item.id);
    notifyListeners();
    await saveEquipment(userId);
    return true;
  }

  /// Définit ou crée un compagnon
  Future<void> setCompanion(String userId, Companion companion) async {
    _companion = companion;
    notifyListeners();
    await saveEquipment(userId);
  }

  /// Calcule les bonus totaux de l'équipement du joueur
  Map<String, int> calculatePlayerBonuses(Map<String, Item> items) {
    if (_playerEquipment == null) {
      return {'attack': 0, 'defense': 0, 'health': 0};
    }
    return _playerEquipment!.calculateBonuses(items);
  }
}


