/// Helper pour charger les assets depuis Figma
/// Utilisez cette classe pour centraliser les chemins des assets
class FigmaAssets {
  // Avatars
  static const String avatarBase = 'assets/images/avatars/hero_base.png';
  static const String avatar1 = 'assets/images/avatars/hero_1.png';
  static const String avatar2 = 'assets/images/avatars/hero_2.png';
  
  // Items du marché
  static const String itemHeaume = 'assets/images/items/heaume_du_zénith.png';
  static const String itemEpee = 'assets/images/items/épée_légendaire.png';
  static const String itemBouclier = 'assets/images/items/bouclier_commun.png';
  static const String itemArmure = 'assets/images/items/armure_rare.png';
  static const String itemAmulette = 'assets/images/items/amulette_mythique.png';
  static const String itemPotion = 'assets/images/items/potion_inhabituelle.png';
  
  // Backgrounds
  static const String backgroundHome = 'assets/images/backgrounds/home_background.png';
  static const String backgroundMarket = 'assets/images/backgrounds/market_background.png';
  static const String backgroundInvocation = 'assets/images/backgrounds/invocation_background.png';
  
  // Compagnons
  static const String companion1 = 'assets/images/companions/companion_1.png';
  static const String companion2 = 'assets/images/companions/companion_2.png';
  static const String companion3 = 'assets/images/companions/companion_3.png';
  
  // Auras
  static const String aura1 = 'assets/images/auras/aura_1.png';
  static const String aura2 = 'assets/images/auras/aura_2.png';
  static const String aura3 = 'assets/images/auras/aura_3.png';
  static const String aura4 = 'assets/images/auras/aura_4.png';
  
  // Mini-jeux
  static const String minigameMemory = 'assets/images/minigames/memory_quest.png';
  static const String minigameSpeed = 'assets/images/minigames/speed_challenge.png';
  static const String minigamePuzzle = 'assets/images/minigames/puzzle_quest.png';
  static const String minigameBattle = 'assets/images/minigames/battle_arena.png';
  
  /// Helper pour obtenir le chemin d'un item par son nom
  static String getItemPath(String itemName) {
    final normalizedName = itemName.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o');
    return 'assets/images/items/$normalizedName.png';
  }
  
  /// Helper pour obtenir le chemin d'un avatar par index
  static String getAvatarPath(int index) {
    if (index == 0) return avatarBase;
    return 'assets/images/avatars/hero_$index.png';
  }
  
  /// Helper pour obtenir le chemin d'un compagnon par index
  static String getCompanionPath(int index) {
    return 'assets/images/companions/companion_${index + 1}.png';
  }
  
  /// Helper pour obtenir le chemin d'une aura par index
  static String getAuraPath(int index) {
    return 'assets/images/auras/aura_${index + 1}.png';
  }
}





