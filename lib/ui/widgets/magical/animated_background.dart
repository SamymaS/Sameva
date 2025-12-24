import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Fond animé magique avec particules et dégradés
/// Crée la profondeur nécessaire pour le glassmorphism
class AnimatedMagicalBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const AnimatedMagicalBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<AnimatedMagicalBackground> createState() => _AnimatedMagicalBackgroundState();
}

class _AnimatedMagicalBackgroundState extends State<AnimatedMagicalBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dégradé de base animé
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.backgroundDeepViolet,
                    Color.lerp(
                      AppColors.backgroundDeepViolet,
                      AppColors.backgroundNightBlue,
                      _gradientController.value,
                    )!,
                    AppColors.backgroundNightBlue,
                  ],
                  stops: [
                    0.0,
                    _gradientController.value,
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),

        // Glows animés pour la profondeur
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Stack(
              children: [
                // Glow violet en haut à gauche
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondaryViolet.withOpacity(0.3 * _glowController.value),
                          AppColors.secondaryViolet.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Glow cyan en bas à droite
                Positioned(
                  bottom: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryTurquoise.withOpacity(0.2 * (1 - _glowController.value)),
                          AppColors.primaryTurquoise.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Particules magiques (optionnel)
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),

        // Overlay sombre pour lisibilité
        Container(
          color: Colors.black.withOpacity(0.2),
        ),

        // Contenu
        widget.child,
      ],
    );
  }
}

/// Peintre pour les particules magiques
class _ParticlePainter extends CustomPainter {
  final double animationValue;

  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final random = math.Random(42); // Seed fixe pour particules cohérentes

    for (int i = 0; i < 20; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height + animationValue * size.height * 2) % size.height;
      final opacity = (math.sin(animationValue * 2 * math.pi + i) + 1) / 2 * 0.3;
      final radius = 2 + random.nextDouble() * 3;

      paint.color = AppColors.primaryTurquoise.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

