import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation d'avatar idle (remplace Rive temporairement)
class AvatarIdleAnimation extends StatefulWidget {
  final double size;
  const AvatarIdleAnimation({super.key, this.size = 200});

  @override
  State<AvatarIdleAnimation> createState() => _AvatarIdleAnimationState();
}

class _AvatarIdleAnimationState extends State<AvatarIdleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathingAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _breathingAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _AvatarPainter(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final double animationValue;

  _AvatarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Halo lumineux (pulse) - effet fantasy adouci
    final haloOpacity = (math.sin(animationValue * 2 * math.pi) * 0.2 + 0.6).clamp(0.0, 1.0);
    
    // Halo externe (plus doux)
    final outerHaloPaint = Paint()
      ..color = const Color(0xFF1AA7EC).withOpacity(haloOpacity * 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.4, outerHaloPaint);
    
    // Halo interne
    final innerHaloPaint = Paint()
      ..color = const Color(0xFF569CF6).withOpacity(haloOpacity * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.2, innerHaloPaint);

    // Corps de l'avatar avec gradient
    final bodyGradient = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF569CF6),
          Color(0xFF1AA7EC),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 0.7),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.7, bodyGradient);
    
    // Bordure lumineuse
    final bodyBorderPaint = Paint()
      ..color = const Color(0xFF1AA7EC).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.7, bodyBorderPaint);

    // Tête avec gradient doré (fantasy)
    final headGradient = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFF59E0B),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(center.dx, center.dy - radius * 0.3),
          radius: radius * 0.4,
        ),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.3),
      radius * 0.4,
      headGradient,
    );
    
    // Bordure dorée
    final headBorderPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.3),
      radius * 0.4,
      headBorderPaint,
    );

    // Yeux (clignotement)
    final eyeOpacity = animationValue > 0.9 && animationValue < 0.95 ? 0.0 : 1.0;
    final eyePaint = Paint()
      ..color = Colors.white.withOpacity(eyeOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.15, center.dy - radius * 0.35),
      radius * 0.08,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.15, center.dy - radius * 0.35),
      radius * 0.08,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) => true;
}

