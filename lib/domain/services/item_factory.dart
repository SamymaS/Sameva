import '../entities/item.dart';
import '../../presentation/providers/quest_provider.dart';

/// Factory pour créer des items prédéfinis
class ItemFactory {
  /// Crée un item d'arme
  static Item createWeapon({
    required String name,
    required ItemRarity rarity,
    required int attackBonus,
    required int value,
    String? imagePath,
  }) {
    return Item(
      name: name,
      description: 'Une arme puissante qui augmente votre attaque.',
      type: ItemType.weapon,
      rarity: rarity,
      imagePath: imagePath ?? 'assets/icons/items/sword.png',
      attackBonus: attackBonus,
      value: value,
      isEquippable: true,
    );
  }

  /// Crée un item d'armure
  static Item createArmor({
    required String name,
    required ItemRarity rarity,
    required int defenseBonus,
    required int healthBonus,
    required int value,
    String? imagePath,
  }) {
    return Item(
      name: name,
      description: 'Une armure qui augmente votre défense et vos PV.',
      type: ItemType.armor,
      rarity: rarity,
      imagePath: imagePath ?? 'assets/icons/items/armor.png',
      defenseBonus: defenseBonus,
      healthBonus: healthBonus,
      value: value,
      isEquippable: true,
    );
  }

  /// Crée une potion
  static Item createPotion({
    required String name,
    required ItemRarity rarity,
    int? healthBonus,
    int? experienceBonus,
    int? goldBonus,
    required int value,
    String? imagePath,
  }) {
    return Item(
      name: name,
      description: 'Une potion magique qui restaure vos ressources.',
      type: ItemType.potion,
      rarity: rarity,
      imagePath: imagePath ?? 'assets/icons/items/potionRed.png',
      healthBonus: healthBonus,
      experienceBonus: experienceBonus,
      goldBonus: goldBonus,
      value: value,
      isConsumable: true,
      stackSize: 10,
    );
  }

  /// Crée un item cosmétique (tenue)
  static Item createOutfit({
    required String name,
    required ItemRarity rarity,
    required int value,
    String? imagePath,
  }) {
    return Item(
      name: name,
      description: 'Une tenue élégante pour personnaliser votre avatar.',
      type: ItemType.cosmetic,
      rarity: rarity,
      imagePath: imagePath,
      value: value,
      isEquippable: true,
      metadata: {'subtype': 'outfit'},
    );
  }

  /// Crée une aura
  static Item createAura({
    required String name,
    required ItemRarity rarity,
    required int value,
    String? imagePath,
  }) {
    return Item(
      name: name,
      description: 'Une aura magique qui entoure votre avatar.',
      type: ItemType.cosmetic,
      rarity: rarity,
      imagePath: imagePath,
      value: value,
      isEquippable: true,
      metadata: {'subtype': 'aura'},
    );
  }

  /// Crée des items de base pour le jeu avec les vrais assets
  static List<Item> createDefaultItems() {
    return [
      // Armes Communes
      createWeapon(
        name: 'Épée en bois',
        rarity: ItemRarity.common,
        attackBonus: 5,
        value: 50,
        imagePath: 'assets/icons/items/woodSword.png',
      ),
      createWeapon(
        name: 'Hache simple',
        rarity: ItemRarity.common,
        attackBonus: 6,
        value: 60,
        imagePath: 'assets/icons/items/axe.png',
      ),
      createWeapon(
        name: 'Marteau basique',
        rarity: ItemRarity.common,
        attackBonus: 7,
        value: 70,
        imagePath: 'assets/icons/items/hammer.png',
      ),
      
      // Armes Peu Communes
      createWeapon(
        name: 'Hache améliorée',
        rarity: ItemRarity.uncommon,
        attackBonus: 12,
        value: 200,
        imagePath: 'assets/icons/items/upg_axe.png',
      ),
      createWeapon(
        name: 'Dague',
        rarity: ItemRarity.uncommon,
        attackBonus: 10,
        value: 150,
        imagePath: 'assets/icons/items/dagger.png',
      ),
      createWeapon(
        name: 'Baguette',
        rarity: ItemRarity.uncommon,
        attackBonus: 11,
        value: 180,
        imagePath: 'assets/icons/items/wand.png',
      ),
      
      // Armes Rares
      createWeapon(
        name: 'Hache double',
        rarity: ItemRarity.rare,
        attackBonus: 18,
        value: 400,
        imagePath: 'assets/icons/items/axeDouble.png',
      ),
      createWeapon(
        name: 'Arc amélioré',
        rarity: ItemRarity.rare,
        attackBonus: 20,
        value: 450,
        imagePath: 'assets/icons/items/upg_bow.png',
      ),
      createWeapon(
        name: 'Dague améliorée',
        rarity: ItemRarity.rare,
        attackBonus: 22,
        value: 500,
        imagePath: 'assets/icons/items/upg_dagger.png',
      ),
      
      // Armes Très Rares
      createWeapon(
        name: 'Hache double améliorée',
        rarity: ItemRarity.veryRare,
        attackBonus: 30,
        value: 800,
        imagePath: 'assets/icons/items/upg_axeDouble.png',
      ),
      createWeapon(
        name: 'Marteau amélioré',
        rarity: ItemRarity.veryRare,
        attackBonus: 28,
        value: 750,
        imagePath: 'assets/icons/items/upg_hammer.png',
      ),
      createWeapon(
        name: 'Baguette améliorée',
        rarity: ItemRarity.veryRare,
        attackBonus: 32,
        value: 900,
        imagePath: 'assets/icons/items/upg_wand.png',
      ),
      
      // Armes Épiques
      createWeapon(
        name: 'Épée épique',
        rarity: ItemRarity.epic,
        attackBonus: 40,
        value: 1500,
        imagePath: 'assets/icons/items/upg_sword.png',
      ),
      createWeapon(
        name: 'Lance épique',
        rarity: ItemRarity.epic,
        attackBonus: 42,
        value: 1600,
        imagePath: 'assets/icons/items/upg_spear.png',
      ),
      
      // Armures
      createArmor(
        name: 'Armure de cuir',
        rarity: ItemRarity.common,
        defenseBonus: 5,
        healthBonus: 10,
        value: 80,
        imagePath: 'assets/icons/items/armor.png',
      ),
      createArmor(
        name: 'Armure renforcée',
        rarity: ItemRarity.uncommon,
        defenseBonus: 12,
        healthBonus: 25,
        value: 250,
        imagePath: 'assets/icons/items/upg_armor.png',
      ),
      
      // Casques
      Item(
        name: 'Casque basique',
        description: 'Un casque qui augmente votre défense.',
        type: ItemType.helmet,
        rarity: ItemRarity.common,
        imagePath: 'assets/icons/items/helmet.png',
        defenseBonus: 3,
        healthBonus: 5,
        value: 60,
        isEquippable: true,
      ),
      Item(
        name: 'Casque amélioré',
        description: 'Un casque renforcé qui augmente votre défense.',
        type: ItemType.helmet,
        rarity: ItemRarity.uncommon,
        imagePath: 'assets/icons/items/upg_helmet.png',
        defenseBonus: 8,
        healthBonus: 15,
        value: 200,
        isEquippable: true,
      ),
      
      // Boucliers
      Item(
        name: 'Petit bouclier',
        description: 'Un bouclier qui augmente votre défense.',
        type: ItemType.shield,
        rarity: ItemRarity.common,
        imagePath: 'assets/icons/items/shieldSmall.png',
        defenseBonus: 8,
        value: 100,
        isEquippable: true,
      ),
      Item(
        name: 'Grand bouclier',
        description: 'Un bouclier solide qui augmente votre défense.',
        type: ItemType.shield,
        rarity: ItemRarity.uncommon,
        imagePath: 'assets/icons/items/shield.png',
        defenseBonus: 15,
        value: 300,
        isEquippable: true,
      ),
      Item(
        name: 'Bouclier amélioré',
        description: 'Un bouclier renforcé qui augmente votre défense.',
        type: ItemType.shield,
        rarity: ItemRarity.rare,
        imagePath: 'assets/icons/items/upg_shield.png',
        defenseBonus: 25,
        value: 600,
        isEquippable: true,
      ),
      Item(
        name: 'Petit bouclier amélioré',
        description: 'Un petit bouclier renforcé.',
        type: ItemType.shield,
        rarity: ItemRarity.rare,
        imagePath: 'assets/icons/items/upg_shieldSmall.png',
        defenseBonus: 20,
        value: 500,
        isEquippable: true,
      ),
      
      // Potions
      createPotion(
        name: 'Potion de soin',
        rarity: ItemRarity.common,
        healthBonus: 50,
        value: 30,
        imagePath: 'assets/icons/items/potionRed.png',
      ),
      createPotion(
        name: 'Potion d\'expérience',
        rarity: ItemRarity.uncommon,
        experienceBonus: 100,
        value: 100,
        imagePath: 'assets/icons/items/potionBlue.png',
      ),
      createPotion(
        name: 'Potion d\'or',
        rarity: ItemRarity.uncommon,
        goldBonus: 200,
        value: 150,
        imagePath: 'assets/icons/items/potionGreen.png',
      ),
      
      // Consommables
      Item(
        name: 'Parchemin',
        description: 'Un parchemin mystérieux qui augmente votre expérience.',
        type: ItemType.consumable,
        rarity: ItemRarity.common,
        imagePath: 'assets/icons/items/scroll.png',
        experienceBonus: 50,
        value: 40,
        isConsumable: true,
        stackSize: 5,
      ),
      Item(
        name: 'Tome',
        description: 'Un tome ancien qui augmente votre expérience.',
        type: ItemType.consumable,
        rarity: ItemRarity.uncommon,
        imagePath: 'assets/icons/items/tome.png',
        experienceBonus: 150,
        value: 120,
        isConsumable: true,
        stackSize: 3,
      ),
      Item(
        name: 'Pièce d\'or',
        description: 'Une pièce d\'or qui augmente votre fortune.',
        type: ItemType.consumable,
        rarity: ItemRarity.common,
        imagePath: 'assets/icons/items/coin.png',
        goldBonus: 50,
        value: 50,
        isConsumable: true,
        stackSize: 10,
      ),
    ];
  }

  /// Crée un item de récompense basé sur la rareté d'une quête
  static Item? createQuestRewardItem(QuestRarity questRarity) {
    switch (questRarity) {
      case QuestRarity.common:
        return createPotion(
          name: 'Potion de base',
          rarity: ItemRarity.common,
          healthBonus: 25,
          value: 20,
        );
      case QuestRarity.uncommon:
        return createPotion(
          name: 'Potion améliorée',
          rarity: ItemRarity.uncommon,
          healthBonus: 50,
          experienceBonus: 50,
          value: 50,
        );
      case QuestRarity.rare:
        return createWeapon(
          name: 'Arme rare',
          rarity: ItemRarity.rare,
          attackBonus: 12,
          value: 200,
        );
      case QuestRarity.veryRare:
        return createArmor(
          name: 'Armure rare',
          rarity: ItemRarity.rare,
          defenseBonus: 12,
          healthBonus: 25,
          value: 300,
        );
      case QuestRarity.epic:
        return createWeapon(
          name: 'Arme épique',
          rarity: ItemRarity.epic,
          attackBonus: 25,
          value: 500,
        );
      case QuestRarity.legendary:
        return createArmor(
          name: 'Armure légendaire',
          rarity: ItemRarity.legendary,
          defenseBonus: 30,
          healthBonus: 50,
          value: 1000,
        );
      case QuestRarity.mythic:
        return createWeapon(
          name: 'Arme mythique',
          rarity: ItemRarity.mythic,
          attackBonus: 50,
          value: 2000,
        );
    }
  }
}

