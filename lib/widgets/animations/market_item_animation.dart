import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation pour les items du marché avec effet de rareté
class AnimatedMarketItem extends StatefulWidget {
  final Widget child;
  final String rarity; // common, uncommon, rare, epic, legendary, mythic
  final VoidCallback? onTap;
  final bool isSelected;

  const AnimatedMarketItem({
    super.key,
    required this.child,
    this.rarity = 'common',
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<AnimatedMarketItem> createState() => _AnimatedMarketItemState();
}

class _AnimatedMarketItemState extends State<AnimatedMarketItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

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
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isSelected || widget.rarity != 'common') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedMarketItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.repeat(reverse: true);
      } else if (!_isHovered && widget.rarity == 'common') {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          if (!_controller.isAnimating) {
            _controller.repeat(reverse: true);
          }
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          if (!widget.isSelected && widget.rarity == 'common') {
            _controller.stop();
            _controller.reset();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHovered ? _scaleAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _rarityColor.withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _rarityColor.withOpacity(_glowAnimation.value * 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animation de particules pour les items légendaires
class RarityParticles extends StatefulWidget {
  final String rarity;
  final double size;

  const RarityParticles({
    super.key,
    required this.rarity,
    this.size = 100,
  });

  @override
  State<RarityParticles> createState() => _RarityParticlesState();
}

class _RarityParticlesState extends State<RarityParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  Color get _rarityColor {
    switch (widget.rarity.toLowerCase()) {
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
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Créer des particules
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble() * widget.size,
          y: random.nextDouble() * widget.size,
          speed: 0.5 + random.nextDouble() * 0.5,
          angle: random.nextDouble() * 2 * math.pi,
        ),
      );
    }
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            color: _rarityColor,
          ),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double angle;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final offsetX = particle.x + math.cos(particle.angle) * particle.speed * progress * 20;
      final offsetY = particle.y + math.sin(particle.angle) * particle.speed * progress * 20;

      // Effet de pulsation
      final radius = 2 + math.sin(progress * 2 * math.pi + particle.angle) * 1;
      final opacity = 0.3 + math.sin(progress * 2 * math.pi + particle.angle) * 0.4;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(offsetX % size.width, offsetY % size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}




