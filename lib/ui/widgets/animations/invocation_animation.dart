import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation d'invocation avec effet de particules
class InvocationAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final String rarity; // common, uncommon, rare, epic, legendary, mythic
  const InvocationAnimation({
    super.key,
    this.onComplete,
    this.rarity = 'rare',
  });

  @override
  State<InvocationAnimation> createState() => _InvocationAnimationState();
}

class _InvocationAnimationState extends State<InvocationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  Color get _rarityColor {
    switch (widget.rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF9CA3AF);
      case 'uncommon':
        return const Color(0xFF22C55E);
      case 'rare':
        return const Color(0xFF60A5FA);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'legendary':
        return const Color(0xFFF59E0B);
      case 'mythic':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF60A5FA);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi * 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Halo externe (pulse)
            Transform.scale(
              scale: _scaleAnimation.value * 1.5,
              child: Opacity(
                opacity: (1 - _controller.value).clamp(0.0, 0.5),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _rarityColor.withOpacity(0.6),
                        _rarityColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Cercle principal rotatif
            Transform.rotate(
              angle: _rotationAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _rarityColor,
                      width: 4,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        _rarityColor.withOpacity(0.3),
                        _rarityColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: _rarityColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

