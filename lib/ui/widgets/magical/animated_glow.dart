import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget avec glow animé pour attirer l'attention
class AnimatedGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const AnimatedGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.primaryTurquoise,
    this.minOpacity = 0.3,
    this.maxOpacity = 0.8,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedGlow> createState() => _AnimatedGlowState();
}

class _AnimatedGlowState extends State<AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value * 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

