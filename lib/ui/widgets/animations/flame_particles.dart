import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget de particules animées (alternative simple à Flame)
/// Utilise CustomPaint pour des performances optimales
class FlameParticlesWidget extends StatefulWidget {
  final Color particleColor;
  final int particleCount;
  final double size;
  final double speed;

  const FlameParticlesWidget({
    super.key,
    this.particleColor = const Color(0xFF1AA7EC),
    this.particleCount = 20,
    this.size = 200,
    this.speed = 1.0,
  });

  @override
  State<FlameParticlesWidget> createState() => _FlameParticlesWidgetState();
}

class _FlameParticlesWidgetState extends State<FlameParticlesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ParticleData> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Initialiser les particules
    final random = math.Random();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _ParticleData(
          x: random.nextDouble() * widget.size,
          y: random.nextDouble() * widget.size,
          vx: (random.nextDouble() - 0.5) * widget.speed * 2,
          vy: (random.nextDouble() - 0.5) * widget.speed * 2,
          radius: 2 + random.nextDouble() * 3,
          opacity: 0.3 + random.nextDouble() * 0.7,
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlesPainter(
              particles: _particles,
              progress: _controller.value,
              color: widget.particleColor,
              size: widget.size,
            ),
          );
        },
      ),
    );
  }
}

class _ParticleData {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double opacity;

  _ParticleData({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double progress;
  final Color color;
  final double size;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Calculer la nouvelle position avec effet de pulsation
      final time = progress * 2 * math.pi;
      final offsetX = particle.x + particle.vx * math.sin(time) * 10;
      final offsetY = particle.y + particle.vy * math.cos(time) * 10;

      // Effet de pulsation pour l'opacité et la taille
      final pulse = (math.sin(time + particle.x * 0.1) + 1) / 2;
      final currentOpacity = particle.opacity * (0.5 + pulse * 0.5);
      final currentRadius = particle.radius * (0.8 + pulse * 0.4);

      paint.color = color.withOpacity(currentOpacity);
      canvas.drawCircle(
        Offset(offsetX % size.width, offsetY % size.height),
        currentRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

