import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_colors.dart';

class AppStyles {
  static final BorderRadius radius = BorderRadius.circular(16);

  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x1A000000), // noir 10% approx
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
