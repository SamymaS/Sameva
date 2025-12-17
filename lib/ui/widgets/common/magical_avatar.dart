import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../../utils/assets_manager.dart';

/// Widget Avatar avec effets magiques - Inspiré du design Figma Sanctuary
/// Utilise de vrais assets au lieu d'emojis
class MagicalAvatar extends StatefulWidget {
  final String? avatarPath; // Chemin de l'image de l'avatar
  final double size;
  final String? companionPath; // Chemin de l'image du familier
  final bool showMagicCircle;
  final String? avatarId; // ID de l'avatar (utilisé pour obtenir le chemin)
  final String? companionId; // ID du familier (utilisé pour obtenir le chemin)

  const MagicalAvatar({
    super.key,
    this.avatarPath,
    this.avatarId,
    this.size = 120,
    this.companionPath,
    this.companionId,
    this.showMagicCircle = true,
  });

  @override
  State<MagicalAvatar> createState() => _MagicalAvatarState();
}

class _MagicalAvatarState extends State<MagicalAvatar>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _companionController;
  late AnimationController _sparkleController;
  late AnimationController _circleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _companionController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _circleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    _companionController.dispose();
    _sparkleController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Magic Circle (rotating)
          if (widget.showMagicCircle)
            AnimatedBuilder(
              animation: _circleController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _circleController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size * 1.6, widget.size * 1.6),
                    painter: _MagicCirclePainter(),
                  ),
                );
              },
            ),

          // Outer magical aura
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryTurquoise.withOpacity(
                        0.3 + _glowController.value * 0.3,
                      ),
                      AppColors.secondaryViolet.withOpacity(
                        0.2 + _glowController.value * 0.2,
                      ),
                      AppColors.gold.withOpacity(
                        0.1 + _glowController.value * 0.1,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Main character
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -10 * _floatController.value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Character glow halo
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          width: widget.size * 0.8,
                          height: widget.size * 0.3,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(40),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.secondaryViolet.withOpacity(
                                  0.4 + _glowController.value * 0.3,
                                ),
                                AppColors.primaryTurquoise.withOpacity(
                                  0.4 + _glowController.value * 0.3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Character image (avatar)
                    _AssetImageWidget(
                      imagePath: widget.avatarPath ?? 
                          AssetsManager.getAvatarPath(widget.avatarId),
                      size: widget.size * 0.6,
                      fallbackIcon: Icons.person,
                      fallbackColor: AppColors.primaryTurquoise,
                    ),
                  ],
                ),
              );
            },
          ),

          // Companion (Familiar) - Image au lieu d'emoji
          if (widget.companionPath != null || widget.companionId != null)
            AnimatedBuilder(
              animation: _companionController,
              builder: (context, child) {
                return Positioned(
                  right: -widget.size * 0.3,
                  top: widget.size * 0.1,
                  child: Transform.translate(
                    offset: Offset(
                      5 * math.sin(_companionController.value * 2 * math.pi),
                      -15 * _companionController.value,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Companion glow
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: widget.size * 0.5,
                              height: widget.size * 0.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.gold.withOpacity(
                                      0.3 + _glowController.value * 0.3,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        _AssetImageWidget(
                          imagePath: widget.companionPath ?? 
                              AssetsManager.getCompanionPath(widget.companionId),
                          size: widget.size * 0.4,
                          fallbackIcon: Icons.pets,
                          fallbackColor: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Sparkles around character
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                final angle = (index * 45) * math.pi / 180;
                final distance = widget.size * 0.6;
                final progress = (_sparkleController.value + index * 0.125) % 1.0;
                
                return Positioned(
                  left: widget.size +
                      math.cos(angle) * distance * (1 - progress * 0.5),
                  top: widget.size +
                      math.sin(angle) * distance * (1 - progress * 0.5),
                  child: Opacity(
                    opacity: progress < 0.5 ? progress * 2 : (1 - progress) * 2,
                    child: Transform.scale(
                      scale: progress < 0.5 ? progress * 2 : (1 - progress) * 2,
                      child: Transform.rotate(
                        angle: progress * math.pi,
                        child: Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _MagicCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Outer circle
    final outerPaint = Paint()
      ..color = AppColors.primaryTurquoise.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, outerPaint);
    final innerPaint = Paint()
      ..color = AppColors.primaryTurquoise.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 15, innerPaint);

    // Pentagram
    final pentagramPaint = Paint()
      ..color = AppColors.primaryTurquoise.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final points = List.generate(5, (i) {
      final angle = (i * 72 - 90) * math.pi / 180;
      return Offset(
        center.dx + math.cos(angle) * (radius - 20),
        center.dy + math.sin(angle) * (radius - 20),
      );
    });

    path.moveTo(points[0].dx, points[0].dy);
    path.lineTo(points[2].dx, points[2].dy);
    path.lineTo(points[4].dx, points[4].dy);
    path.lineTo(points[1].dx, points[1].dy);
    path.lineTo(points[3].dx, points[3].dy);
    path.close();

    canvas.drawPath(path, pentagramPaint);

    // Runes around - simplified to circles
    final runePaint = Paint()
      ..color = AppColors.primaryTurquoise.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x = center.dx + math.cos(angle) * (radius - 10);
      final y = center.dy + math.sin(angle) * (radius - 10);
      canvas.drawCircle(Offset(x, y), 3, runePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget pour afficher un asset avec fallback
class _AssetImageWidget extends StatelessWidget {
  final String imagePath;
  final double size;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const _AssetImageWidget({
    required this.imagePath,
    required this.size,
    required this.fallbackIcon,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback vers une icône si l'image n'existe pas
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fallbackColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: fallbackColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            fallbackIcon,
            size: size * 0.6,
            color: fallbackColor,
          ),
        );
      },
    );
  }
}

