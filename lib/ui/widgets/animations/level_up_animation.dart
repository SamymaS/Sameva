import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation de level up avec particules
class LevelUpAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  const LevelUpAnimation({super.key, this.onComplete});

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Controller principal
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller pour les particules
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );

    // Générer les particules
    _generateParticles();

    _mainController.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    _particleController.repeat();
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        angle: (i / 30) * 2 * math.pi,
        distance: 100 + math.Random().nextDouble() * 50,
        speed: 0.5 + math.Random().nextDouble() * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Particules
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(_particles, _particleController.value),
            );
          },
        ),
        // Texte "LEVEL UP"
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class Particle {
  final double angle;
  final double distance;
  final double speed;
  double currentDistance = 0;

  Particle({
    required this.angle,
    required this.distance,
    required this.speed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      particle.currentDistance = particle.distance * animationValue;
      final x = center.dx + math.cos(particle.angle) * particle.currentDistance;
      final y = center.dy + math.sin(particle.angle) * particle.currentDistance;

      final opacity = (1 - animationValue).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

