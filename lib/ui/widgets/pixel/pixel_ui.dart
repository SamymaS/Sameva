import 'package:flutter/material.dart';

/// Briques d'interface « pixel art » (maquettes Claude Design « Sameva · Écrans
/// pixel art », nov. 2026) : cadres épais, ombres franches sans flou, aucun coin
/// arrondi, animations par paliers.
abstract final class PixelCouleurs {
  static const nuit = Color(0xFF120A2E);
  static const abysse = Color(0xFF0A0620);
  static const panneau = Color(0xFF1A0F3C);
  static const panneauProfond = Color(0xFF241552);
  static const trait = Color(0xFF3B2A78);
  static const violetSombre = Color(0xFF2D1B6E);
  static const violet = Color(0xFF805AD5);
  static const violetClair = Color(0xFFB794F4);
  static const or = Color(0xFFF59E0B);
  static const orClair = Color(0xFFFDE68A);
  static const orSombre = Color(0xFFB45309);
  static const oracle = Color(0xFF1AA7EC);
  static const texte = Color(0xFFFFFFFF);
  static const texteDoux = Color(0xFFCBD5E0);
}

/// Polices embarquées (pubspec) : Press Start 2P pour les titres et les
/// chiffres, Pixelify Sans pour le texte courant (plus lisible).
abstract final class PixelTextes {
  static const titre = 'PressStart2P';
  static const courant = 'PixelifySans';

  static TextStyle chiffres(double taille, Color couleur) =>
      TextStyle(fontFamily: titre, fontSize: taille, height: 1.5, color: couleur);

  static TextStyle corps(double taille, {Color couleur = PixelCouleurs.texte, FontWeight poids = FontWeight.w400}) =>
      TextStyle(fontFamily: courant, fontSize: taille, height: 1.35, color: couleur, fontWeight: poids);
}

/// Ramène une progression continue `t` (0..1) à `paliers` valeurs : le
/// mouvement saute d'une position à l'autre comme une animation image par image.
double parPaliers(double t, int paliers) =>
    (t.clamp(0.0, 1.0) * paliers).floor().clamp(0, paliers) / paliers;

/// Partie fractionnaire, pour dériver plusieurs boucles d'un seul contrôleur.
double fraction(double v) => v - v.floorToDouble();

/// Panneau à bord épais et ombre portée franche.
class PixelCadre extends StatelessWidget {
  final Widget child;
  final Color fond;
  final Color bord;
  final EdgeInsetsGeometry padding;

  const PixelCadre({
    super.key,
    required this.child,
    this.fond = PixelCouleurs.panneau,
    this.bord = PixelCouleurs.trait,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: fond,
          border: Border.all(color: bord, width: 3),
          boxShadow: const [BoxShadow(color: PixelCouleurs.abysse, offset: Offset(0, 4))],
        ),
        child: Padding(padding: padding, child: child),
      );
}

/// Bouton pixel : principal (or) ou secondaire (violet). Cible tactile ≥ 48 px.
class PixelBouton extends StatelessWidget {
  final String libelle;
  final VoidCallback? onPressed;
  final bool principal;

  const PixelBouton({super.key, required this.libelle, this.onPressed, this.principal = true});

  @override
  Widget build(BuildContext context) {
    final fond = principal ? PixelCouleurs.or : PixelCouleurs.panneau;
    final bord = principal ? PixelCouleurs.orClair : PixelCouleurs.violet;
    final creux = principal ? PixelCouleurs.orSombre : PixelCouleurs.violetSombre;
    final texte = principal ? PixelCouleurs.nuit : PixelCouleurs.texte;
    return Semantics(
      // container : sinon, dans une boîte de dialogue, le bouton fusionne avec le
      // texte voisin en un seul nœud (« Titre Récupérer ») et devient introuvable.
      container: true,
      button: true,
      enabled: onPressed != null,
      label: libelle,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          // désactivé : estompé, sans changer la mise en page
          opacity: onPressed == null ? 0.45 : 1,
          child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fond,
            border: Border(
              top: BorderSide(color: bord, width: 3),
              left: BorderSide(color: bord, width: 3),
              right: BorderSide(color: bord, width: 3),
              bottom: BorderSide(color: creux, width: 8),
            ),
            boxShadow: const [BoxShadow(color: PixelCouleurs.abysse, offset: Offset(0, 4))],
          ),
          child: Text(libelle,
              style: PixelTextes.corps(19, couleur: texte, poids: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

/// Fond nuit étoilé : une grille régulière de points d'un pixel logique.
class PixelFondPoints extends StatelessWidget {
  final Color fond;
  final Color point;
  const PixelFondPoints({super.key, this.fond = PixelCouleurs.nuit, this.point = PixelCouleurs.trait});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PointsPainter(fond, point), size: Size.infinite);
}

class _PointsPainter extends CustomPainter {
  final Color fond;
  final Color point;
  _PointsPainter(this.fond, this.point);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fond);
    final p = Paint()..color = point.withValues(alpha: 0.6);
    for (double y = 12; y < size.height; y += 24) {
      for (double x = 12; x < size.width; x += 24) {
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), p);
      }
    }
  }

  @override
  bool shouldRepaint(_PointsPainter old) => old.fond != fond || old.point != point;
}

/// Contour « cercle pixelisé » (octogone en escalier) de côté 1, à mettre à
/// l'échelle : le même polygone que le `clip-path` des maquettes.
const List<Offset> contourAnneau = [
  Offset(.30, 0), Offset(.70, 0), Offset(.70, .06), Offset(.85, .06), Offset(.85, .15),
  Offset(.94, .15), Offset(.94, .30), Offset(1, .30), Offset(1, .70), Offset(.94, .70),
  Offset(.94, .85), Offset(.85, .85), Offset(.85, .94), Offset(.70, .94), Offset(.70, 1),
  Offset(.30, 1), Offset(.30, .94), Offset(.15, .94), Offset(.15, .85), Offset(.06, .85),
  Offset(.06, .70), Offset(0, .70), Offset(0, .30), Offset(.06, .30), Offset(.06, .15),
  Offset(.15, .15), Offset(.15, .06), Offset(.30, .06),
];

/// Disque pixelisé plein, de la couleur donnée.
class PixelAnneau extends StatelessWidget {
  final double cote;
  final Color couleur;
  const PixelAnneau({super.key, required this.cote, required this.couleur});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(cote), painter: _AnneauPainter(couleur));
}

class _AnneauPainter extends CustomPainter {
  final Color couleur;
  _AnneauPainter(this.couleur);

  @override
  void paint(Canvas canvas, Size size) {
    final chemin = Path()
      ..addPolygon([for (final o in contourAnneau) Offset(o.dx * size.width, o.dy * size.height)], true);
    canvas.drawPath(chemin, Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_AnneauPainter old) => old.couleur != couleur;
}

/// Barre de progression pixel avec un repère de seuil (confiance de l'Oracle).
/// [valeur] et [seuil] entre 0 et 1. Le remplissage est positionné : dans une
/// Stack, une boîte sans enfant recevrait sinon une hauteur nulle.
class PixelBarreSeuil extends StatelessWidget {
  final double valeur;
  final double seuil;
  final Color couleur;
  final double hauteur;

  const PixelBarreSeuil({
    super.key,
    required this.valeur,
    required this.seuil,
    required this.couleur,
    this.hauteur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hauteur,
      child: LayoutBuilder(
        builder: (_, c) => Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: ColoredBox(color: PixelCouleurs.violetSombre)),
            Positioned(
              key: const ValueKey('remplissage'),
              left: 0,
              top: 0,
              bottom: 0,
              width: c.maxWidth * valeur.clamp(0.0, 1.0),
              child: ColoredBox(color: couleur),
            ),
            Positioned(
              key: const ValueKey('seuil'),
              left: c.maxWidth * seuil.clamp(0.0, 1.0) - 1.5,
              top: -4,
              bottom: -4,
              width: 3,
              child: const ColoredBox(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jauge pixel (PV, XP, moral) : remplissage plein avec un reflet clair sur le
/// haut, qui se remplit en paliers à l'apparition. [valeur] entre 0 et 1.
class PixelJauge extends StatelessWidget {
  final double valeur;
  final Color couleur;
  final double hauteur;
  final Color fond;

  const PixelJauge({
    super.key,
    required this.valeur,
    required this.couleur,
    this.hauteur = 12,
    this.fond = PixelCouleurs.violetSombre,
  });

  @override
  Widget build(BuildContext context) {
    final cible = valeur.clamp(0.0, 1.0);
    final reflet = Color.lerp(couleur, Colors.white, .45)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: cible),
      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 600),
      builder: (_, v, __) => Container(
        height: hauteur,
        decoration: BoxDecoration(color: fond, border: Border.all(color: PixelCouleurs.abysse, width: 2)),
        child: LayoutBuilder(
          builder: (_, c) => Stack(
            children: [
              // positionné : une boîte sans enfant aurait sinon une hauteur nulle
              Positioned(
                key: const ValueKey('remplissage'),
                left: 0,
                top: 0,
                bottom: 0,
                // 12 paliers : la jauge « monte » image par image
                width: c.maxWidth * (v >= cible ? cible : parPaliers(v, 12)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: couleur,
                    border: Border(top: BorderSide(color: reflet, width: hauteur > 8 ? 3 : 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
