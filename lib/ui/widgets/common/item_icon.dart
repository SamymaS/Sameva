import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../data/models/item_model.dart';
import '../../theme/app_colors.dart';

/// Widget d'icône d'item universel.
///
/// Affiche l'asset SVG pixel art si [item.assetPath] est défini,
/// sinon replie sur l'icône Material avec la couleur de rareté.
///
/// Usage :
/// ```dart
/// ItemIcon(item: myItem, size: 48)
/// ItemIcon(item: myItem, size: 32, showRarityGlow: true)
/// ItemIcon(item: myItem, size: 64, showBackground: true)
/// ```
class ItemIcon extends StatelessWidget {
  final Item item;
  final double size;
  final bool showBackground;
  final bool showRarityGlow;
  final bool showRarityBorder;
  final double borderRadius;

  const ItemIcon({
    super.key,
    required this.item,
    this.size = 48,
    this.showBackground = false,
    this.showRarityGlow = false,
    this.showRarityBorder = false,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.getRarityColor(item.rarity.name);
    final iconWidget = _buildIcon(rarityColor);

    if (!showBackground && !showRarityGlow && !showRarityBorder) {
      return SizedBox(width: size, height: size, child: iconWidget);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground
            ? rarityColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showRarityBorder
            ? Border.all(
                color: rarityColor.withValues(alpha: 0.7),
                width: 1.5,
              )
            : null,
        boxShadow: showRarityGlow
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: iconWidget,
        ),
      ),
    );
  }

  Widget _buildIcon(Color rarityColor) {
    if (item.assetPath != null) {
      return SvgPicture.asset(
        item.assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallbackIcon(rarityColor),
      );
    }
    return _fallbackIcon(rarityColor);
  }

  Widget _fallbackIcon(Color rarityColor) {
    return Icon(
      item.getIcon(),
      size: size * 0.65,
      color: rarityColor,
    );
  }
}

// ─── Variante carte (pour inventaire/marché) ──────────────────────────────────

/// Carte d'item complète avec icône, nom et badge de rareté.
class ItemCard extends StatelessWidget {
  final Item item;
  final double cardSize;
  final VoidCallback? onTap;
  final bool selected;

  const ItemCard({
    super.key,
    required this.item,
    this.cardSize = 72,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.getRarityColor(item.rarity.name);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: cardSize,
        decoration: BoxDecoration(
          color: selected
              ? rarityColor.withValues(alpha: 0.22)
              : rarityColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? rarityColor
                : rarityColor.withValues(alpha: 0.35),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: ItemIcon(
                item: item,
                size: cardSize - 28,
              ),
            ),
            // Badge rareté + quantité
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.18),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rarityColor,
                    ),
                  ),
                  if (item.stackable && item.quantity > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '×${item.quantity}',
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Variante slot d'équipement ───────────────────────────────────────────────

/// Slot d'équipement vide ou rempli, utilisé dans la page Avatar.
class EquipmentSlotWidget extends StatelessWidget {
  final Item? item;
  final IconData emptyIcon;
  final String label;
  final double size;
  final VoidCallback? onTap;

  const EquipmentSlotWidget({
    super.key,
    this.item,
    required this.emptyIcon,
    required this.label,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = item != null
        ? AppColors.getRarityColor(item!.rarity.name)
        : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: item != null ? 0.15 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rarityColor.withValues(alpha: item != null ? 0.65 : 0.22),
                width: 1.5,
              ),
              boxShadow: item != null
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: item != null
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: ItemIcon(item: item!, size: size - 12),
                  )
                : Icon(
                    emptyIcon,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    size: size * 0.42,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            item != null
                ? (item!.name.length > 8
                    ? '${item!.name.substring(0, 7)}…'
                    : item!.name)
                : label,
            style: TextStyle(
              color: item != null ? rarityColor : AppColors.textMuted,
              fontSize: 8.5,
              fontWeight:
                  item != null ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
