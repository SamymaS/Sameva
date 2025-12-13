import 'package:flutter/material.dart';

/// Couleurs de l'application Sameva - Basé sur le design Figma
class AppColors {
  // ============================================
  // COULEURS PRINCIPALES (selon Figma)
  // ============================================
  
  /// Turquoise Primaire
  static const Color primaryTurquoise = Color(0xFF4FD1C5);
  static const Color primaryTurquoiseDark = Color(0xFF38B2AC);
  
  /// Violet Secondaire
  static const Color secondaryViolet = Color(0xFF805AD5);
  static const Color secondaryVioletGlow = Color(0xFFB794F4);
  
  /// Or
  static const Color gold = Color(0xFFF6E05E);
  static const Color goldDark = Color(0xFFD69E2E);
  
  // ============================================
  // BACKGROUNDS (selon Figma)
  // ============================================
  
  static const Color backgroundDeepViolet = Color(0xFF2D2B55);
  static const Color backgroundNightBlue = Color(0xFF0F172A);
  static const Color backgroundDarkPanel = Color(0xFF1A202C);

  // ============================================
  // COULEURS DE TEXTE
  // ============================================
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E0);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color cream100 = Color(0xFFF5F3F0);
  static const Color cream200 = Color(0xFFEBE8E3);
  static const Color parchment = Color(0xFFFFFAF0);

  // ============================================
  // COULEURS D'ÉTAT
  // ============================================
  
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ============================================
  // SYSTÈME DE RARETÉ (selon Figma)
  // ============================================
  
  static const Color rarityCommon = Color(0xFFCBD5E0);      // Gris
  static const Color rarityUncommon = Color(0xFF68D391);    // Vert
  static const Color rarityRare = Color(0xFF4299E1);        // Bleu
  static const Color rarityEpic = Color(0xFF9F7AEA);        // Violet
  static const Color rarityLegendary = Color(0xFFECC94B);    // Or
  static const Color rarityMythic = Color(0xFFFC8181);      // Rouge
  
  // Anciennes couleurs (compatibilité)
  static const Color rarityVeryRare = rarityEpic;
  
  // ============================================
  // COMPATIBILITÉ - Anciennes propriétés
  // ============================================
  
  // Anciennes couleurs principales (compatibilité)
  static const Color primary = primaryTurquoise;
  static const Color accent = gold;
  static const Color secondary = secondaryViolet;
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = backgroundNightBlue;
  
  // Propriétés de compatibilité pour les anciens widgets
  static const Color card = backgroundDarkPanel;
  static const Color cardForeground = textPrimary;
  static const Color border = inputBorder;
  static const Color primaryForeground = textPrimary;
  static const Color accentForeground = textPrimary;
  
  // Anciennes couleurs de rareté (compatibilité)
  static const Color common = rarityCommon;
  static const Color uncommon = rarityUncommon;
  static const Color rare = rarityRare;
  static const Color veryRare = rarityEpic;
  static const Color epic = rarityEpic;
  static const Color legendary = rarityLegendary;
  static const Color mythic = rarityMythic;

  // ============================================
  // UI ELEMENTS
  // ============================================
  
  static const Color inputBg = backgroundNightBlue;
  static const Color inputBorder = Color(0xFF4A5568);
  static const Color cardBg = Color(0xCC1A202C); // rgba(26, 32, 44, 0.8) - 0xCC = 80% opacity
  static const Color glassBg = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.1)
  
  // ============================================
  // HELPERS
  // ============================================
  
  /// Retourne la couleur de rareté selon l'enum
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return rarityCommon;
      case 'uncommon':
        return rarityUncommon;
      case 'rare':
        return rarityRare;
      case 'epic':
        return rarityEpic;
      case 'legendary':
        return rarityLegendary;
      case 'mythic':
        return rarityMythic;
      default:
        return rarityCommon;
    }
  }
  
  /// Vérifie si une rareté doit avoir un effet glow
  static bool shouldGlow(String rarity) {
    return rarity.toLowerCase() == 'epic' || 
           rarity.toLowerCase() == 'legendary' || 
           rarity.toLowerCase() == 'mythic';
  }
}

