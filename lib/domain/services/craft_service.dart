import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/craft_recipe_model.dart';
import '../../data/models/item_model.dart';
import '../../data/models/quest_model.dart';

/// Service de forge — catalogue de recettes et logique d'exécution.
class CraftService {
  static const _uuid = Uuid();

  // ── Catalogue de recettes ───────────────────────────────────────────────────

  static final List<CraftRecipe> recipes = [
    // ── Matériaux ────────────────────────────────────────────────────────────
    CraftRecipe(
      id: 'fragment_to_crystal',
      name: 'Cristal Brut',
      description: '3 fragments de pierre fusionnés en un cristal brut.',
      icon: '💎',
      ingredients: const [
        CraftIngredient(itemName: 'Fragment de Pierre', quantity: 3),
      ],
      result: _makeMaterial(
        name: 'Cristal Brut',
        description: 'Un cristal qui peut être utilisé pour l\'invocation.',
        rarity: QuestRarity.rare,
        iconCodePoint: Icons.diamond_outlined.codePoint,
        goldValue: 50,
        assetPath: 'assets/items/material_crystal.svg',
      ),
    ),

    CraftRecipe(
      id: 'crystal_to_essence',
      name: 'Essence Mythique',
      description: '3 cristaux bruts distillés en une essence pure.',
      icon: '✨',
      goldCost: 100,
      ingredients: const [
        CraftIngredient(itemName: 'Cristal Brut', quantity: 3),
      ],
      result: _makeMaterial(
        name: 'Essence Mythique',
        description: 'Une essence concentrée de puissance mythique.',
        rarity: QuestRarity.mythic,
        iconCodePoint: Icons.flare.codePoint,
        goldValue: 500,
        assetPath: 'assets/items/material_essence.svg',
      ),
    ),

    // ── Consommables ─────────────────────────────────────────────────────────
    CraftRecipe(
      id: 'crystal_to_potion',
      name: 'Potion de Soin',
      description: 'Combine 2 cristaux pour obtenir une potion de soin.',
      icon: '🧪',
      ingredients: const [
        CraftIngredient(itemName: 'Cristal Brut', quantity: 2),
      ],
      result: _makePotion(
        name: 'Potion de Soin',
        description: 'Restaure 30% des PV au moment de l\'utilisation.',
        rarity: QuestRarity.uncommon,
        iconCodePoint: Icons.healing.codePoint,
        goldValue: 80,
        hpBonus: 30,
      ),
    ),

    CraftRecipe(
      id: 'essence_to_potion_supreme',
      name: 'Potion de Soin Suprême',
      description: 'Une essence mythique transformée en soin puissant.',
      icon: '⚗️',
      ingredients: const [
        CraftIngredient(itemName: 'Essence Mythique', quantity: 1),
        CraftIngredient(itemName: 'Cristal Brut', quantity: 1),
      ],
      result: _makePotion(
        name: 'Potion de Soin Suprême',
        description: 'Restaure la totalité des PV.',
        rarity: QuestRarity.legendary,
        iconCodePoint: Icons.local_hospital.codePoint,
        goldValue: 300,
        hpBonus: 100,
      ),
    ),

    // ── Équipements ──────────────────────────────────────────────────────────
    CraftRecipe(
      id: 'essence_to_ring',
      name: 'Anneau de l\'Aventurier',
      description: 'Forge un anneau légendaire depuis une essence mythique.',
      icon: '💍',
      goldCost: 200,
      ingredients: const [
        CraftIngredient(itemName: 'Essence Mythique', quantity: 1),
        CraftIngredient(itemName: 'Cristal Brut', quantity: 2),
      ],
      result: _makeEquipment(
        name: 'Anneau de l\'Aventurier',
        description: 'Un anneau forgé dans l\'essence même de l\'aventure.',
        type: ItemType.ring,
        rarity: QuestRarity.legendary,
        iconCodePoint: Icons.circle_outlined.codePoint,
        goldValue: 600,
        xpBonus: 10,
        goldBonus: 5,
      ),
    ),

    CraftRecipe(
      id: 'fragments_to_helmet',
      name: 'Casque de l\'Apprenti',
      description: 'Assemble 5 fragments en un casque solide.',
      icon: '🪖',
      ingredients: const [
        CraftIngredient(itemName: 'Fragment de Pierre', quantity: 5),
      ],
      result: _makeEquipment(
        name: 'Casque de l\'Apprenti',
        description: 'Un casque robuste pour les aventuriers débutants.',
        type: ItemType.helmet,
        rarity: QuestRarity.uncommon,
        iconCodePoint: Icons.shield_outlined.codePoint,
        goldValue: 120,
        hpBonus: 15,
      ),
    ),

    // ── Consommables avancés ─────────────────────────────────────────────────
    CraftRecipe(
      id: 'fragments_crystal_to_moral',
      name: 'Élixir de Moral',
      description: 'Mélange de fragments et de cristal pour redonner le moral.',
      icon: '🌿',
      ingredients: const [
        CraftIngredient(itemName: 'Fragment de Pierre', quantity: 2),
        CraftIngredient(itemName: 'Cristal Brut', quantity: 1),
      ],
      result: _makePotion(
        name: 'Élixir de Moral',
        description: 'Restaure 25 points de moral immédiatement.',
        rarity: QuestRarity.uncommon,
        iconCodePoint: Icons.sentiment_satisfied_alt_outlined.codePoint,
        goldValue: 60,
        moralBonus: 25,
      ),
    ),

    CraftRecipe(
      id: 'essence_to_xp_scroll',
      name: 'Parchemin d\'Expérience',
      description: 'Transforme une essence en parchemin d\'XP pur.',
      icon: '📜',
      goldCost: 150,
      ingredients: const [
        CraftIngredient(itemName: 'Essence Mythique', quantity: 1),
      ],
      result: _makePotion(
        name: 'Parchemin d\'Expérience',
        description: 'Accorde immédiatement 500 XP au joueur.',
        rarity: QuestRarity.epic,
        iconCodePoint: Icons.auto_stories_outlined.codePoint,
        goldValue: 400,
        xpBonus: 500,
      ),
    ),

    // ── Équipements avancés ──────────────────────────────────────────────────
    CraftRecipe(
      id: 'crystals_to_amulet',
      name: 'Amulette du Marchand',
      description: 'Trois cristaux forgés en une amulette qui attire l\'or.',
      icon: '📿',
      goldCost: 100,
      ingredients: const [
        CraftIngredient(itemName: 'Cristal Brut', quantity: 3),
      ],
      result: _makeEquipment(
        name: 'Amulette du Marchand',
        description: 'Augmente le gain d\'or de toutes les quêtes.',
        type: ItemType.ring,
        rarity: QuestRarity.rare,
        iconCodePoint: Icons.monetization_on_outlined.codePoint,
        goldValue: 350,
        goldBonus: 8,
      ),
    ),

    CraftRecipe(
      id: 'essence_fragments_to_breastplate',
      name: 'Plastron de Fer',
      description: 'Forge une armure résistante depuis fragments et essence.',
      icon: '🛡️',
      goldCost: 250,
      ingredients: const [
        CraftIngredient(itemName: 'Fragment de Pierre', quantity: 4),
        CraftIngredient(itemName: 'Essence Mythique', quantity: 1),
      ],
      result: _makeEquipment(
        name: 'Plastron de Fer',
        description: 'Une armure solide offrant protection et endurance.',
        type: ItemType.armor,
        rarity: QuestRarity.epic,
        iconCodePoint: Icons.security_outlined.codePoint,
        goldValue: 500,
        hpBonus: 30,
        moralBonus: 10,
      ),
    ),

    CraftRecipe(
      id: 'crystals_to_xp_ring',
      name: 'Anneau du Sage',
      description: 'Deux cristaux et de l\'or pour un anneau qui amplifie l\'XP.',
      icon: '🔮',
      goldCost: 120,
      ingredients: const [
        CraftIngredient(itemName: 'Cristal Brut', quantity: 2),
        CraftIngredient(itemName: 'Fragment de Pierre', quantity: 3),
      ],
      result: _makeEquipment(
        name: 'Anneau du Sage',
        description: 'Les quêtes rapportent plus d\'expérience.',
        type: ItemType.ring,
        rarity: QuestRarity.rare,
        iconCodePoint: Icons.school_outlined.codePoint,
        goldValue: 280,
        xpBonus: 12,
      ),
    ),
  ];

  // ── Helpers de création d'items ─────────────────────────────────────────────

  static Item _makeMaterial({
    required String name,
    required String description,
    required QuestRarity rarity,
    required int iconCodePoint,
    required int goldValue,
    String? assetPath,
  }) =>
      Item(
        id: 'recipe_template',
        name: name,
        description: description,
        type: ItemType.material,
        rarity: rarity,
        iconCodePoint: iconCodePoint,
        stats: const {},
        goldValue: goldValue,
        stackable: true,
        assetPath: assetPath,
      );

  static Item _makePotion({
    required String name,
    required String description,
    required QuestRarity rarity,
    required int iconCodePoint,
    required int goldValue,
    int hpBonus = 0,
    int moralBonus = 0,
    int xpBonus = 0,
  }) =>
      Item(
        id: 'recipe_template',
        name: name,
        description: description,
        type: ItemType.potion,
        rarity: rarity,
        iconCodePoint: iconCodePoint,
        stats: {
          if (hpBonus > 0) 'hpBonus': hpBonus,
          if (moralBonus > 0) 'moralBonus': moralBonus,
          if (xpBonus > 0) 'xpBonus': xpBonus,
        },
        goldValue: goldValue,
      );

  static Item _makeEquipment({
    required String name,
    required String description,
    required ItemType type,
    required QuestRarity rarity,
    required int iconCodePoint,
    required int goldValue,
    int xpBonus = 0,
    int goldBonus = 0,
    int hpBonus = 0,
    int moralBonus = 0,
  }) =>
      Item(
        id: 'recipe_template',
        name: name,
        description: description,
        type: type,
        rarity: rarity,
        iconCodePoint: iconCodePoint,
        stats: {
          if (xpBonus > 0) 'xpBonusPercent': xpBonus,
          if (goldBonus > 0) 'goldBonusPercent': goldBonus,
          if (hpBonus > 0) 'hpBonus': hpBonus,
          if (moralBonus > 0) 'moralBonus': moralBonus,
        },
        goldValue: goldValue,
      );

  // ── Logique métier ──────────────────────────────────────────────────────────

  /// Vérifie si le joueur peut forger cette recette.
  static bool canCraft(CraftRecipe recipe, List<Item> inventory, int gold) {
    if (gold < recipe.goldCost) return false;
    for (final ingredient in recipe.ingredients) {
      final total = inventory
          .where((i) => i.name == ingredient.itemName)
          .fold<int>(0, (sum, i) => sum + i.quantity);
      if (total < ingredient.quantity) return false;
    }
    return true;
  }

  /// Retourne la quantité disponible d'un ingrédient dans l'inventaire.
  static int availableCount(String itemName, List<Item> inventory) =>
      inventory
          .where((i) => i.name == itemName)
          .fold<int>(0, (sum, i) => sum + i.quantity);

  /// Crée l'item résultat avec un UUID frais.
  static Item craftResult(CraftRecipe recipe) => Item(
        id: _uuid.v4(),
        name: recipe.result.name,
        description: recipe.result.description,
        type: recipe.result.type,
        rarity: recipe.result.rarity,
        iconCodePoint: recipe.result.iconCodePoint,
        stats: recipe.result.stats,
        goldValue: recipe.result.goldValue,
        stackable: recipe.result.stackable,
        cosmeticSlot: recipe.result.cosmeticSlot,
        assetPath: recipe.result.assetPath,
      );

  /// Retire les ingrédients nécessaires de l'inventaire (mutera les IDs).
  /// Retourne la liste des paires (itemId, quantité à retirer) à passer à
  /// `InventoryViewModel.removeItem`.
  static List<({String id, int qty})> ingredientsToRemove(
      CraftRecipe recipe, List<Item> inventory) {
    final result = <({String id, int qty})>[];
    for (final ingredient in recipe.ingredients) {
      var remaining = ingredient.quantity;
      for (final item in inventory.where((i) => i.name == ingredient.itemName)) {
        if (remaining <= 0) break;
        final toTake = remaining < item.quantity ? remaining : item.quantity;
        result.add((id: item.id, qty: toTake));
        remaining -= toTake;
      }
    }
    return result;
  }
}
