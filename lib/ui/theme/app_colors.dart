import 'package:flutter/material.dart';

/// Palette Sameva — DA "Cosmos Chat" 🐱
/// Référence unique pour toutes les couleurs de l'application.
class AppColors {
  // ============================================
  // BACKGROUNDS
  // ============================================

  static const Color backgroundNightCosmos = Color(0xFF120A2E);
  static const Color backgroundDarkPanel   = Color(0xFF1A0F3C);

  // ============================================
  // COULEURS PRIMAIRES
  // ============================================

  static const Color primaryViolet      = Color(0xFF805AD5);
  static const Color primaryVioletLight = Color(0xFFB794F4);
  static const Color primaryVioletGlow  = Color(0xFFE9D5FF);

  // ============================================
  // ACCENTS
  // ============================================

  static const Color gold        = Color(0xFFFDE68A);
  static const Color goldDark    = Color(0xFFF59E0B);
  static const Color crystalBlue = Color(0xFF7DD3FC);
  static const Color rosePastel  = Color(0xFFFDA4AF);
  static const Color mintMagic   = Color(0xFF86EFAC);
  static const Color coralRare   = Color(0xFFFCA5A5);

  // ============================================
  // TEXTES
  // ============================================

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBD5E0);
  static const Color textMuted     = Color(0xFF9CA3AF);

  // ============================================
  // RARETÉS
  // ============================================

  static const Color rarityCommon    = Color(0xFFCBD5E1);
  static const Color rarityUncommon  = Color(0xFF86EFAC);
  static const Color rarityRare      = Color(0xFF7DD3FC);
  static const Color rarityEpic      = Color(0xFFA78BFA);
  static const Color rarityLegendary = Color(0xFFFDE68A);
  static const Color rarityMythic    = Color(0xFFFCA5A5);

  // ============================================
  // ALIASES DE COMPATIBILITÉ (anciens noms)
  // ============================================

  // Backgrounds
  static const Color backgroundNightBlue = backgroundNightCosmos;
  static const Color backgroundDeepViolet = Color(0xFF2D1B6E);

  // Primaires (anciens noms turquoise → violet)
  static const Color primaryTurquoise     = primaryViolet;
  static const Color primaryTurquoiseDark = Color(0xFF6B46C1);
  static const Color secondaryViolet      = primaryViolet;
  static const Color secondaryVioletGlow  = primaryVioletLight;

  // Génériques
  static const Color primary          = primaryViolet;
  static const Color secondary        = primaryVioletLight;
  static const Color accent           = gold;
  static const Color background       = backgroundNightCosmos;
  static const Color backgroundDark   = backgroundNightCosmos;
  static const Color card             = backgroundDarkPanel;
  static const Color cardForeground   = textPrimary;
  static const Color primaryForeground = textPrimary;
  static const Color accentForeground  = textPrimary;

  // UI Elements
  static const Color inputBg     = backgroundNightCosmos;
  static const Color inputBorder = Color(0xFF4A5568);
  static const Color border      = inputBorder;
  static const Color cardBg      = Color(0xCC1A0F3C);
  static const Color glassBg     = Color(0x1AFFFFFF);

  // Couleurs de texte supplémentaires (compatibilité)
  static const Color cream100  = Color(0xFFF5F3F0);
  static const Color cream200  = Color(0xFFEBE8E3);
  static const Color parchment = Color(0xFFFFFAF0);

  // États (compatibilité)
  static const Color success = mintMagic;
  static const Color error   = coralRare;
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = crystalBlue;

  // Raretés (anciens noms)
  static const Color rarityVeryRare = rarityEpic;
  static const Color common         = rarityCommon;
  static const Color uncommon       = rarityUncommon;
  static const Color rare           = rarityRare;
  static const Color veryRare       = rarityEpic;
  static const Color epic           = rarityEpic;
  static const Color legendary      = rarityLegendary;
  static const Color mythic         = rarityMythic;

  // ============================================
  // HELPERS
  // ============================================

  /// Retourne la couleur de rareté selon la chaîne.
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':    return rarityCommon;
      case 'uncommon':  return rarityUncommon;
      case 'rare':      return rarityRare;
      case 'epic':      return rarityEpic;
      case 'legendary': return rarityLegendary;
      case 'mythic':    return rarityMythic;
      default:          return rarityCommon;
    }
  }

  /// Indique si une rareté mérite un effet glow.
  static bool shouldGlow(String rarity) {
    final r = rarity.toLowerCase();
    return r == 'epic' || r == 'legendary' || r == 'mythic';
  }
}
