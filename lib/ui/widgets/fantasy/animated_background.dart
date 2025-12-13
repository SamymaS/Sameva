import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Fond animé avec gradient et particules
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
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
        return Stack(
          children: [
            // Fond avec gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B0F18),
                    Color(0xFF111827),
                    Color(0xFF0B0F18),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Lueur centrale animée
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      (math.cos(_controller.value * 2 * math.pi) * 0.2).clamp(-1.0, 1.0),
                      ((math.sin(_controller.value * 2 * math.pi) * 0.1 - 0.2)).clamp(-1.0, 1.0),
                    ),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF1AA7EC).withOpacity(
                        (0.15 + 0.1 * (math.sin(_controller.value * 2 * math.pi) * 0.5 + 0.5)).clamp(0.0, 1.0),
                      ),
                      const Color(0xFF569CF6).withOpacity(
                        (0.08 + 0.05 * (math.sin(_controller.value * 2 * math.pi) * 0.5 + 0.5)).clamp(0.0, 1.0),
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Particules flottantes
            IgnorePointer(
              child: CustomPaint(
                painter: _BackgroundParticlesPainter(_controller.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackgroundParticlesPainter extends CustomPainter {
  final double animationValue;

  _BackgroundParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Vérifier que la taille est valide pour éviter NaN
    if (size.width <= 0 || size.height <= 0 || 
        !size.width.isFinite || !size.height.isFinite) {
      return;
    }

    final random = math.Random(123);

    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final offsetX = baseX + math.sin(animationValue * 2 * math.pi + i) * 20;
      final offsetY = baseY + math.cos(animationValue * 2 * math.pi + i) * 15;
      
      // Utiliser modulo avec vérification pour éviter NaN
      final x = offsetX.isFinite ? (offsetX % size.width).clamp(0.0, size.width) : baseX;
      final y = offsetY.isFinite ? (offsetY % size.height).clamp(0.0, size.height) : baseY;
      
      final opacity = (math.sin(animationValue * 2 * math.pi + i) * 0.15 + 0.15).clamp(0.0, 0.3);
      final particleSize = (random.nextDouble() * 2 + 1).clamp(1.0, 3.0);

      // Vérifier que les coordonnées sont valides avant de dessiner
      if (x.isFinite && y.isFinite && particleSize.isFinite) {
        final paint = Paint()
          ..color = const Color(0xFF1AA7EC).withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundParticlesPainter oldDelegate) => true;
}

