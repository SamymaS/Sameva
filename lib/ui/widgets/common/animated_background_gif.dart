import 'package:flutter/material.dart';

/// Widget pour afficher un GIF animé en background
/// Supporte aussi les images statiques avec fallback
class AnimatedBackgroundGif extends StatelessWidget {
  final String gifPath;
  final String? fallbackImagePath; // Image statique si GIF non disponible
  final BoxFit fit;
  final double? opacity;
  final Color? colorFilter; // Optionnel : appliquer une couleur par-dessus

  const AnimatedBackgroundGif({
    super.key,
    required this.gifPath,
    this.fallbackImagePath,
    this.fit = BoxFit.cover,
    this.opacity,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      gifPath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Si le GIF n'existe pas, utiliser l'image de fallback
        if (fallbackImagePath != null) {
          return Image.asset(
            fallbackImagePath!,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              // Si même le fallback n'existe pas, afficher un gradient
              return _buildDefaultGradient();
            },
          );
        }
        return _buildDefaultGradient();
      },
    );

    // Appliquer l'opacité si spécifiée
    if (opacity != null) {
      imageWidget = Opacity(
        opacity: opacity!,
        child: imageWidget,
      );
    }

    // Appliquer un filtre de couleur si spécifié
    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          colorFilter!,
          BlendMode.overlay,
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D2B55), // backgroundDeepViolet
            const Color(0xFF0F172A), // backgroundNightBlue
          ],
        ),
      ),
    );
  }
}

/// Widget spécialisé pour les backgrounds de pages avec GIF
class PageAnimatedBackground extends StatelessWidget {
  final String? gifPath;
  final String? staticImagePath;
  final Widget child;
  final double opacity;

  const PageAnimatedBackground({
    super.key,
    this.gifPath,
    this.staticImagePath,
    required this.child,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background animé (GIF) ou statique
        if (gifPath != null || staticImagePath != null)
          Positioned.fill(
            child: AnimatedBackgroundGif(
              gifPath: gifPath ?? staticImagePath ?? '',
              fallbackImagePath: staticImagePath,
              fit: BoxFit.cover,
              opacity: opacity,
            ),
          )
        else
          // Gradient par défaut si aucun asset
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2D2B55),
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
        // Contenu de la page par-dessus
        child,
      ],
    );
  }
}

