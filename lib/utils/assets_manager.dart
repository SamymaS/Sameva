/// Gestionnaire centralisé des assets de l'application
/// Remplace les emojis par de vrais assets d'images
class AssetsManager {
  // ============================================
  // AVATARS
  // ============================================
  
  /// Chemin de base pour les avatars
  static const String avatarsPath = 'assets/images/avatars/';
  
  /// Avatar par défaut
  static const String defaultAvatar = '${avatarsPath}hero_base.png';
  
  /// Obtenir le chemin d'un avatar par ID ou nom
  static String getAvatarPath(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) {
      return defaultAvatar;
    }
    return '${avatarsPath}${avatarId}.png';
  }
  
  /// Liste des avatars disponibles (à compléter selon vos assets)
  static const List<String> availableAvatars = [
    'hero_base',
    'hero_1',
    'hero_2',
    'hero_3',
  ];
  
  // ============================================
  // FAMILIERS / COMPAGNONS
  // ============================================
  
  /// Chemin de base pour les familiers
  static const String companionsPath = 'assets/images/companions/';
  
  /// Familier par défaut
  static const String defaultCompanion = '${companionsPath}companion_1.png';
  
  /// Obtenir le chemin d'un familier par ID ou nom
  static String getCompanionPath(String? companionId) {
    if (companionId == null || companionId.isEmpty) {
      return defaultCompanion;
    }
    return '${companionsPath}${companionId}.png';
  }
  
  /// Liste des familiers disponibles
  static const List<String> availableCompanions = [
    'companion_1',
    'companion_2',
    'companion_3',
    'companion_fox',
    'companion_dragon',
  ];
  
  // ============================================
  // ITEMS / ÉQUIPEMENTS
  // ============================================
  
  /// Chemin de base pour les items
  static const String itemsPath = 'assets/images/items/';
  
  /// Obtenir le chemin d'un item par nom
  static String getItemPath(String itemName) {
    // Normaliser le nom (enlever accents, espaces, etc.)
    final normalizedName = _normalizeFileName(itemName);
    return '${itemsPath}${normalizedName}.png';
  }
  
  /// Items par type (exemples)
  static const Map<String, List<String>> itemsByType = {
    'weapon': [
      'sword_common',
      'sword_rare',
      'sword_epic',
      'sword_legendary',
    ],
    'armor': [
      'armor_common',
      'armor_rare',
      'armor_epic',
    ],
    'helmet': [
      'helmet_common',
      'helmet_rare',
    ],
    'shield': [
      'shield_common',
      'shield_rare',
    ],
    'potion': [
      'potion_health',
      'potion_mana',
      'potion_strength',
    ],
  };
  
  // ============================================
  // AURAS / EFFETS VISUELS
  // ============================================
  
  /// Chemin de base pour les auras
  static const String aurasPath = 'assets/images/auras/';
  
  /// Obtenir le chemin d'une aura par ID
  static String getAuraPath(String? auraId) {
    if (auraId == null || auraId.isEmpty) {
      return '${aurasPath}aura_1.png';
    }
    return '${aurasPath}${auraId}.png';
  }
  
  /// Liste des auras disponibles
  static const List<String> availableAuras = [
    'aura_1',
    'aura_2',
    'aura_3',
    'aura_fire',
    'aura_ice',
    'aura_lightning',
  ];
  
  // ============================================
  // BACKGROUNDS
  // ============================================
  
  /// Chemin de base pour les backgrounds
  static const String backgroundsPath = 'assets/images/backgrounds/';
  
  static const String backgroundHome = '${backgroundsPath}home_background.png';
  static const String backgroundMarket = '${backgroundsPath}market_background.png';
  static const String backgroundInvocation = '${backgroundsPath}invocation_background.png';
  static const String backgroundSanctuary = '${backgroundsPath}sanctuary_background.png';
  
  // ============================================
  // INVOCATIONS / GACHA
  // ============================================
  
  /// Chemin de base pour les effets d'invocation
  static const String invocationPath = 'assets/images/invocations/';
  
  static const String invocationVortex = '${invocationPath}vortex.png';
  static const String invocationPortal = '${invocationPath}portal.png';
  static const String invocationGlow = '${invocationPath}glow.png';
  
  // ============================================
  // HELPERS
  // ============================================
  
  /// Normalise un nom de fichier (enlève accents, espaces, etc.)
  static String _normalizeFileName(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
  
  /// Vérifie si un asset existe (à implémenter avec un package de vérification si nécessaire)
  static bool assetExists(String path) {
    // Pour l'instant, on retourne toujours true
    // Vous pouvez utiliser le package 'flutter/services.dart' pour vérifier
    return true;
  }
}

