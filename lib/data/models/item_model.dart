import 'package:flutter/material.dart';
import 'quest_model.dart';

enum ItemType { weapon, armor, helmet, boots, ring, potion, material }

enum EquipmentSlot { weapon, armor, helmet, boots, ring }

class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final QuestRarity rarity;
  final int iconCodePoint;
  final Map<String, int> stats; // xpBonus, goldBonus, hpBonus, moralBonus
  final int quantity;
  final bool stackable;
  final int goldValue;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.iconCodePoint,
    this.stats = const {},
    this.quantity = 1,
    this.stackable = false,
    required this.goldValue,
  });

  IconData getIcon() => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// Retourne le slot d'équipement pour cet item, null si non équipable.
  static EquipmentSlot? slotForItem(Item item) {
    return switch (item.type) {
      ItemType.weapon => EquipmentSlot.weapon,
      ItemType.armor => EquipmentSlot.armor,
      ItemType.helmet => EquipmentSlot.helmet,
      ItemType.boots => EquipmentSlot.boots,
      ItemType.ring => EquipmentSlot.ring,
      ItemType.potion || ItemType.material => null,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'rarity': rarity.name,
        'iconCodePoint': iconCodePoint,
        'stats': stats,
        'quantity': quantity,
        'stackable': stackable,
        'goldValue': goldValue,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ItemType.values.byName(json['type'] as String),
        rarity: QuestRarity.fromSupabaseString(json['rarity'] as String),
        iconCodePoint: json['iconCodePoint'] as int,
        stats: json['stats'] != null
            ? Map<String, int>.from(json['stats'] as Map)
            : {},
        quantity: json['quantity'] as int? ?? 1,
        stackable: json['stackable'] as bool? ?? false,
        goldValue: json['goldValue'] as int? ?? 0,
      );

  Item copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? type,
    QuestRarity? rarity,
    int? iconCodePoint,
    Map<String, int>? stats,
    int? quantity,
    bool? stackable,
    int? goldValue,
  }) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        rarity: rarity ?? this.rarity,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        stats: stats ?? this.stats,
        quantity: quantity ?? this.quantity,
        stackable: stackable ?? this.stackable,
        goldValue: goldValue ?? this.goldValue,
      );
}
