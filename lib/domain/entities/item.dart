import 'package:uuid/uuid.dart';

/// Type d'item
enum ItemType {
  weapon, // Arme
  armor, // Armure
  helmet, // Casque
  shield, // Bouclier
  potion, // Potion
  consumable, // Consommable
  cosmetic, // Cosmétique (tenue, aura)
  companion, // Compagnon
  material, // Matériau
}

/// Rareté de l'item
enum ItemRarity {
  common,
  uncommon,
  rare,
  veryRare,
  epic,
  legendary,
  mythic
}

/// Classe représentant un item dans l'inventaire
class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final String? imagePath; // Chemin vers l'image de l'item
  final int? attackBonus; // Bonus d'attaque (pour armes)
  final int? defenseBonus; // Bonus de défense (pour armures)
  final int? healthBonus; // Bonus de PV (pour potions/armures)
  final int? experienceBonus; // Bonus d'XP (pour potions)
  final int? goldBonus; // Bonus d'or (pour potions)
  final int value; // Valeur de l'item (pour vente/achat)
  final bool isEquippable; // Peut être équipé
  final bool isConsumable; // Peut être consommé
  final int stackSize; // Taille de pile (pour items consommables)
  final Map<String, dynamic>? metadata; // Métadonnées supplémentaires

  Item({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    this.imagePath,
    this.attackBonus,
    this.defenseBonus,
    this.healthBonus,
    this.experienceBonus,
    this.goldBonus,
    required this.value,
    this.isEquippable = false,
    this.isConsumable = false,
    this.stackSize = 1,
    this.metadata,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.toString(),
        'rarity': rarity.toString(),
        'imagePath': imagePath,
        'attackBonus': attackBonus,
        'defenseBonus': defenseBonus,
        'healthBonus': healthBonus,
        'experienceBonus': experienceBonus,
        'goldBonus': goldBonus,
        'value': value,
        'isEquippable': isEquippable,
        'isConsumable': isConsumable,
        'stackSize': stackSize,
        'metadata': metadata,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ItemType.values.firstWhere(
          (e) => e.toString() == json['type'],
        ),
        rarity: ItemRarity.values.firstWhere(
          (e) => e.toString() == json['rarity'],
        ),
        imagePath: json['imagePath'] as String?,
        attackBonus: json['attackBonus'] as int?,
        defenseBonus: json['defenseBonus'] as int?,
        healthBonus: json['healthBonus'] as int?,
        experienceBonus: json['experienceBonus'] as int?,
        goldBonus: json['goldBonus'] as int?,
        value: json['value'] as int,
        isEquippable: json['isEquippable'] as bool? ?? false,
        isConsumable: json['isConsumable'] as bool? ?? false,
        stackSize: json['stackSize'] as int? ?? 1,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  Item copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? type,
    ItemRarity? rarity,
    String? imagePath,
    int? attackBonus,
    int? defenseBonus,
    int? healthBonus,
    int? experienceBonus,
    int? goldBonus,
    int? value,
    bool? isEquippable,
    bool? isConsumable,
    int? stackSize,
    Map<String, dynamic>? metadata,
  }) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        rarity: rarity ?? this.rarity,
        imagePath: imagePath ?? this.imagePath,
        attackBonus: attackBonus ?? this.attackBonus,
        defenseBonus: defenseBonus ?? this.defenseBonus,
        healthBonus: healthBonus ?? this.healthBonus,
        experienceBonus: experienceBonus ?? this.experienceBonus,
        goldBonus: goldBonus ?? this.goldBonus,
        value: value ?? this.value,
        isEquippable: isEquippable ?? this.isEquippable,
        isConsumable: isConsumable ?? this.isConsumable,
        stackSize: stackSize ?? this.stackSize,
        metadata: metadata ?? this.metadata,
      );
}

/// Classe représentant un slot d'inventaire (item + quantité)
class InventorySlot {
  final Item item;
  final int quantity;

  InventorySlot({
    required this.item,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'quantity': quantity,
      };

  factory InventorySlot.fromJson(Map<String, dynamic> json) => InventorySlot(
        item: Item.fromJson(json['item'] as Map<String, dynamic>),
        quantity: json['quantity'] as int? ?? 1,
      );

  InventorySlot copyWith({
    Item? item,
    int? quantity,
  }) =>
      InventorySlot(
        item: item ?? this.item,
        quantity: quantity ?? this.quantity,
      );
}







