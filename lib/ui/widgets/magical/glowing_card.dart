import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Carte avec lueurs internes et dégradés de bordure
/// Style "Moderne Éthérée" avec effet magique
class GlowingCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double? borderWidth;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool showInnerGlow;

  const GlowingCard({
    super.key,
    required this.child,
    this.glowColor,
    this.borderWidth,
    this.padding,
    this.onTap,
    this.showInnerGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppColors.primaryTurquoise;
    final effectiveBorderWidth = borderWidth ?? 1.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Fond translucide
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          // Bordure avec dégradé
          border: Border.all(
            width: effectiveBorderWidth,
            color: effectiveGlowColor.withOpacity(0.3),
          ),
          // Ombre externe (glow)
          boxShadow: [
            BoxShadow(
              color: effectiveGlowColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: effectiveGlowColor.withOpacity(0.1),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lueur interne (inner shadow effect)
            if (showInnerGlow)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.5,
                      colors: [
                        effectiveGlowColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            // Contenu
            child,
          ],
        ),
      ),
    );
  }
}

/// Carte avec glassmorphism et lueur
class GlassmorphicGlowingCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double blur;

  const GlassmorphicGlowingCard({
    super.key,
    required this.child,
    this.glowColor,
    this.padding,
    this.onTap,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppColors.primaryTurquoise;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Fond translucide avec glassmorphism
              color: AppColors.backgroundNightBlue.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              // Bordure subtile
              border: Border.all(
                width: 1.5,
                color: Colors.white.withOpacity(0.1),
              ),
              // Lueur externe
              boxShadow: [
                BoxShadow(
                  color: effectiveGlowColor.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

