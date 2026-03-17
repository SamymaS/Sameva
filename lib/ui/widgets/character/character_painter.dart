import 'package:flutter/material.dart';
import '../../../data/models/character_model.dart';

/// CustomPainter du personnage Sameva avec calques superposés.
///
/// Ordre de dessin (bas → haut) :
///   1. Aura   2. Chaussures   3. Jambes/Pantalon   4. Bras
///   5. Torse/Tenue   6. Cou   7. Cheveux (arrière)
///   8. Tête   9. Cheveux (avant)   10. Visage   11. Chapeau
///
/// Utiliser avec : CustomPaint(size: const Size(140, 290), painter: CharacterPainter(...))
class CharacterPainter extends CustomPainter {
  final CharacterAppearance appearance;
  final Color outfitColor;
  final Color pantsColor;
  final Color shoesColor;
  final Color hatColor;
  final int hatStyle; // 0=aucun 1=conique 2=couronne 3=bonnet 4=bandana
  final Color? auraColor;

  static const Color _defaultOutfit = Color(0xFF4FD1C5);
  static const Color _defaultPants = Color(0xFF2D3748);
  static const Color _defaultShoes = Color(0xFF3D2B1A);
  static const Color _defaultHat = Color(0xFF805AD5);

  const CharacterPainter({
    required this.appearance,
    this.outfitColor = _defaultOutfit,
    this.pantsColor = _defaultPants,
    this.shoesColor = _defaultShoes,
    this.hatColor = _defaultHat,
    this.hatStyle = 0,
    this.auraColor,
  });

  // ── Helpers Paint ──────────────────────────────────────────────────────────

  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;

  Paint _stroke(Color c, [double w = 1.5]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  Color _darker(Color c, [double amount = 0.25]) =>
      Color.lerp(c, Colors.black, amount)!;

  // ── Paint entry ────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final isFemale = appearance.gender == CharacterGender.female;

    final skin = appearance.skinTone.color;
    final skinDark = _darker(skin, 0.2);
    final hair = appearance.hairColor;
    final hairDark = _darker(hair, 0.3);
    final outfitDark = _darker(outfitColor);
    final pantsDark = _darker(pantsColor);
    final shoesDark = _darker(shoesColor, 0.3);

    // 1. Aura
    if (auraColor != null) {
      canvas.drawCircle(
        Offset(cx, size.height * 0.46),
        size.width * 0.6,
        _fill(auraColor!.withValues(alpha: 0.13)),
      );
      canvas.drawCircle(
        Offset(cx, size.height * 0.46),
        size.width * 0.6,
        _stroke(auraColor!.withValues(alpha: 0.45), 2.5),
      );
    }

    // 2. Chaussures (dessinées avant les jambes)
    _drawShoes(canvas, cx, size, isFemale, shoesColor, shoesDark);

    // 3. Jambes / Pantalon
    _drawLegs(canvas, cx, size, isFemale, pantsColor, pantsDark);

    // 4. Bras
    _drawArms(canvas, cx, size, isFemale, skin, skinDark);

    // 5. Torse / Tenue
    _drawTorso(canvas, cx, size, isFemale, outfitColor, outfitDark);

    // 6. Cou
    _drawNeck(canvas, cx, size, isFemale, skin, skinDark);

    // 7. Cheveux arrière (derrière la tête)
    _drawHairBack(canvas, cx, size, isFemale, hair, hairDark);

    // 8. Tête
    _drawHead(canvas, cx, size, isFemale, skin, skinDark);

    // 9. Cheveux avant (sur la tête)
    _drawHairFront(canvas, cx, size, isFemale, hair, hairDark);

    // 10. Visage
    _drawFace(canvas, cx, size, isFemale, skin, skinDark);

    // 11. Chapeau
    _drawHat(canvas, cx, size, hatColor, hatStyle);
  }

  // ── HEAD ───────────────────────────────────────────────────────────────────

  void _drawHead(Canvas canvas, double cx, Size size, bool isFemale,
      Color skin, Color skinDark) {
    final center = Offset(cx, size.height * 0.135);
    final r = size.width * 0.176;

    if (isFemale) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 1.88, height: r * 2.12),
        _fill(skin),
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 1.88, height: r * 2.12),
        _stroke(skinDark),
      );
    } else {
      final rrect = RRect.fromRectAndCorners(
        Rect.fromCenter(center: center, width: r * 1.98, height: r * 1.94),
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(12),
        bottomRight: const Radius.circular(12),
      );
      canvas.drawRRect(rrect, _fill(skin));
      canvas.drawRRect(rrect, _stroke(skinDark));
    }
  }

  // ── NECK ───────────────────────────────────────────────────────────────────

  void _drawNeck(Canvas canvas, double cx, Size size, bool isFemale,
      Color skin, Color skinDark) {
    final hw = isFemale ? size.width * 0.088 : size.width * 0.103;
    final top = size.height * 0.213;
    final h = size.height * 0.072;
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - hw, top, hw * 2, h),
      const Radius.circular(4),
    );
    canvas.drawRRect(neck, _fill(skin));
    canvas.drawRRect(neck, _stroke(skinDark));
  }

  // ── TORSO / OUTFIT ─────────────────────────────────────────────────────────

  void _drawTorso(Canvas canvas, double cx, Size size, bool isFemale,
      Color outfit, Color outfitDark) {
    final shoulderY = size.height * 0.286;
    final torsoBot = size.height * 0.590;

    if (isFemale) {
      final sL = cx - size.width * 0.268;
      final sR = cx + size.width * 0.268;
      final wL = cx - size.width * 0.192;
      final wR = cx + size.width * 0.192;
      final hL = cx - size.width * 0.292;
      final hR = cx + size.width * 0.292;
      final waistY = size.height * 0.478;
      final hipY = torsoBot;

      final path = Path()
        ..moveTo(sL, shoulderY)
        ..quadraticBezierTo(sL - 5, waistY, wL, waistY)
        ..quadraticBezierTo(wL - 2, hipY - 8, hL, hipY)
        ..lineTo(hR, hipY)
        ..quadraticBezierTo(wR + 2, hipY - 8, wR, waistY)
        ..quadraticBezierTo(sR + 5, waistY, sR, shoulderY)
        ..close();

      canvas.drawPath(path, _fill(outfit));
      canvas.drawPath(path, _stroke(outfitDark));

      // Détail col V
      final collarPath = Path()
        ..moveTo(cx - size.width * 0.068, shoulderY)
        ..lineTo(cx, shoulderY + size.height * 0.038)
        ..lineTo(cx + size.width * 0.068, shoulderY)
        ..close();
      canvas.drawPath(collarPath, _fill(outfit));
      canvas.drawPath(collarPath, _stroke(outfitDark));
    } else {
      final sL = cx - size.width * 0.318;
      final sR = cx + size.width * 0.318;
      final wL = cx - size.width * 0.262;
      final wR = cx + size.width * 0.262;

      final path = Path()
        ..moveTo(sL, shoulderY)
        ..lineTo(sR, shoulderY)
        ..lineTo(wR, torsoBot)
        ..lineTo(wL, torsoBot)
        ..close();

      canvas.drawPath(path, _fill(outfit));
      canvas.drawPath(path, _stroke(outfitDark));

      // Ligne verticale centrale (détail torse)
      canvas.drawLine(
        Offset(cx, shoulderY + 6),
        Offset(cx, torsoBot - 6),
        _stroke(outfitDark.withValues(alpha: 0.3), 1.0),
      );
    }
  }

  // ── ARMS ───────────────────────────────────────────────────────────────────

  void _drawArms(Canvas canvas, double cx, Size size, bool isFemale,
      Color skin, Color skinDark) {
    final armTopY = size.height * 0.305;
    final armBotY = size.height * 0.630;
    final handR = isFemale ? size.width * 0.055 : size.width * 0.065;

    if (isFemale) {
      final outerX = size.width * 0.368;
      final innerX = size.width * 0.205;
      final midX = size.width * 0.38;

      // Bras gauche
      final lPath = Path()
        ..moveTo(cx - size.width * 0.268, armTopY)
        ..quadraticBezierTo(
            cx - outerX, size.height * 0.455, cx - midX, armBotY)
        ..lineTo(cx - innerX, armBotY)
        ..quadraticBezierTo(
            cx - size.width * 0.24, size.height * 0.455,
            cx - size.width * 0.188, armTopY)
        ..close();
      canvas.drawPath(lPath, _fill(skin));
      canvas.drawPath(lPath, _stroke(skinDark));

      // Bras droit
      final rPath = Path()
        ..moveTo(cx + size.width * 0.268, armTopY)
        ..quadraticBezierTo(
            cx + outerX, size.height * 0.455, cx + midX, armBotY)
        ..lineTo(cx + innerX, armBotY)
        ..quadraticBezierTo(
            cx + size.width * 0.24, size.height * 0.455,
            cx + size.width * 0.188, armTopY)
        ..close();
      canvas.drawPath(rPath, _fill(skin));
      canvas.drawPath(rPath, _stroke(skinDark));

      // Mains
      final lHand = Offset(cx - midX + (midX - innerX) / 2, armBotY + handR * 0.8);
      final rHand = Offset(cx + midX - (midX - innerX) / 2, armBotY + handR * 0.8);
      canvas.drawCircle(lHand, handR, _fill(skin));
      canvas.drawCircle(lHand, handR, _stroke(skinDark));
      canvas.drawCircle(rHand, handR, _fill(skin));
      canvas.drawCircle(rHand, handR, _stroke(skinDark));
    } else {
      final outerX = size.width * 0.42;
      final innerX = size.width * 0.26;
      final midX = size.width * 0.405;

      // Bras gauche
      final lPath = Path()
        ..moveTo(cx - size.width * 0.318, armTopY)
        ..quadraticBezierTo(
            cx - outerX, size.height * 0.455, cx - midX, armBotY)
        ..lineTo(cx - innerX, armBotY)
        ..quadraticBezierTo(
            cx - size.width * 0.30, size.height * 0.455,
            cx - size.width * 0.23, armTopY)
        ..close();
      canvas.drawPath(lPath, _fill(skin));
      canvas.drawPath(lPath, _stroke(skinDark));

      // Bras droit
      final rPath = Path()
        ..moveTo(cx + size.width * 0.318, armTopY)
        ..quadraticBezierTo(
            cx + outerX, size.height * 0.455, cx + midX, armBotY)
        ..lineTo(cx + innerX, armBotY)
        ..quadraticBezierTo(
            cx + size.width * 0.30, size.height * 0.455,
            cx + size.width * 0.23, armTopY)
        ..close();
      canvas.drawPath(rPath, _fill(skin));
      canvas.drawPath(rPath, _stroke(skinDark));

      // Mains
      final lHand = Offset(cx - midX + (midX - innerX) / 2, armBotY + handR * 0.8);
      final rHand = Offset(cx + midX - (midX - innerX) / 2, armBotY + handR * 0.8);
      canvas.drawCircle(lHand, handR, _fill(skin));
      canvas.drawCircle(lHand, handR, _stroke(skinDark));
      canvas.drawCircle(rHand, handR, _fill(skin));
      canvas.drawCircle(rHand, handR, _stroke(skinDark));
    }
  }

  // ── LEGS / PANTS ───────────────────────────────────────────────────────────

  void _drawLegs(Canvas canvas, double cx, Size size, bool isFemale,
      Color pants, Color pantsDark) {
    final legsTop = size.height * 0.590;
    final legsBot = size.height * 0.895;
    final legW = isFemale ? size.width * 0.160 : size.width * 0.185;
    final gap = size.width * 0.022;

    // Connecteur entrejambe
    canvas.drawRect(
      Rect.fromLTWH(cx - legW - gap, legsTop, (legW + gap) * 2, size.height * 0.042),
      _fill(pants),
    );

    // Jambe gauche
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - legW - gap, legsTop + 2, legW, legsBot - legsTop - 2),
        const Radius.circular(8),
      ),
      _fill(pants),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - legW - gap, legsTop + 2, legW, legsBot - legsTop - 2),
        const Radius.circular(8),
      ),
      _stroke(pantsDark),
    );

    // Jambe droite
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap, legsTop + 2, legW, legsBot - legsTop - 2),
        const Radius.circular(8),
      ),
      _fill(pants),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap, legsTop + 2, legW, legsBot - legsTop - 2),
        const Radius.circular(8),
      ),
      _stroke(pantsDark),
    );

    // Contour connecteur
    canvas.drawRect(
      Rect.fromLTWH(cx - legW - gap, legsTop, (legW + gap) * 2, size.height * 0.042),
      _stroke(pantsDark),
    );
  }

  // ── SHOES ──────────────────────────────────────────────────────────────────

  void _drawShoes(Canvas canvas, double cx, Size size, bool isFemale,
      Color shoes, Color shoesDark) {
    final shoesY = size.height * 0.895;
    final legW = isFemale ? size.width * 0.160 : size.width * 0.185;
    final gap = size.width * 0.022;
    final shoeH = size.height * 0.058;
    final shoeExtra = size.width * 0.028;

    // Chaussure gauche (déborde à gauche)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - legW - gap - shoeExtra, shoesY, legW + shoeExtra * 1.4, shoeH),
        const Radius.circular(6),
      ),
      _fill(shoes),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - legW - gap - shoeExtra, shoesY, legW + shoeExtra * 1.4, shoeH),
        const Radius.circular(6),
      ),
      _stroke(shoesDark),
    );

    // Chaussure droite (déborde à droite)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap, shoesY, legW + shoeExtra * 1.4, shoeH),
        const Radius.circular(6),
      ),
      _fill(shoes),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap, shoesY, legW + shoeExtra * 1.4, shoeH),
        const Radius.circular(6),
      ),
      _stroke(shoesDark),
    );
  }

  // ── HAIR BACK (derrière la tête) ───────────────────────────────────────────

  void _drawHairBack(Canvas canvas, double cx, Size size, bool isFemale,
      Color hair, Color hairDark) {
    final headCenter = Offset(cx, size.height * 0.135);
    final r = size.width * 0.176;
    final hs = appearance.hairStyle;

    if (hs == HairStyle.long || hs == HairStyle.ponytail) {
      final backLength = hs == HairStyle.long
          ? size.height * 0.225
          : size.height * 0.085;
      final backW = isFemale ? r * 1.42 : r * 1.12;
      final backY = headCenter.dy + r;

      final path = Path()
        ..moveTo(cx - backW, headCenter.dy)
        ..quadraticBezierTo(
            cx - backW - 6, backY + backLength * 0.5,
            cx - backW * 0.5, backY + backLength)
        ..lineTo(cx + backW * 0.5, backY + backLength)
        ..quadraticBezierTo(
            cx + backW + 6, backY + backLength * 0.5,
            cx + backW, headCenter.dy)
        ..close();
      canvas.drawPath(path, _fill(hair));
      canvas.drawPath(path, _stroke(hairDark));
    }

    if (hs == HairStyle.ponytail) {
      final ts = Offset(cx + r * 0.55, headCenter.dy + r * 0.45);
      final tailPath = Path()
        ..moveTo(ts.dx, ts.dy - 8)
        ..quadraticBezierTo(
            ts.dx + size.width * 0.19, ts.dy + size.height * 0.065,
            ts.dx + size.width * 0.09, ts.dy + size.height * 0.125)
        ..quadraticBezierTo(
            ts.dx + size.width * 0.115, ts.dy + size.height * 0.04,
            ts.dx, ts.dy + 8)
        ..close();
      canvas.drawPath(tailPath, _fill(hair));
      canvas.drawPath(tailPath, _stroke(hairDark));
    }

    if (hs == HairStyle.bun) {
      final bunC = Offset(cx + r * 0.18, headCenter.dy - r * 0.72);
      canvas.drawCircle(bunC, r * 0.44, _fill(hair));
      canvas.drawCircle(bunC, r * 0.44, _stroke(hairDark));
    }
  }

  // ── HAIR FRONT (sur la tête) ────────────────────────────────────────────────

  void _drawHairFront(Canvas canvas, double cx, Size size, bool isFemale,
      Color hair, Color hairDark) {
    final headCenter = Offset(cx, size.height * 0.135);
    final r = size.width * 0.176;
    final hs = appearance.hairStyle;

    switch (hs) {
      case HairStyle.short:
        final path = Path()
          ..moveTo(cx - r * 1.01, headCenter.dy - r * 0.12)
          ..quadraticBezierTo(
              cx - r * 0.88, headCenter.dy - r * 1.3, cx, headCenter.dy - r * 1.18)
          ..quadraticBezierTo(
              cx + r * 0.88, headCenter.dy - r * 1.3, cx + r * 1.01, headCenter.dy - r * 0.12)
          ..quadraticBezierTo(
              cx + r * 0.72, headCenter.dy - r * 0.52, cx, headCenter.dy - r * 0.42)
          ..quadraticBezierTo(
              cx - r * 0.72, headCenter.dy - r * 0.52, cx - r * 1.01, headCenter.dy - r * 0.12)
          ..close();
        canvas.drawPath(path, _fill(hair));
        canvas.drawPath(path, _stroke(hairDark));
        if (!isFemale) {
          // Favoris masculins
          for (final sign in [-1.0, 1.0]) {
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(cx + sign * r * 0.88, headCenter.dy + r * 0.42),
                width: r * 0.36, height: r * 0.52,
              ),
              _fill(hair),
            );
          }
        }

      case HairStyle.medium:
        _drawMediumHair(canvas, cx, headCenter, r, hair, hairDark, isFemale);
        _drawBangs(canvas, cx, headCenter, r, hair, hairDark, isFemale);

      case HairStyle.long:
      case HairStyle.ponytail:
        _drawMediumHair(canvas, cx, headCenter, r, hair, hairDark, isFemale,
            lowSides: true);
        _drawBangs(canvas, cx, headCenter, r, hair, hairDark, isFemale);

      case HairStyle.bun:
        _drawMediumHair(canvas, cx, headCenter, r, hair, hairDark, isFemale);
        _drawBangs(canvas, cx, headCenter, r, hair, hairDark, isFemale);

      case HairStyle.spiky:
        // Base courte
        final base = Path()
          ..moveTo(cx - r * 1.02, headCenter.dy - r * 0.08)
          ..quadraticBezierTo(
              cx - r * 0.9, headCenter.dy - r * 1.05,
              cx, headCenter.dy - r * 0.98)
          ..quadraticBezierTo(
              cx + r * 0.9, headCenter.dy - r * 1.05,
              cx + r * 1.02, headCenter.dy - r * 0.08)
          ..close();
        canvas.drawPath(base, _fill(hair));

        // Pointes
        final spikeDefs = [
          [cx - r * 0.6, headCenter.dy - r * 1.02, cx - r * 0.3, headCenter.dy - r * 1.68],
          [cx, headCenter.dy - r * 1.0, cx, headCenter.dy - r * 1.65],
          [cx + r * 0.5, headCenter.dy - r * 1.05, cx + r * 0.2, headCenter.dy - r * 1.62],
          [cx - r * 0.2, headCenter.dy - r * 1.08, cx - r * 0.65, headCenter.dy - r * 1.52],
          [cx + r * 0.35, headCenter.dy - r * 1.08, cx + r * 0.7, headCenter.dy - r * 1.48],
        ];
        for (final s in spikeDefs) {
          final sp = Path()
            ..moveTo(s[0] - 5, s[1])
            ..lineTo(s[2], s[3])
            ..lineTo(s[0] + 5, s[1])
            ..close();
          canvas.drawPath(sp, _fill(hair));
          canvas.drawPath(sp, _stroke(hairDark, 1.0));
        }
        canvas.drawPath(base, _stroke(hairDark));
    }
  }

  void _drawMediumHair(
      Canvas canvas, double cx, Offset hc, double r, Color hair, Color hairDark,
      bool isFemale, {bool lowSides = false}) {
    final sideBottom = lowSides ? hc.dy + r * 0.88 : hc.dy + r * 0.82;
    final innerBottom = lowSides ? hc.dy + r * 0.58 : hc.dy + r * 0.52;

    final path = Path()
      ..moveTo(cx - r * 1.05, hc.dy + r * 0.3)
      ..quadraticBezierTo(cx - r * 1.1, hc.dy - r * 0.42, cx - r * 0.82, hc.dy - r * 1.25)
      ..quadraticBezierTo(cx, hc.dy - r * 1.42, cx + r * 0.82, hc.dy - r * 1.25)
      ..quadraticBezierTo(cx + r * 1.1, hc.dy - r * 0.42, cx + r * 1.05, hc.dy + r * 0.3)
      ..quadraticBezierTo(cx + r * 0.92, hc.dy + r * 0.68, cx + r * 0.66, sideBottom)
      ..quadraticBezierTo(cx, innerBottom, cx - r * 0.66, sideBottom)
      ..quadraticBezierTo(cx - r * 0.92, hc.dy + r * 0.68, cx - r * 1.05, hc.dy + r * 0.3)
      ..close();
    canvas.drawPath(path, _fill(hair));
    canvas.drawPath(path, _stroke(hairDark));
  }

  void _drawBangs(Canvas canvas, double cx, Offset hc, double r, Color hair,
      Color hairDark, bool isFemale) {
    if (isFemale) {
      // Frange côté (asymétrique/douce)
      final bangPath = Path()
        ..moveTo(cx - r * 0.92, hc.dy - r * 0.88)
        ..quadraticBezierTo(
            cx - r * 0.48, hc.dy - r * 1.1, cx - r * 0.08, hc.dy - r * 0.82)
        ..quadraticBezierTo(
            cx - r * 0.48, hc.dy - r * 0.62, cx - r * 0.92, hc.dy - r * 0.88);
      canvas.drawPath(bangPath, _fill(hair));
    } else {
      // Frange droite
      final bangPath = Path()
        ..moveTo(cx - r * 0.9, hc.dy - r * 0.9)
        ..lineTo(cx + r * 0.9, hc.dy - r * 0.9)
        ..quadraticBezierTo(
            cx + r * 0.62, hc.dy - r * 0.55, cx, hc.dy - r * 0.52)
        ..quadraticBezierTo(
            cx - r * 0.62, hc.dy - r * 0.55, cx - r * 0.9, hc.dy - r * 0.9)
        ..close();
      canvas.drawPath(bangPath, _fill(hair));
    }
  }

  // ── FACE ───────────────────────────────────────────────────────────────────

  void _drawFace(Canvas canvas, double cx, Size size, bool isFemale,
      Color skin, Color skinDark) {
    final hc = Offset(cx, size.height * 0.135);
    final r = size.width * 0.176;

    final eyeRY = hc.dy - r * 0.04;
    final eyeRX = isFemale ? 6.2 : 5.6;
    final eyeRYR = isFemale ? 5.2 : 4.6;
    final eyeSpacing = r * 0.44;

    // Blancs des yeux
    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + sign * eyeSpacing, eyeRY),
          width: eyeRX * 2, height: eyeRYR * 2,
        ),
        _fill(Colors.white.withValues(alpha: 0.92)),
      );
    }

    // Pupilles
    final pupilR = isFemale ? 3.3 : 2.9;
    for (final sign in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + sign * eyeSpacing, eyeRY),
        pupilR,
        _fill(const Color(0xFF2D1A00)),
      );
      // Reflet
      canvas.drawCircle(
        Offset(cx + sign * eyeSpacing + 1, eyeRY - 1),
        1.0,
        _fill(Colors.white),
      );
    }

    // Contour yeux
    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + sign * eyeSpacing, eyeRY),
          width: eyeRX * 2, height: eyeRYR * 2,
        ),
        _stroke(skinDark.withValues(alpha: 0.85), 1.0),
      );
    }

    // Sourcils
    final browPaint = Paint()
      ..color = appearance.hairColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isFemale ? 1.5 : 2.0
      ..strokeCap = StrokeCap.round;
    final browY = eyeRY - eyeRYR - 2.5;

    if (isFemale) {
      for (final sign in [-1.0, 1.0]) {
        final brow = Path()
          ..moveTo(cx + sign * (eyeSpacing - eyeRX), browY + 1)
          ..quadraticBezierTo(
              cx + sign * eyeSpacing, browY - 3,
              cx + sign * (eyeSpacing + eyeRX), browY + 1);
        canvas.drawPath(brow, browPaint);
      }

      // Cils
      final lashPaint = _stroke(const Color(0xFF1A0A00), 1.2);
      for (final sign in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(cx + sign * (eyeSpacing + eyeRX * 0.7), eyeRY - eyeRYR + 0.5),
          Offset(cx + sign * (eyeSpacing + eyeRX * 0.7 + sign * 2), eyeRY - eyeRYR - 2.2),
          lashPaint,
        );
        canvas.drawLine(
          Offset(cx + sign * eyeSpacing, eyeRY - eyeRYR),
          Offset(cx + sign * eyeSpacing, eyeRY - eyeRYR - 2.5),
          lashPaint,
        );
      }

      // Joues rosées
      final blush = _fill(const Color(0xFFFFB6C1).withValues(alpha: 0.35));
      for (final sign in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + sign * r * 0.64, eyeRY + r * 0.33),
            width: r * 0.56, height: r * 0.3,
          ),
          blush,
        );
      }
    } else {
      // Sourcils droits masculins
      for (final sign in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(cx + sign * (eyeSpacing - eyeRX), browY),
          Offset(cx + sign * (eyeSpacing + eyeRX), browY - (sign > 0 ? 1 : -1)),
          browPaint,
        );
      }
    }

    // Nez
    if (isFemale) {
      canvas.drawCircle(
        Offset(cx, eyeRY + r * 0.25),
        1.2,
        _fill(skinDark.withValues(alpha: 0.38)),
      );
    } else {
      canvas.drawLine(
        Offset(cx, eyeRY + r * 0.20),
        Offset(cx - 2, eyeRY + r * 0.30),
        _stroke(skinDark.withValues(alpha: 0.48), 1.5),
      );
    }

    // Bouche
    final mouthY = eyeRY + r * 0.52;
    final mouthPaint = _stroke(skinDark.withValues(alpha: 0.58), isFemale ? 2.0 : 1.5);

    if (isFemale) {
      final lip = Path()
        ..moveTo(cx - 5.5, mouthY)
        ..quadraticBezierTo(cx, mouthY + 3, cx + 5.5, mouthY);
      canvas.drawPath(lip, mouthPaint);
    } else {
      canvas.drawLine(
        Offset(cx - 5.0, mouthY),
        Offset(cx + 5.0, mouthY),
        mouthPaint,
      );
    }
  }

  // ── HAT ────────────────────────────────────────────────────────────────────

  void _drawHat(Canvas canvas, double cx, Size size, Color hat, int style) {
    if (style == 0) return;

    final hc = Offset(cx, size.height * 0.135);
    final r = size.width * 0.176;
    final hatDark = _darker(hat);

    switch (style) {
      case 1: // Chapeau conique (sorcier)
        final brimY = hc.dy - r * 0.78;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, brimY), width: r * 2.82, height: r * 0.5),
          _fill(hat),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, brimY), width: r * 2.82, height: r * 0.5),
          _stroke(hatDark),
        );
        final cone = Path()
          ..moveTo(cx - r * 1.22, brimY)
          ..lineTo(cx, hc.dy - r * 2.45)
          ..lineTo(cx + r * 1.22, brimY)
          ..close();
        canvas.drawPath(cone, _fill(hat));
        canvas.drawPath(cone, _stroke(hatDark));

      case 2: // Couronne
        final crownY = hc.dy - r * 0.88;
        final crownH = r * 0.72;
        // Dents (5, hauteurs alternées)
        for (var i = 0; i < 5; i++) {
          final tx = cx - r + (r * 2 * i / 4);
          final isHigh = i.isEven;
          final toothH = isHigh ? crownH * 0.68 : crownH * 0.38;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  tx - r * 0.188, crownY + crownH * 0.38 - toothH, r * 0.376, toothH + 2),
              const Radius.circular(3),
            ),
            _fill(hat),
          );
        }
        // Bande principale
        final band = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - r, crownY + crownH * 0.38, r * 2, crownH * 0.62),
          const Radius.circular(3),
        );
        canvas.drawRRect(band, _fill(hat));
        canvas.drawRRect(band, _stroke(hatDark));
        // Gemme
        canvas.drawCircle(
          Offset(cx, crownY + crownH * 0.68),
          3.5,
          _fill(const Color(0xFFFF4444).withValues(alpha: 0.9)),
        );
        canvas.drawCircle(
          Offset(cx, crownY + crownH * 0.68),
          3.5,
          _stroke(const Color(0xFFAA0000), 0.8),
        );

      case 3: // Bonnet
        final beanie = Path()
          ..moveTo(cx - r * 1.06, hc.dy + r * 0.02)
          ..quadraticBezierTo(
              cx - r * 1.1, hc.dy - r * 1.62, cx, hc.dy - r * 1.68)
          ..quadraticBezierTo(
              cx + r * 1.1, hc.dy - r * 1.62, cx + r * 1.06, hc.dy + r * 0.02)
          ..close();
        canvas.drawPath(beanie, _fill(hat));
        canvas.drawPath(beanie, _stroke(hatDark));
        // Pompon
        canvas.drawCircle(
          Offset(cx, hc.dy - r * 1.75),
          r * 0.28,
          _fill(Colors.white.withValues(alpha: 0.9)),
        );
        canvas.drawCircle(
          Offset(cx, hc.dy - r * 1.75),
          r * 0.28,
          _stroke(const Color(0xFFCCCCCC), 0.8),
        );
        // Bord rebique
        final ribY = hc.dy - r * 0.04;
        final ribH = r * 0.36;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.06, ribY - ribH, r * 2.12, ribH),
            const Radius.circular(3),
          ),
          _fill(_darker(hat, 0.15)),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.06, ribY - ribH, r * 2.12, ribH),
            const Radius.circular(3),
          ),
          _stroke(hatDark),
        );

      case 4: // Bandana
        final bandTop = hc.dy - r * 0.18;
        final bandH = r * 0.44;
        final band = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.0, bandTop, r * 2.0, bandH),
            const Radius.circular(3),
          ));
        canvas.drawPath(band, _fill(hat));
        canvas.drawPath(band, _stroke(hatDark));
        // Nœud + liens
        final knotC = Offset(cx + r * 0.82, bandTop + bandH * 0.5);
        canvas.drawCircle(knotC, r * 0.16, _fill(_darker(hat, 0.1)));
        canvas.drawCircle(knotC, r * 0.16, _stroke(hatDark));
        canvas.drawLine(knotC, Offset(knotC.dx + r * 0.38, bandTop - r * 0.1),
            _stroke(hat, 2.6));
        canvas.drawLine(knotC, Offset(knotC.dx + r * 0.45, bandTop + bandH + r * 0.05),
            _stroke(hat, 2.6));
    }
  }

  // ── shouldRepaint ──────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(covariant CharacterPainter old) =>
      old.appearance.gender != appearance.gender ||
      old.appearance.skinTone != appearance.skinTone ||
      old.appearance.hairColor != appearance.hairColor ||
      old.appearance.hairStyle != appearance.hairStyle ||
      old.outfitColor != outfitColor ||
      old.pantsColor != pantsColor ||
      old.shoesColor != shoesColor ||
      old.hatColor != hatColor ||
      old.hatStyle != hatStyle ||
      old.auraColor != auraColor;
}
