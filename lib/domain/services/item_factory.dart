import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/item_model.dart';
import '../../data/models/quest_model.dart';

/// Fabrique d'items : catalogue prédéfini, gacha et marché.
class ItemFactory {
  static const _uuid = Uuid();
  static final _random = Random();

  // Non-const pour pouvoir utiliser Icons.xxx.codePoint
  static final List<Map<String, dynamic>> _catalog = [
    // ── ARMES ──────────────────────────────────────────────────────────────────
    {
      'name': 'Épée Rouillée',
      'description': 'Une vieille épée qui accorde un petit bonus d\'XP.',
      'type': ItemType.weapon, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.sports_kabaddi.codePoint,
      'stats': {'xpBonus': 5}, 'goldValue': 50,
      'assetPath': 'assets/items/sword_rusty.svg',
    },
    {
      'name': 'Lame du Chasseur',
      'description': 'Une lame fine qui augmente notablement l\'XP gagné.',
      'type': ItemType.weapon, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.auto_fix_high.codePoint,
      'stats': {'xpBonus': 15}, 'goldValue': 150,
      'assetPath': 'assets/items/sword_hunter.svg',
    },
    {
      'name': 'Épée Légendaire',
      'description': 'Forgée par un maître, elle double presque votre XP.',
      'type': ItemType.weapon, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.bolt.codePoint,
      'stats': {'xpBonus': 30}, 'goldValue': 500,
      'assetPath': 'assets/items/sword_legendary.svg',
    },
    // ── ARMURES ────────────────────────────────────────────────────────────────
    {
      'name': 'Tunique de Lin',
      'description': 'Protection de base qui renforce légèrement les HP.',
      'type': ItemType.armor, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.shield_outlined.codePoint,
      'stats': {'hpBonus': 10}, 'goldValue': 40,
      'assetPath': 'assets/items/armor_tunic.svg',
    },
    {
      'name': 'Cotte de Mailles',
      'description': 'Armure solide offrant une bonne protection.',
      'type': ItemType.armor, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.security.codePoint,
      'stats': {'hpBonus': 25}, 'goldValue': 200,
      'assetPath': 'assets/items/armor_mail.svg',
    },
    {
      'name': 'Armure Épique',
      'description': 'Protection épique pour les grands aventuriers.',
      'type': ItemType.armor, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.verified_user.codePoint,
      'stats': {'hpBonus': 50}, 'goldValue': 400,
      'assetPath': 'assets/items/armor_epic.svg',
    },
    // ── CASQUES ────────────────────────────────────────────────────────────────
    {
      'name': 'Chapeau de Voyage',
      'description': 'Un chapeau simple qui améliore votre moral.',
      'type': ItemType.helmet, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.face.codePoint,
      'stats': {'moralBonus': 5}, 'goldValue': 30,
      'assetPath': 'assets/items/helmet_hat.svg',
    },
    {
      'name': 'Heaume du Sage',
      'description': 'Un casque qui augmente l\'XP gagné.',
      'type': ItemType.helmet, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.psychology.codePoint,
      'stats': {'xpBonus': 10}, 'goldValue': 180,
      'assetPath': 'assets/items/helmet_sage.svg',
    },
    // ── BOTTES ─────────────────────────────────────────────────────────────────
    {
      'name': 'Bottes Usées',
      'description': 'De vieilles bottes qui donnent un bonus d\'or.',
      'type': ItemType.boots, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.directions_walk.codePoint,
      'stats': {'goldBonus': 5}, 'goldValue': 35,
      'assetPath': 'assets/items/boots_worn.svg',
    },
    {
      'name': 'Bottes de Mercenaire',
      'description': 'Bottes robustes augmentant significativement l\'or récolté.',
      'type': ItemType.boots, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.hiking.codePoint,
      'stats': {'goldBonus': 15}, 'goldValue': 140,
      'assetPath': 'assets/items/boots_merc.svg',
    },
    // ── ANNEAUX ────────────────────────────────────────────────────────────────
    {
      'name': 'Anneau de Bronze',
      'description': 'Un simple anneau offrant un petit bonus de moral.',
      'type': ItemType.ring, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.circle_outlined.codePoint,
      'stats': {'moralBonus': 3}, 'goldValue': 25,
      'assetPath': 'assets/items/ring_bronze.svg',
    },
    {
      'name': 'Anneau Mystique',
      'description': 'Un anneau enchanté qui booste à la fois XP et or.',
      'type': ItemType.ring, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.radio_button_checked.codePoint,
      'stats': {'xpBonus': 8, 'goldBonus': 8}, 'goldValue': 350,
      'assetPath': 'assets/items/ring_mystic.svg',
    },
    // ── POTIONS ────────────────────────────────────────────────────────────────
    {
      'name': 'Potion de Soin',
      'description': 'Restaure 20 HP instantanément.',
      'type': ItemType.potion, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.local_pharmacy.codePoint,
      'stats': {'hpBonus': 20}, 'goldValue': 30, 'stackable': true,
      'assetPath': 'assets/items/potion_heal.svg',
    },
    {
      'name': 'Élixir de Force',
      'description': 'Booste l\'XP de la prochaine quête de 25%.',
      'type': ItemType.potion, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.science.codePoint,
      'stats': {'xpBonus': 25}, 'goldValue': 80, 'stackable': true,
      'assetPath': 'assets/items/potion_xp.svg',
    },
    {
      'name': 'Philtre d\'Or',
      'description': 'Double l\'or de la prochaine quête.',
      'type': ItemType.potion, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.water_drop.codePoint,
      'stats': {'goldBonus': 50}, 'goldValue': 120, 'stackable': true,
      'assetPath': 'assets/items/potion_gold.svg',
    },
    // ── COSMÉTIQUES — CHAPEAUX ─────────────────────────────────────────────────
    {
      'name': 'Chapeau Mystique',
      'description': 'Un chapeau conique aux reflets violets, symbole de sagesse.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.auto_awesome.codePoint,
      'stats': {'colorValue': 0xFF805AD5, 'styleIndex': 1}, 'goldValue': 200,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_cone_violet.svg',
    },
    {
      'name': 'Chapeau Azur',
      'description': 'Un chapeau conique couleur ciel, favori des mages aquatiques.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.auto_awesome.codePoint,
      'stats': {'colorValue': 0xFF4299E1, 'styleIndex': 1}, 'goldValue': 120,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_cone_blue.svg',
    },
    {
      'name': 'Couronne d\'Or',
      'description': 'Une couronne dorée digne des grands champions.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.workspace_premium.codePoint,
      'stats': {'colorValue': 0xFFF6E05E, 'styleIndex': 2}, 'goldValue': 500,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_crown_gold.svg',
    },
    {
      'name': 'Couronne de Cristal',
      'description': 'Une couronne translucide taillée dans un cristal pur.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.workspace_premium.codePoint,
      'stats': {'colorValue': 0xFF76E4F7, 'styleIndex': 2}, 'goldValue': 400,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_crown_cyan.svg',
    },
    {
      'name': 'Bonnet Rouge',
      'description': 'Un bonnet douillet rouge vif, parfait pour les aventures hivernales.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.snowboarding.codePoint,
      'stats': {'colorValue': 0xFFE53E3E, 'styleIndex': 3}, 'goldValue': 80,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_beanie_red.svg',
    },
    {
      'name': 'Bonnet Galactique',
      'description': 'Un bonnet aux reflets cosmiques qui scintillent dans la nuit.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.nightlight.codePoint,
      'stats': {'colorValue': 0xFF553C9A, 'styleIndex': 3}, 'goldValue': 380,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_beanie_violet.svg',
    },
    {
      'name': 'Bandana Turquoise',
      'description': 'Un bandana vif qui donne un air de guerrier des mers.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.flag.codePoint,
      'stats': {'colorValue': 0xFF4FD1C5, 'styleIndex': 4}, 'goldValue': 60,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_bandana_teal.svg',
    },
    {
      'name': 'Bandana de Feu',
      'description': 'Un bandana aux couleurs de la flamme pour les téméraires.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.local_fire_department.codePoint,
      'stats': {'colorValue': 0xFFED8936, 'styleIndex': 4}, 'goldValue': 220,
      'cosmeticSlot': 'hat', 'assetPath': 'assets/items/hat_bandana_orange.svg',
    },
    // ── COSMÉTIQUES — TENUES ───────────────────────────────────────────────────
    {
      'name': 'Robe d\'Azur',
      'description': 'Une robe turquoise aux reflets chatoyants.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.dry_cleaning.codePoint,
      'stats': {'colorValue': 0xFF4FD1C5}, 'goldValue': 150,
      'cosmeticSlot': 'outfit', 'assetPath': 'assets/items/outfit_teal.svg',
    },
    {
      'name': 'Cape Violette',
      'description': 'Une cape de velours violet à l\'allure mystérieuse.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.style.codePoint,
      'stats': {'colorValue': 0xFF805AD5}, 'goldValue': 250,
      'cosmeticSlot': 'outfit', 'assetPath': 'assets/items/outfit_violet.svg',
    },
    {
      'name': 'Veste Sombre',
      'description': 'Une veste navy élégante aux coutures argentées.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.checkroom.codePoint,
      'stats': {'colorValue': 0xFF2C5282}, 'goldValue': 180,
      'cosmeticSlot': 'outfit', 'assetPath': 'assets/items/outfit_navy.svg',
    },
    {
      'name': 'Gilet Doré',
      'description': 'Un gilet orné de broderies dorées digne d\'un seigneur.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.star_border.codePoint,
      'stats': {'colorValue': 0xFFD69E2E}, 'goldValue': 550,
      'cosmeticSlot': 'outfit', 'assetPath': 'assets/items/outfit_gold.svg',
    },
    {
      'name': 'Tenue Écarlate',
      'description': 'Une tunique rouge feu portée par les grands guerriers.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.style.codePoint,
      'stats': {'colorValue': 0xFFC53030}, 'goldValue': 280,
      'cosmeticSlot': 'outfit', 'assetPath': 'assets/items/outfit_red.svg',
    },
    // ── COSMÉTIQUES — PANTALONS ────────────────────────────────────────────────
    {
      'name': 'Pantalon Sombre',
      'description': 'Un pantalon de voyage robuste aux tons anthracite.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.remove_from_queue.codePoint,
      'stats': {'colorValue': 0xFF2D3748}, 'goldValue': 60,
      'cosmeticSlot': 'pants', 'assetPath': 'assets/items/pants_dark.svg',
    },
    {
      'name': 'Pantalon Pourpre',
      'description': 'Un pantalon couleur prune réservé aux nobles.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.remove_from_queue.codePoint,
      'stats': {'colorValue': 0xFF553C9A}, 'goldValue': 140,
      'cosmeticSlot': 'pants', 'assetPath': 'assets/items/pants_purple.svg',
    },
    {
      'name': 'Kilt de Clan',
      'description': 'Un kilt rouge des hautes terres pour les aventuriers intrépides.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.grid_on.codePoint,
      'stats': {'colorValue': 0xFFC53030}, 'goldValue': 230,
      'cosmeticSlot': 'pants', 'assetPath': 'assets/items/pants_red.svg',
    },
    {
      'name': 'Braies de Mage',
      'description': 'Un pantalon de mage bleu nuit orné de runes lumineuses.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.auto_fix_high.codePoint,
      'stats': {'colorValue': 0xFF1A365D}, 'goldValue': 360,
      'cosmeticSlot': 'pants', 'assetPath': 'assets/items/pants_navy.svg',
    },
    {
      'name': 'Cuissardes Dorées',
      'description': 'Des cuissardes en cuir doré pour les champions.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.star.codePoint,
      'stats': {'colorValue': 0xFFD69E2E}, 'goldValue': 520,
      'cosmeticSlot': 'pants', 'assetPath': 'assets/items/pants_gold.svg',
    },
    // ── COSMÉTIQUES — CHAUSSURES ───────────────────────────────────────────────
    {
      'name': 'Bottes de Combat',
      'description': 'Des bottes sombres solides pour tous les terrains.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.hiking.codePoint,
      'stats': {'colorValue': 0xFF3D2B1A}, 'goldValue': 55,
      'cosmeticSlot': 'shoes', 'assetPath': 'assets/items/shoes_brown.svg',
    },
    {
      'name': 'Souliers Enchantés',
      'description': 'Des souliers aux boucles dorées qui portent chance.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.auto_awesome.codePoint,
      'stats': {'colorValue': 0xFFD69E2E}, 'goldValue': 160,
      'cosmeticSlot': 'shoes', 'assetPath': 'assets/items/shoes_gold.svg',
    },
    {
      'name': 'Sandales d\'Été',
      'description': 'Des sandales légères en cuir tanné pour voyager léger.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.beach_access.codePoint,
      'stats': {'colorValue': 0xFFC68642}, 'goldValue': 45,
      'cosmeticSlot': 'shoes', 'assetPath': 'assets/items/shoes_tan.svg',
    },
    {
      'name': 'Bottes de Glace',
      'description': 'Des bottes d\'un bleu givré forgées dans les montagnes polaires.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.ac_unit.codePoint,
      'stats': {'colorValue': 0xFF76E4F7}, 'goldValue': 390,
      'cosmeticSlot': 'shoes', 'assetPath': 'assets/items/shoes_cyan.svg',
    },
    {
      'name': 'Bottes Mythiques',
      'description': 'Des bottes légendaires qui laissent des empreintes lumineuses.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.mythic,
      'iconCodePoint': Icons.bolt.codePoint,
      'stats': {'colorValue': 0xFFFC8181}, 'goldValue': 900,
      'cosmeticSlot': 'shoes', 'assetPath': 'assets/items/shoes_mythic.svg',
    },
    // ── COSMÉTIQUES — AURAS ────────────────────────────────────────────────────
    {
      'name': 'Aura Dorée',
      'description': 'Une aura rayonnante qui enveloppe le héros d\'or.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.wb_sunny.codePoint,
      'stats': {'colorValue': 0xFFF6E05E}, 'goldValue': 350,
      'cosmeticSlot': 'aura', 'assetPath': 'assets/items/aura_gold.svg',
    },
    {
      'name': 'Aura de Cristal',
      'description': 'Une aura cristalline aux teintes turquoise légendaires.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.flare.codePoint,
      'stats': {'colorValue': 0xFF4FD1C5}, 'goldValue': 600,
      'cosmeticSlot': 'aura', 'assetPath': 'assets/items/aura_teal.svg',
    },
    {
      'name': 'Aura de Feu',
      'description': 'Des flammes ardentes entourent le héros d\'une lueur orange.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.local_fire_department.codePoint,
      'stats': {'colorValue': 0xFFED8936}, 'goldValue': 380,
      'cosmeticSlot': 'aura', 'assetPath': 'assets/items/aura_fire.svg',
    },
    {
      'name': 'Aura d\'Ombre',
      'description': 'Un voile ténébreux enveloppe le personnage de mystère.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.nights_stay.codePoint,
      'stats': {'colorValue': 0xFF44337A}, 'goldValue': 650,
      'cosmeticSlot': 'aura', 'assetPath': 'assets/items/aura_shadow.svg',
    },
    {
      'name': 'Aura Sacrée',
      'description': 'Un halo argenté qui rayonne la pureté et la lumière divine.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.mythic,
      'iconCodePoint': Icons.wb_incandescent.codePoint,
      'stats': {'colorValue': 0xFFE2E8F0}, 'goldValue': 950,
      'cosmeticSlot': 'aura', 'assetPath': 'assets/items/aura_holy.svg',
    },
    // ── MATÉRIAUX ──────────────────────────────────────────────────────────────
    {
      'name': 'Fragment de Pierre',
      'description': 'Un fragment mystérieux à collectionner.',
      'type': ItemType.material, 'rarity': QuestRarity.common,
      'iconCodePoint': Icons.texture.codePoint,
      'stats': {}, 'goldValue': 10, 'stackable': true,
      'assetPath': 'assets/items/material_stone.svg',
    },
    {
      'name': 'Cristal Brut',
      'description': 'Un cristal qui peut être utilisé pour l\'invocation.',
      'type': ItemType.material, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.diamond_outlined.codePoint,
      'stats': {}, 'goldValue': 50, 'stackable': true,
      'assetPath': 'assets/items/material_crystal.svg',
    },
    {
      'name': 'Essence Mythique',
      'description': 'Une essence rarissime aux propriétés inconnues.',
      'type': ItemType.material, 'rarity': QuestRarity.mythic,
      'iconCodePoint': Icons.flare.codePoint,
      'stats': {}, 'goldValue': 500, 'stackable': true,
      'assetPath': 'assets/items/material_essence.svg',
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

  /// Comme [rollGachaRarity] mais applique le système pity.
  /// - pityCount ≥ 80 → Légendaire garanti, reset
  /// - pityCount ≥ 20 → Épique minimum garanti, reset
  /// Retourne aussi un booléen indiquant si le pity a été déclenché.
  static ({QuestRarity rarity, bool pityTriggered}) rollGachaRarityWithPity(
      int pityCount) {
    if (pityCount >= 80) {
      return (rarity: QuestRarity.legendary, pityTriggered: true);
    }
    if (pityCount >= 20) {
      final result = rollGachaRarity();
      final forced = result.index < QuestRarity.epic.index
          ? QuestRarity.epic
          : result;
      return (rarity: forced, pityTriggered: forced == QuestRarity.epic && result.index < QuestRarity.epic.index);
    }
    return (rarity: rollGachaRarity(), pityTriggered: false);
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
      cosmeticSlot: template['cosmeticSlot'] as String?,
      assetPath: template['assetPath'] as String?,
    );
  }

  /// Catalogue des items achetables en cristaux (boutique premium).
  static final List<Map<String, dynamic>> _crystalCatalog = [
    {
      'name': 'Potion de Soin Suprême',
      'description': 'Restaure 50 HP instantanément.',
      'type': ItemType.potion, 'rarity': QuestRarity.rare,
      'iconCodePoint': Icons.favorite.codePoint,
      'stats': {'hpBonus': 50}, 'goldValue': 0, 'crystalValue': 10,
      'stackable': true,
    },
    {
      'name': 'Élixir d\'XP',
      'description': 'Double les XP gagnés sur votre prochaine quête.',
      'type': ItemType.potion, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.auto_awesome.codePoint,
      'stats': {'xpBonus': 100}, 'goldValue': 0, 'crystalValue': 20,
      'stackable': true,
    },
    {
      'name': 'Amulette du Héros',
      'description': 'Accessoire légendaire qui booste XP et or simultanément.',
      'type': ItemType.ring, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.circle.codePoint,
      'stats': {'xpBonus': 20, 'goldBonus': 20}, 'goldValue': 0, 'crystalValue': 50,
    },
    {
      'name': 'Parchemin de Réinitialisation',
      'description': 'Remet à zéro le cooldown de caresse du chat.',
      'type': ItemType.potion, 'rarity': QuestRarity.uncommon,
      'iconCodePoint': Icons.refresh.codePoint,
      'stats': {'resetCatCooldown': 1}, 'goldValue': 0, 'crystalValue': 5,
      'stackable': true,
    },
    {
      'name': 'Chapeau du Magicien',
      'description': 'Un chapeau violet étoilé pour votre compagnon.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.epic,
      'iconCodePoint': Icons.dry_outlined.codePoint,
      'stats': {}, 'goldValue': 0, 'crystalValue': 30,
      'cosmeticSlot': 'hat',
    },
    {
      'name': 'Aura Dorée',
      'description': 'Une aura dorée légendaire qui enveloppe votre chat.',
      'type': ItemType.cosmetic, 'rarity': QuestRarity.legendary,
      'iconCodePoint': Icons.auto_awesome_outlined.codePoint,
      'stats': {}, 'goldValue': 0, 'crystalValue': 75,
      'cosmeticSlot': 'aura',
    },
  ];

  /// Retourne le catalogue achetable en cristaux (boutique premium).
  static List<Item> getCrystalCatalog() {
    return _crystalCatalog.map((c) => Item(
          id: 'crystal_${c['name']}',
          name: c['name'] as String,
          description: c['description'] as String,
          type: c['type'] as ItemType,
          rarity: c['rarity'] as QuestRarity,
          iconCodePoint: c['iconCodePoint'] as int,
          stats: Map<String, int>.from((c['stats'] as Map?) ?? {}),
          quantity: 1,
          stackable: c['stackable'] as bool? ?? false,
          goldValue: 0,
          crystalValue: c['crystalValue'] as int,
          cosmeticSlot: c['cosmeticSlot'] as String?,
        )).toList();
  }

  /// Retourne le catalogue achetable en boutique.
  static List<Item> getMarketCatalog() {
    return _catalog
        .where((c) => c['type'] != ItemType.material)
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
              cosmeticSlot: c['cosmeticSlot'] as String?,
              assetPath: c['assetPath'] as String?,
            ))
        .toList();
  }
}
