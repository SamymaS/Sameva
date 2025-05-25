import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color background = Color(0xFFF8F3FF);  // Fond doux violet très clair
  static const Color primary = Color(0xFF9F89FF);     // Violet pastel
  static const Color secondary = Color(0xFFB5E9FF);   // Bleu pastel
  static const Color accent = Color(0xFFFFB5D8);      // Rose pastel
  
  // Couleurs des cartes
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x0F000000);  // Ombre très légère
  
  // Textes
  static const Color textPrimary = Color(0xFF3B3B3B);
  static const Color textSecondary = Color(0xFF6E6E6E);
  
  // États
  static const Color success = Color(0xFF80FFB0);     // Vert pastel
  static const Color error = Color(0xFFFF9B9B);       // Rouge pastel
}

class AppStyles {
  // Rayons de bordure
  static BorderRadius radius = BorderRadius.circular(20);
  static BorderRadius radiusLarge = BorderRadius.circular(30);
  
  // Ombre douce
  static BoxShadow softShadow = BoxShadow(
    color: AppColors.cardShadow,
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  // Styles de texte
  static TextStyle titleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitleStyle = const TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );
}