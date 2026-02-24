import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/item_model.dart';
import '../../data/models/quest_model.dart';

/// Fabrique d'items : catalogue prédéfini, gacha et marché.
class ItemFactory {
  static final _uuid = Uuid();
  static final _random = Random();

  // Non-const pour pouvoir utiliser Icons.xxx.codePoint
  static final List<Map<String, dynamic>> _catalog = [
    // --- ARMES ---
    {
      'name': 'Épée Rouyée',
      'description': 'Une vieille épée qui accorde un petit bonus d\'XP.',
      'type': ItemType.weapon,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.sports_kabaddi.codePoint,
      'stats': {'xpBonus': 5},
      'goldValue': 50,
    },
    {
      'name': 'Lame du Chasseur',
      'description': 'Une lame fine qui augmente notablement l\'XP gagné.',
      'type': ItemType.weapon,
      'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.auto_fix_high.codePoint,
      'stats': {'xpBonus': 15},
      'goldValue': 150,
    },
    {
      'name': 'Épée Légendaire',
      'description': 'Forgée par un maître, elle double presque votre XP.',
      'type': ItemType.weapon,
      'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.bolt.codePoint,
      'stats': {'xpBonus': 30},
      'goldValue': 500,
    },
    // --- ARMURES ---
    {
      'name': 'Tunique de Lin',
      'description': 'Protection de base qui renforce légèrement les HP.',
      'type': ItemType.armor,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.shield_outlined.codePoint,
      'stats': {'hpBonus': 10},
      'goldValue': 40,
    },
    {
      'name': 'Cotte de Mailles',
      'description': 'Armure solide offrant une bonne protection.',
      'type': ItemType.armor,
      'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.security.codePoint,
      'stats': {'hpBonus': 25},
      'goldValue': 200,
    },
    {
      'name': 'Armure Épique',
      'description': 'Protection épique pour les grands aventuriers.',
      'type': ItemType.armor,
      'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.verified_user.codePoint,
      'stats': {'hpBonus': 50},
      'goldValue': 400,
    },
    // --- CASQUES ---
    {
      'name': 'Chapeau de Voyage',
      'description': 'Un chapeau simple qui améliore votre moral.',
      'type': ItemType.helmet,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.face.codePoint,
      'stats': {'moralBonus': 5},
      'goldValue': 30,
    },
    {
      'name': 'Heaume du Sage',
      'description': 'Un casque qui augmente l\'XP gagné.',
      'type': ItemType.helmet,
      'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.psychology.codePoint,
      'stats': {'xpBonus': 10},
      'goldValue': 180,
    },
    // --- BOTTES ---
    {
      'name': 'Bottes Usées',
      'description': 'De vieilles bottes qui donnent un bonus d\'or.',
      'type': ItemType.boots,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.directions_walk.codePoint,
      'stats': {'goldBonus': 5},
      'goldValue': 35,
    },
    {
      'name': 'Bottes de Mercenaire',
      'description': 'Bottes robustes augmentant significativement l\'or récolté.',
      'type': ItemType.boots,
      'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.hiking.codePoint,
      'stats': {'goldBonus': 15},
      'goldValue': 140,
    },
    // --- ANNEAUX ---
    {
      'name': 'Anneau de Bronze',
      'description': 'Un simple anneau offrant un petit bonus de moral.',
      'type': ItemType.ring,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.circle_outlined.codePoint,
      'stats': {'moralBonus': 3},
      'goldValue': 25,
    },
    {
      'name': 'Anneau Mystique',
      'description': 'Un anneau enchanté qui booste à la fois XP et or.',
      'type': ItemType.ring,
      'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.radio_button_checked.codePoint,
      'stats': {'xpBonus': 8, 'goldBonus': 8},
      'goldValue': 350,
    },
    // --- POTIONS ---
    {
      'name': 'Potion de Soin',
      'description': 'Restaure 20 HP instantanément.',
      'type': ItemType.potion,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.local_pharmacy.codePoint,
      'stats': {'hpBonus': 20},
      'goldValue': 30,
      'stackable': true,
    },
    {
      'name': 'Élixir de Force',
      'description': 'Booste l\'XP de la prochaine quête de 25%.',
      'type': ItemType.potion,
      'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.science.codePoint,
      'stats': {'xpBonus': 25},
      'goldValue': 80,
      'stackable': true,
    },
    {
      'name': 'Philtre d\'Or',
      'description': 'Double l\'or de la prochaine quête.',
      'type': ItemType.potion,
      'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.water_drop.codePoint,
      'stats': {'goldBonus': 50},
      'goldValue': 120,
      'stackable': true,
    },
    // --- MATÉRIAUX ---
    {
      'name': 'Fragment de Pierre',
      'description': 'Un fragment mystérieux à collectionner.',
      'type': ItemType.material,
      'rarity': QuestRarity.common,
      'iconCodePoint': Icons.texture.codePoint,
      'stats': {},
      'goldValue': 10,
      'stackable': true,
    },
    {
      'name': 'Cristal Brut',
      'description': 'Un cristal qui peut être utilisé pour l\'invocation.',
      'type': ItemType.material,
      'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.diamond_outlined.codePoint,
      'stats': {},
      'goldValue': 50,
      'stackable': true,
    },
    {
      'name': 'Essence Mythique',
      'description': 'Une essence rarissime aux propriétés inconnues.',
      'type': ItemType.material,
      'rarity': QuestRarity.mythic,
      'iconCodePoint': Icons.flare.codePoint,
      'stats': {},
      'goldValue': 500,
      'stackable': true,
    },
  ];

  /// Lance les dés et retourne une rareté selon les probabilités gacha.
  static QuestRarity rollGachaRarity() {
    final roll = _random.nextDouble() * 100;
    if (roll < 0.1) return QuestRarity.mythic;
    if (roll < 1.0) return QuestRarity.legendary;
    if (roll < 5.0) return QuestRarity.epic;
    if (roll < 15.0) return QuestRarity.rare;
    if (roll < 40.0) return QuestRarity.uncommon;
    return QuestRarity.common;
  }

  /// Génère un item aléatoire de la rareté donnée.
  static Item generateRandomItem(QuestRarity rarity) {
    final matching =
        _catalog.where((c) => c['rarity'] == rarity).toList();

    final template = matching.isNotEmpty
        ? matching[_random.nextInt(matching.length)]
        : _catalog.first;

    return Item(
      id: _uuid.v4(),
      name: template['name'] as String,
      description: template['description'] as String,
      type: template['type'] as ItemType,
      rarity: rarity,
      iconCodePoint: template['iconCodePoint'] as int,
      stats: Map<String, int>.from((template['stats'] as Map?) ?? {}),
      quantity: 1,
      stackable: template['stackable'] as bool? ?? false,
      goldValue: template['goldValue'] as int,
    );
  }

  /// Retourne le catalogue achetable en boutique.
  static List<Item> getMarketCatalog() {
    return _catalog
        .where((c) =>
            c['type'] != ItemType.material)
        .map((c) => Item(
              id: 'market_${c['name']}',
              name: c['name'] as String,
              description: c['description'] as String,
              type: c['type'] as ItemType,
              rarity: c['rarity'] as QuestRarity,
              iconCodePoint: c['iconCodePoint'] as int,
              stats: Map<String, int>.from((c['stats'] as Map?) ?? {}),
              quantity: 1,
              stackable: c['stackable'] as bool? ?? false,
              goldValue: c['goldValue'] as int,
            ))
        .toList();
  }
}
