import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget réutilisable pour afficher un asset avec fallback automatique
/// Utilisé pour remplacer les emojis par de vrais assets
class AssetImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final double? size; // Si défini, width et height seront égaux à size
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final BoxFit fit;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AssetImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.size,
    this.fallbackIcon = Icons.image,
    this.fallbackColor,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final finalWidth = size ?? width;
    final finalHeight = size ?? height;
    final finalFallbackColor = fallbackColor ?? AppColors.primaryTurquoise;

    return Image.asset(
      imagePath,
      width: finalWidth,
      height: finalHeight,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback vers une icône stylisée si l'image n'existe pas
        return Container(
          width: finalWidth,
          height: finalHeight,
          decoration: BoxDecoration(
            color: backgroundColor ?? finalFallbackColor.withOpacity(0.2),
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            border: Border.all(
              color: finalFallbackColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            fallbackIcon,
            size: finalWidth != null && finalHeight != null
                ? (finalWidth < finalHeight ? finalWidth : finalHeight) * 0.6
                : 48,
            color: finalFallbackColor,
          ),
        );
      },
    );
  }
}

/// Widget spécialisé pour les avatars
class AvatarImageWidget extends StatelessWidget {
  final String? avatarId;
  final String? avatarPath;
  final double size;
  final bool showBorder;

  const AvatarImageWidget({
    super.key,
    this.avatarId,
    this.avatarPath,
    this.size = 80,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final path = avatarPath ?? 
        (avatarId != null 
            ? 'assets/images/avatars/$avatarId.png'
            : 'assets/images/avatars/hero_base.png');

    return AssetImageWidget(
      imagePath: path,
      size: size,
      fallbackIcon: Icons.person,
      fallbackColor: AppColors.primaryTurquoise,
      borderRadius: BorderRadius.circular(size / 2),
      backgroundColor: showBorder ? null : Colors.transparent,
    );
  }
}

/// Widget spécialisé pour les familiers/compagnons
class CompanionImageWidget extends StatelessWidget {
  final String? companionId;
  final String? companionPath;
  final double size;
  final bool animated;

  const CompanionImageWidget({
    super.key,
    this.companionId,
    this.companionPath,
    this.size = 60,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final path = companionPath ?? 
        (companionId != null 
            ? 'assets/images/companions/$companionId.png'
            : 'assets/images/companions/companion_1.png');

    Widget imageWidget = AssetImageWidget(
      imagePath: path,
      size: size,
      fallbackIcon: Icons.pets,
      fallbackColor: AppColors.gold,
      borderRadius: BorderRadius.circular(size / 2),
    );

    if (animated) {
      // Ajouter une animation de flottement si nécessaire
      return imageWidget;
    }

    return imageWidget;
  }
}

/// Widget spécialisé pour les items
class ItemImageWidget extends StatelessWidget {
  final String? itemId;
  final String? itemPath;
  final String? itemName; // Utilisé pour générer le chemin si itemId/itemPath non fourni
  final double size;
  final Color? rarityColor; // Couleur de bordure selon la rareté

  const ItemImageWidget({
    super.key,
    this.itemId,
    this.itemPath,
    this.itemName,
    this.size = 64,
    this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    String? path;
    
    if (itemPath != null) {
      path = itemPath;
    } else if (itemId != null) {
      path = 'assets/images/items/$itemId.png';
    } else if (itemName != null) {
      // Normaliser le nom pour créer le chemin
      final normalized = itemName!
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      path = 'assets/images/items/$normalized.png';
    } else {
      path = 'assets/images/items/default.png';
    }

    return Container(
      decoration: rarityColor != null
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: rarityColor!,
                width: 2,
              ),
            )
          : null,
      child: AssetImageWidget(
        imagePath: path!,
        size: size,
        fallbackIcon: Icons.inventory_2,
        fallbackColor: rarityColor ?? AppColors.primaryTurquoise,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

