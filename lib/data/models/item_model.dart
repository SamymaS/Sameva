import 'package:flutter/material.dart';
import 'quest_model.dart';

enum ItemType { weapon, armor, helmet, boots, ring, potion, material, cosmetic }

enum EquipmentSlot { weapon, armor, helmet, boots, ring }

class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final QuestRarity rarity;
  final int iconCodePoint;
  final Map<String, int> stats; // xpBonus, goldBonus, hpBonus, moralBonus, colorValue, styleIndex
  final int quantity;
  final bool stackable;
  final int goldValue;
  /// Prix en cristaux (0 = non disponible en boutique premium).
  final int crystalValue;
  final String? cosmeticSlot; // 'hat' | 'outfit' | 'pants' | 'shoes' | 'aura'

  /// Chemin vers l'asset SVG pixel art (ex: 'assets/items/sword_rusty.svg').
  /// Null = fallback sur [iconCodePoint] (Material Icons).
  final String? assetPath;

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
    this.crystalValue = 0,
    this.cosmeticSlot,
    this.assetPath,
  });

  IconData getIcon() => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// Retourne le slot d'équipement pour cet item, null si non équipable.
  static EquipmentSlot? slotForItem(Item item) {
    return switch (item.type) {
      ItemType.weapon => EquipmentSlot.weapon,
      ItemType.armor  => EquipmentSlot.armor,
      ItemType.helmet => EquipmentSlot.helmet,
      ItemType.boots  => EquipmentSlot.boots,
      ItemType.ring   => EquipmentSlot.ring,
      ItemType.potion || ItemType.material || ItemType.cosmetic => null,
    };
  }

  /// Retourne le slot cosmétique pour cet item, null si non cosmétique.
  static String? cosmeticSlotForItem(Item item) => item.cosmeticSlot;

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
        if (crystalValue > 0) 'crystalValue': crystalValue,
        if (cosmeticSlot != null) 'cosmeticSlot': cosmeticSlot,
        if (assetPath != null) 'assetPath': assetPath,
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
        crystalValue: json['crystalValue'] as int? ?? 0,
        cosmeticSlot: json['cosmeticSlot'] as String?,
        assetPath: json['assetPath'] as String?,
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
    int? crystalValue,
    String? cosmeticSlot,
    String? assetPath,
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
        crystalValue: crystalValue ?? this.crystalValue,
        cosmeticSlot: cosmeticSlot ?? this.cosmeticSlot,
        assetPath: assetPath ?? this.assetPath,
      );
}
