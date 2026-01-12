import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation de halo avec particules flottantes
class ParticlesHalo extends StatefulWidget {
  final Color color;
  final double size;
  const ParticlesHalo({
    super.key,
    this.color = const Color(0xFF1AA7EC),
    this.size = 100,
  });

  @override
  State<ParticlesHalo> createState() => _ParticlesHaloState();
}

class _ParticlesHaloState extends State<ParticlesHalo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
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
          painter: _HaloPainter(_controller.value, widget.color),
        );
      },
    );
  }
}

class _HaloPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _HaloPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Halo principal (pulse)
    final haloOpacity = (math.sin(animationValue * 2 * math.pi) * 0.3 + 0.7).clamp(0.0, 1.0);
    final haloPaint = Paint()
      ..color = color.withOpacity(haloOpacity * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, haloPaint);

    // Particules orbitantes
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + animationValue * 2 * math.pi;
      final x = center.dx + math.cos(angle) * radius * 0.7;
      final y = center.dy + math.sin(angle) * radius * 0.7;

      final particleOpacity = (math.sin(animationValue * 4 * math.pi + i) * 0.5 + 0.5).clamp(0.0, 1.0);
      final particlePaint = Paint()
        ..color = color.withOpacity(particleOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 3, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) => true;
}

