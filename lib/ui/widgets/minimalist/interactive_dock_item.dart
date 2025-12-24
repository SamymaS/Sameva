import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Élément interactif du Dock avec micro-interactions
class InteractiveDockItem extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const InteractiveDockItem({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<InteractiveDockItem> createState() => _InteractiveDockItemState();
}

class _InteractiveDockItemState extends State<InteractiveDockItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive
                    ? AppColors.primaryTurquoise.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône avec transition de couleur
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      key: ValueKey(widget.isActive),
                      size: 24,
                      color: widget.isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Point lumineux pour l'état actif avec animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.isActive ? 4 : 0,
                    height: widget.isActive ? 4 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTurquoise,
                      shape: BoxShape.circle,
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primaryTurquoise.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

