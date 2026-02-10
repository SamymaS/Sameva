import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Carte minimaliste avec glassmorphism allégé
/// Style "Magie Minimaliste" selon UX_UI_REFACTORING.md
class MinimalistCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool showGlow;

  const MinimalistCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.glowColor,
    this.onTap,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = padding ?? const EdgeInsets.all(16.0);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16.0);
    final defaultBorderColor = borderColor ?? AppColors.primaryTurquoise.withOpacity(0.3);
    final defaultGlowColor = glowColor ?? AppColors.primaryTurquoise;

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        // Glassmorphism translucide
        color: AppColors.backgroundDarkPanel.withOpacity(0.6),
        borderRadius: defaultBorderRadius,
        border: Border.all(
          color: defaultBorderColor,
          width: borderWidth,
        ),
        // Glow subtil
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: defaultGlowColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: defaultBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: defaultPadding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultBorderRadius,
          child: card,
        ),
      );
    }

    return card;
  }
}






