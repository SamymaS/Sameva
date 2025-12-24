import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../magical/animated_glow.dart';

/// FAB Central Flottant - Sphère/Rune dorée
/// Style "Moderne Éthérée" avec animation de respiration
class FloatingFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  const FloatingFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  @override
  State<FloatingFAB> createState() => _FloatingFABState();
}

class _FloatingFABState extends State<FloatingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGlow(
      glowColor: AppColors.gold,
      minOpacity: 0.3,
      maxOpacity: 0.6,
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_breathingController.value * 0.05), // Respiration subtile
            child: Container(
              width: 56,
              height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Dégradé radial or doux
              gradient: RadialGradient(
                colors: [
                  AppColors.gold,
                  AppColors.gold.withOpacity(0.7),
                  const Color(0xFFFFF8DC), // Jaune pâle au centre
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              // Ombre diffuse pour lévitation
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(28),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

