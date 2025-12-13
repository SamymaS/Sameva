import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Logo Sameva animé avec CustomPaint
class SamevaLogo extends StatefulWidget {
  final double size;
  final bool animated;
  const SamevaLogo({
    super.key,
    this.size = 100,
    this.animated = true,
  });

  @override
  State<SamevaLogo> createState() => _SamevaLogoState();
}

class _SamevaLogoState extends State<SamevaLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat();
      _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animated) {
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _LogoPainter(_glowAnimation.value),
          );
        },
      );
    } else {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _LogoPainter(1.0),
      );
    }
  }
}

class _LogoPainter extends CustomPainter {
  final double glowIntensity;

  _LogoPainter(this.glowIntensity);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Halo externe
    final haloPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.3 * glowIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.2, haloPaint);

    // Cercle principal
    final circlePaint = Paint()
      ..color = const Color(0xFF1AA7EC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Lettre "S" stylisée
    final textPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.15
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final sWidth = radius * 0.6;
    final sHeight = radius * 0.8;

    // Dessiner un "S" stylisé
    path.moveTo(center.dx - sWidth / 2, center.dy - sHeight / 2);
    path.quadraticBezierTo(
      center.dx,
      center.dy - sHeight / 2,
      center.dx + sWidth / 2,
      center.dy - sHeight / 4,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy,
      center.dx - sWidth / 2,
      center.dy + sHeight / 4,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy + sHeight / 2,
      center.dx + sWidth / 2,
      center.dy + sHeight / 2,
    );

    canvas.drawPath(path, textPaint);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => true;
}

