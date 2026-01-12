import 'package:uuid/uuid.dart';
import 'item.dart';

/// Classe représentant l'équipement actuel du joueur
class PlayerEquipment {
  final String? weaponId; // ID de l'arme équipée
  final String? armorId; // ID de l'armure équipée
  final String? helmetId; // ID du casque équipé
  final String? shieldId; // ID du bouclier équipé
  final String? outfitId; // ID de la tenue équipée (cosmétique)
  final String? auraId; // ID de l'aura équipée (cosmétique)

  PlayerEquipment({
    this.weaponId,
    this.armorId,
    this.helmetId,
    this.shieldId,
    this.outfitId,
    this.auraId,
  });

  Map<String, dynamic> toJson() => {
        'weaponId': weaponId,
        'armorId': armorId,
        'helmetId': helmetId,
        'shieldId': shieldId,
        'outfitId': outfitId,
        'auraId': auraId,
      };

  factory PlayerEquipment.fromJson(Map<String, dynamic> json) =>
      PlayerEquipment(
        weaponId: json['weaponId'] as String?,
        armorId: json['armorId'] as String?,
        helmetId: json['helmetId'] as String?,
        shieldId: json['shieldId'] as String?,
        outfitId: json['outfitId'] as String?,
        auraId: json['auraId'] as String?,
      );

  PlayerEquipment copyWith({
    String? weaponId,
    String? armorId,
    String? helmetId,
    String? shieldId,
    String? outfitId,
    String? auraId,
  }) =>
      PlayerEquipment(
        weaponId: weaponId ?? this.weaponId,
        armorId: armorId ?? this.armorId,
        helmetId: helmetId ?? this.helmetId,
        shieldId: shieldId ?? this.shieldId,
        outfitId: outfitId ?? this.outfitId,
        auraId: auraId ?? this.auraId,
      );

  /// Calcule les bonus totaux de l'équipement
  Map<String, int> calculateBonuses(Map<String, Item> items) {
    int attack = 0;
    int defense = 0;
    int health = 0;

    if (weaponId != null && items.containsKey(weaponId)) {
      attack += items[weaponId]!.attackBonus ?? 0;
    }
    if (armorId != null && items.containsKey(armorId)) {
      defense += items[armorId]!.defenseBonus ?? 0;
      health += items[armorId]!.healthBonus ?? 0;
    }
    if (helmetId != null && items.containsKey(helmetId)) {
      defense += items[helmetId]!.defenseBonus ?? 0;
      health += items[helmetId]!.healthBonus ?? 0;
    }
    if (shieldId != null && items.containsKey(shieldId)) {
      defense += items[shieldId]!.defenseBonus ?? 0;
    }

    return {
      'attack': attack,
      'defense': defense,
      'health': health,
    };
  }
}

/// Classe représentant un compagnon
class Companion {
  final String id;
  final String name;
  final String description;
  final String? imagePath;
  final int level;
  final int experience;
  final int healthPoints;
  final int maxHealthPoints;
  final String? equippedOutfitId; // Tenue équipée sur le compagnon
  final Map<String, dynamic>? metadata;

  Companion({
    String? id,
    required this.name,
    required this.description,
    this.imagePath,
    this.level = 1,
    this.experience = 0,
    this.healthPoints = 100,
    this.maxHealthPoints = 100,
    this.equippedOutfitId,
    this.metadata,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'level': level,
        'experience': experience,
        'healthPoints': healthPoints,
        'maxHealthPoints': maxHealthPoints,
        'equippedOutfitId': equippedOutfitId,
        'metadata': metadata,
      };

  factory Companion.fromJson(Map<String, dynamic> json) => Companion(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imagePath: json['imagePath'] as String?,
        level: json['level'] as int? ?? 1,
        experience: json['experience'] as int? ?? 0,
        healthPoints: json['healthPoints'] as int? ?? 100,
        maxHealthPoints: json['maxHealthPoints'] as int? ?? 100,
        equippedOutfitId: json['equippedOutfitId'] as String?,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  Companion copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    int? level,
    int? experience,
    int? healthPoints,
    int? maxHealthPoints,
    String? equippedOutfitId,
    Map<String, dynamic>? metadata,
  }) =>
      Companion(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        imagePath: imagePath ?? this.imagePath,
        level: level ?? this.level,
        experience: experience ?? this.experience,
        healthPoints: healthPoints ?? this.healthPoints,
        maxHealthPoints: maxHealthPoints ?? this.maxHealthPoints,
        equippedOutfitId: equippedOutfitId ?? this.equippedOutfitId,
        metadata: metadata ?? this.metadata,
      );
}

