import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget RarityBorder - Bordure avec effet de rareté
/// Basé sur le design Figma avec glows pour les raretés épiques
class RarityBorder extends StatefulWidget {
  final String rarity; // 'common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic'
  final Widget child;
  final bool withGlow;
  final double borderWidth;
  final BorderRadius? borderRadius;

  const RarityBorder({
    super.key,
    required this.rarity,
    required this.child,
    this.withGlow = true,
    this.borderWidth = 2.0,
    this.borderRadius,
  });

  @override
  State<RarityBorder> createState() => _RarityBorderState();
}

class _RarityBorderState extends State<RarityBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color _getRarityColor() {
    return AppColors.getRarityColor(widget.rarity);
  }

  bool _shouldAnimateGlow() {
    return widget.withGlow && AppColors.shouldGlow(widget.rarity);
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor();
    final shouldGlow = _shouldAnimateGlow();
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12.0);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: rarityColor,
              width: widget.borderWidth,
            ),
            boxShadow: shouldGlow
                ? [
                    BoxShadow(
                      color: rarityColor.withOpacity(_glowAnimation.value),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                    if (widget.rarity.toLowerCase() == 'legendary' ||
                        widget.rarity.toLowerCase() == 'mythic')
                      BoxShadow(
                        color: rarityColor.withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 25,
                        spreadRadius: 0,
                      ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: widget.child,
          ),
        );
      },
    );
  }
}

