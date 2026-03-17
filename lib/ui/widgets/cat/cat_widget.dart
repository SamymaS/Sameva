import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Couleur de pelage selon la race.
Color catBodyColor(String race) => switch (race) {
      'michi'  => const Color(0xFFD8B4FE), // Lavande pastel
      'lune'   => const Color(0xFFE2E8F0), // Blanc nacré
      'braise' => const Color(0xFFFB923C), // Orange roux
      'neige'  => const Color(0xFFBAE6FD), // Bleu glacier
      'cosmos' => const Color(0xFF7C3AED), // Violet nuit
      'sakura' => const Color(0xFFFDA4AF), // Rose cerisier
      _        => AppColors.primaryVioletLight,
    };

/// Couleur intérieure des oreilles (plus claire).
Color _earInnerColor(Color body) =>
    Color.lerp(body, Colors.white, 0.45)!;

/// Widget affichant le chat compagnon du joueur.
///
/// Paramètres :
/// - [race] : race du chat (michi/lune/braise/neige/cosmos/sakura)
/// - [equippedHat] : identifiant du chapeau équipé (null = aucun)
/// - [size] : taille totale du widget (carré)
/// - [mood] : expression (happy/neutral/sad/excited/sleepy)
class CatWidget extends StatefulWidget {
  final String race;
  final String? equippedHat;
  final double size;
  final String mood;

  const CatWidget({
    super.key,
    required this.race,
    this.equippedHat,
    this.size = 160,
    this.mood = 'happy',
  });

  @override
  State<CatWidget> createState() => _CatWidgetState();
}

class _CatWidgetState extends State<CatWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sway;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _sway = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = catBodyColor(widget.race);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _sway,
        builder: (_, __) => Transform.rotate(
          angle: _sway.value,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Corps + tête + détails
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CatPainter(
                  bodyColor: color,
                  innerEarColor: _earInnerColor(color),
                  mood: widget.mood,
                ),
              ),
              // Chapeau (cosmétique)
              if (widget.equippedHat != null)
                Positioned(
                  top: widget.size * 0.01,
                  child: _HatWidget(
                    hat: widget.equippedHat!,
                    size: widget.size * 0.45,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — dessin du chat
// ─────────────────────────────────────────────────────────────────────────────

class _CatPainter extends CustomPainter {
  final Color bodyColor;
  final Color innerEarColor;
  final String mood;

  const _CatPainter({
    required this.bodyColor,
    required this.innerEarColor,
    required this.mood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = bodyColor;

    // ── Corps ──────────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.66),
        width: w * 0.68,
        height: h * 0.52,
      ),
      bodyPaint,
    );

    // ── Tête ───────────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.50, h * 0.36), w * 0.30, bodyPaint);

    // ── Oreilles ───────────────────────────────────────────────────────────
    _drawEar(canvas, bodyPaint,
        tip: Offset(w * 0.28, h * 0.08),
        base1: Offset(w * 0.18, h * 0.24),
        base2: Offset(w * 0.38, h * 0.22));
    _drawEar(canvas, bodyPaint,
        tip: Offset(w * 0.72, h * 0.08),
        base1: Offset(w * 0.62, h * 0.22),
        base2: Offset(w * 0.82, h * 0.24));

    // Intérieur des oreilles
    final innerPaint = Paint()..color = innerEarColor;
    _drawEar(canvas, innerPaint,
        tip: Offset(w * 0.28, h * 0.12),
        base1: Offset(w * 0.22, h * 0.23),
        base2: Offset(w * 0.36, h * 0.22));
    _drawEar(canvas, innerPaint,
        tip: Offset(w * 0.72, h * 0.12),
        base1: Offset(w * 0.64, h * 0.22),
        base2: Offset(w * 0.78, h * 0.23));

    // ── Queue ──────────────────────────────────────────────────────────────
    final tailPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    final tail = Path()
      ..moveTo(w * 0.76, h * 0.78)
      ..cubicTo(w * 1.08, h * 0.82, w * 1.10, h * 0.52, w * 0.84, h * 0.55);
    canvas.drawPath(tail, tailPaint);

    // ── Yeux ───────────────────────────────────────────────────────────────
    _drawEyes(canvas, size, mood);

    // ── Nez ────────────────────────────────────────────────────────────────
    final nosePaint = Paint()..color = const Color(0xFFFFB6C1);
    final nose = Path()
      ..moveTo(w * 0.47, h * 0.42)
      ..lineTo(w * 0.53, h * 0.42)
      ..lineTo(w * 0.50, h * 0.45)
      ..close();
    canvas.drawPath(nose, nosePaint);

    // ── Bouche ─────────────────────────────────────────────────────────────
    _drawMouth(canvas, size, mood);

    // ── Moustaches ─────────────────────────────────────────────────────────
    _drawWhiskers(canvas, size);
  }

  void _drawEar(Canvas canvas, Paint paint,
      {required Offset tip,
      required Offset base1,
      required Offset base2}) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawEyes(Canvas canvas, Size size, String mood) {
    final w = size.width;
    final h = size.height;

    final pupilPaint = Paint()..color = const Color(0xFF1A0A00);
    final shinePaint = Paint()..color = Colors.white;

    switch (mood) {
      case 'excited':
        // Yeux en forme de ★ — on dessine des cercles plus grands
        canvas.drawCircle(Offset(w * 0.37, h * 0.34), w * 0.065, pupilPaint);
        canvas.drawCircle(Offset(w * 0.63, h * 0.34), w * 0.065, pupilPaint);
        canvas.drawCircle(Offset(w * 0.39, h * 0.31), w * 0.025, shinePaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.31), w * 0.025, shinePaint);

      case 'sad':
        // Demi-cercles vers le bas (yeux tombants)
        final sadEye = Paint()..color = const Color(0xFF1A0A00);
        final rectL = Rect.fromCenter(
            center: Offset(w * 0.37, h * 0.345), width: w * 0.10, height: w * 0.10);
        canvas.drawArc(rectL, 0, math.pi, true, sadEye);
        final rectR = Rect.fromCenter(
            center: Offset(w * 0.63, h * 0.345), width: w * 0.10, height: w * 0.10);
        canvas.drawArc(rectR, 0, math.pi, true, sadEye);

      case 'sleepy':
        // Demi-cercles (yeux mi-clos)
        final sleepPaint = Paint()..color = const Color(0xFF1A0A00);
        final rectL = Rect.fromCenter(
            center: Offset(w * 0.37, h * 0.34), width: w * 0.10, height: w * 0.10);
        canvas.drawArc(rectL, math.pi, math.pi, true, sleepPaint);
        final rectR = Rect.fromCenter(
            center: Offset(w * 0.63, h * 0.34), width: w * 0.10, height: w * 0.10);
        canvas.drawArc(rectR, math.pi, math.pi, true, sleepPaint);

      default:
        // Yeux ronds (happy / neutral)
        canvas.drawCircle(Offset(w * 0.37, h * 0.34), w * 0.055, pupilPaint);
        canvas.drawCircle(Offset(w * 0.63, h * 0.34), w * 0.055, pupilPaint);
        canvas.drawCircle(Offset(w * 0.39, h * 0.31), w * 0.020, shinePaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.31), w * 0.020, shinePaint);
    }
  }

  void _drawMouth(Canvas canvas, Size size, String mood) {
    final w = size.width;
    final h = size.height;

    final mouthPaint = Paint()
      ..color = const Color(0xFF7B5563)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (mood == 'sad') {
      // Bouche triste
      path
        ..moveTo(w * 0.43, h * 0.48)
        ..cubicTo(w * 0.47, h * 0.46, w * 0.53, h * 0.46, w * 0.57, h * 0.48);
    } else {
      // Bouche souriante
      path
        ..moveTo(w * 0.43, h * 0.47)
        ..cubicTo(w * 0.47, h * 0.50, w * 0.53, h * 0.50, w * 0.57, h * 0.47);
    }
    canvas.drawPath(path, mouthPaint);
  }

  void _drawWhiskers(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wp = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gauche
    canvas.drawLine(Offset(w * 0.08, h * 0.43), Offset(w * 0.43, h * 0.44), wp);
    canvas.drawLine(Offset(w * 0.08, h * 0.46), Offset(w * 0.43, h * 0.46), wp);
    canvas.drawLine(Offset(w * 0.08, h * 0.49), Offset(w * 0.43, h * 0.48), wp);

    // Droite
    canvas.drawLine(Offset(w * 0.92, h * 0.43), Offset(w * 0.57, h * 0.44), wp);
    canvas.drawLine(Offset(w * 0.92, h * 0.46), Offset(w * 0.57, h * 0.46), wp);
    canvas.drawLine(Offset(w * 0.92, h * 0.49), Offset(w * 0.57, h * 0.48), wp);
  }

  @override
  bool shouldRepaint(_CatPainter old) =>
      old.bodyColor != bodyColor ||
      old.innerEarColor != innerEarColor ||
      old.mood != mood;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget chapeau (cosmétique)
// ─────────────────────────────────────────────────────────────────────────────

class _HatWidget extends StatelessWidget {
  final String hat;
  final double size;

  const _HatWidget({required this.hat, required this.size});

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = _hatData(hat);
    return Container(
      width: size,
      height: size * 0.55,
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.45),
        textAlign: TextAlign.center,
      ),
    );
  }

  (String, Color) _hatData(String hat) => switch (hat) {
        'wizard_hat'  => ('🧙', AppColors.primaryViolet),
        'crown'       => ('👑', AppColors.gold),
        'bow'         => ('🎀', AppColors.rosePastel),
        'party_hat'   => ('🎉', AppColors.crystalBlue),
        'santa_hat'   => ('🎅', Colors.red),
        _             => ('🎩', AppColors.textMuted),
      };
}
