import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/audio/sons.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/quest_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/item_icon.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Libellé français d'une rareté.
String libelleRarete(QuestRarity r) => switch (r) {
      QuestRarity.common => 'Commun',
      QuestRarity.uncommon => 'Peu commun',
      QuestRarity.rare => 'Rare',
      QuestRarity.epic => 'Épique',
      QuestRarity.legendary => 'Légendaire',
      QuestRarity.mythic => 'Mythique',
    };

/// Couleur de la colonne de lumière pendant la charge : elle annonce la
/// meilleure rareté du tirage avant la révélation (les raretés modestes
/// gardent le violet du portail pour ne rien promettre).
Color couleurColonne(QuestRarity r) => switch (r) {
      QuestRarity.common || QuestRarity.uncommon => PixelCouleurs.violetClair,
      QuestRarity.rare => AppColors.rarityRare,
      QuestRarity.epic => AppColors.rarityEpic,
      QuestRarity.legendary => PixelCouleurs.or,
      QuestRarity.mythic => AppColors.rarityMythic,
    };

/// Meilleure rareté d'une liste d'objets.
QuestRarity meilleureRarete(List<Item> objets) =>
    objets.map((o) => o.rarity).reduce((a, b) => a.index >= b.index ? a : b);

/// Ordre de révélation d'un tirage multiple : l'ordre du serveur, sauf le
/// meilleur objet, gardé pour la fin (le suspense va crescendo).
List<Item> ordreRevelation(List<Item> objets) {
  if (objets.length < 2) return List.of(objets);
  final meilleur = meilleureRarete(objets);
  final i = objets.lastIndexWhere((o) => o.rarity == meilleur);
  return [...objets.sublist(0, i), ...objets.sublist(i + 1), objets[i]];
}

enum _Phase { charge, revelation }

/// Séquence plein écran d'une invocation (maquettes « Sameva · Écrans pixel
/// art ») : charge du portail, puis révélation d'un objet ou de dix cartes.
///
/// Purement visuelle : les objets sont déjà tirés par le serveur et rangés.
/// « Passer » (ou un toucher pendant le retournement des cartes) saute à la
/// fin ; avec « réduire les animations », la charge est omise.
class SequenceInvocation extends StatefulWidget {
  final List<Item> objets;

  /// Cristaux rendus pour les doublons (0 : aucun).
  final int remboursement;
  final int? epiqueDans;
  final int? legendaireDans;

  const SequenceInvocation({
    super.key,
    required this.objets,
    this.remboursement = 0,
    this.epiqueDans,
    this.legendaireDans,
  }) : assert(objets.length > 0);

  static Future<void> afficher(
    BuildContext context, {
    required List<Item> objets,
    int remboursement = 0,
    int? epiqueDans,
    int? legendaireDans,
  }) =>
      Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => SequenceInvocation(
          objets: objets,
          remboursement: remboursement,
          epiqueDans: epiqueDans,
          legendaireDans: legendaireDans,
        ),
      ));

  @override
  State<SequenceInvocation> createState() => _SequenceInvocationState();
}

class _SequenceInvocationState extends State<SequenceInvocation> with TickerProviderStateMixin {
  /// Horloge commune des boucles (rotation, flottement, scintillement) : 4,8 s.
  late final AnimationController _boucle;
  late final AnimationController _charge;
  late final AnimationController _revele;
  late final List<Item> _ordre;
  late final QuestRarity _meilleure;
  _Phase _phase = _Phase.charge;

  bool get _multiple => widget.objets.length > 1;

  @override
  void initState() {
    super.initState();
    _ordre = ordreRevelation(widget.objets);
    _meilleure = meilleureRarete(widget.objets);
    _boucle = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800))..repeat();
    _charge = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _reveler();
      });
    // Un objet : apparition 0,6 s. Dix : une carte toutes les 0,15 s, la
    // dernière après une pause, chacune se retournant en 0,45 s.
    _revele = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _multiple ? _debutCarte(_ordre.length - 1) + 450 : 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phase == _Phase.charge && !_charge.isAnimating && _charge.value == 0) {
      if (MediaQuery.of(context).disableAnimations) {
        _reveler(fin: true);
      } else {
        _charge.forward();
      }
    }
  }

  int _debutCarte(int i) => i * 150 + (i == _ordre.length - 1 && i > 0 ? 300 : 0);

  void _reveler({bool fin = false}) {
    if (_phase == _Phase.revelation) {
      _revele.value = 1;
      return;
    }
    unawaited(Sons.jouer(Sons.invocationPour(_meilleure.name)));
    setState(() => _phase = _Phase.revelation);
    if (fin) {
      _revele.value = 1;
    } else {
      _revele.forward();
    }
  }

  @override
  void dispose() {
    _boucle.dispose();
    _charge.dispose();
    _revele.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == _Phase.revelation,
      child: Material(
        color: PixelCouleurs.abysse,
        child: AnimatedBuilder(
          animation: Listenable.merge([_boucle, _charge, _revele]),
          builder: (context, _) => _phase == _Phase.charge
              ? _Charge(
                  boucle: _boucle.value,
                  progression: _charge.value,
                  colonne: couleurColonne(_meilleure),
                  onPasser: _reveler,
                )
              : _multiple
                  ? _RevelationMultiple(
                      objets: _ordre,
                      boucle: _boucle.value,
                      ecouleMs: _revele.value * _revele.duration!.inMilliseconds,
                      debutCarte: _debutCarte,
                      remboursement: widget.remboursement,
                      epiqueDans: widget.epiqueDans,
                      legendaireDans: widget.legendaireDans,
                      enCours: _revele.value < 1,
                      onToucher: () => _revele.value = 1,
                      onContinuer: () => Navigator.of(context).pop(),
                    )
                  : _RevelationUnique(
                      objet: _ordre.single,
                      boucle: _boucle.value,
                      apparition: _revele.value,
                      remboursement: widget.remboursement,
                      epiqueDans: widget.epiqueDans,
                      legendaireDans: widget.legendaireDans,
                      onContinuer: () => Navigator.of(context).pop(),
                    ),
        ),
      ),
    );
  }
}

// ─── Charge ──────────────────────────────────────────────────────────────────

class _Charge extends StatelessWidget {
  final double boucle;
  final double progression;
  final Color colonne;
  final VoidCallback onPasser;

  const _Charge({required this.boucle, required this.progression, required this.colonne, required this.onPasser});

  @override
  Widget build(BuildContext context) {
    // Rotation par paliers de 45°/8 toutes les 1,2 s (4 tours d'horloge),
    // l'anneau intérieur en sens inverse et plus vite.
    final rot = parPaliers(fraction(boucle * 4), 8) * math.pi / 4;
    final rotInverse = -parPaliers(fraction(boucle * 5.33), 8) * math.pi / 4;
    // Tremblement : 2 positions alternées toutes les 0,12 s.
    final tremble = (boucle * 40).floor().isEven ? const Offset(3, -3) : const Offset(-3, 3);
    // La colonne s'élargit avec la charge (5 paliers).
    final p = parPaliers(progression, 5);
    final largeur = 64 + 48 * p;
    final points = '.' * ((boucle * 16).floor() % 4);

    return Stack(
      fit: StackFit.expand,
      children: [
        const PixelFondPoints(fond: PixelCouleurs.abysse, point: PixelCouleurs.violetSombre),
        Center(child: Container(width: largeur, color: colonne.withValues(alpha: 0.35 + 0.5 * p))),
        Center(child: Container(width: 24, color: Colors.white.withValues(alpha: 0.85))),
        Center(
          child: Transform.translate(
            offset: tremble,
            child: SizedBox.square(
              dimension: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(angle: rot, child: const PixelAnneau(cote: 300, couleur: PixelCouleurs.violet)),
                  const PixelAnneau(cote: 272, couleur: PixelCouleurs.abysse),
                  Transform.rotate(angle: rotInverse, child: PixelAnneau(cote: 240, couleur: colonne)),
                  const PixelAnneau(cote: 216, couleur: PixelCouleurs.panneauProfond),
                  PixelAnneau(cote: 150, couleur: Colors.white.withValues(alpha: 0.9)),
                  for (final (i, c) in [PixelCouleurs.orClair, const Color(0xFFE9D5FF), AppColors.crystalBlue].indexed)
                    _Particule(phase: fraction(boucle * 4.8 + i / 3), x: -60.0 + 60 * i, couleur: c),
                  Semantics(
                    label: 'Essence aspirée par le portail',
                    child: Image.asset('assets/sprites/objets/material_essence.png',
                        width: 128, height: 128, fit: BoxFit.contain,
                        filterQuality: FilterQuality.none, isAntiAlias: false),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: 112, child: PixelBouton(libelle: 'Passer', principal: false, onPressed: onPasser)),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                child: Text(
                  "Le portail s'éveille$points".padRight(23),
                  textAlign: TextAlign.center,
                  style: PixelTextes.chiffres(13, PixelCouleurs.texte).copyWith(
                    shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(3, 3))],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Étincelle aspirée vers le haut, en 6 paliers.
class _Particule extends StatelessWidget {
  final double phase;
  final double x;
  final Color couleur;
  const _Particule({required this.phase, required this.x, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final p = parPaliers(phase, 6);
    return Transform.translate(
      offset: Offset(x, 110 - 170 * p),
      child: Opacity(opacity: 1 - p, child: Container(width: 8, height: 8, color: couleur)),
    );
  }
}

// ─── Révélation d'un objet ───────────────────────────────────────────────────

class _RevelationUnique extends StatelessWidget {
  final Item objet;
  final double boucle;
  final double apparition;
  final int remboursement;
  final int? epiqueDans;
  final int? legendaireDans;
  final VoidCallback onContinuer;

  const _RevelationUnique({
    required this.objet,
    required this.boucle,
    required this.apparition,
    required this.remboursement,
    required this.epiqueDans,
    required this.legendaireDans,
    required this.onContinuer,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = AppColors.getRarityColor(objet.rarity.name);
    final eclatant = objet.rarity.index >= QuestRarity.epic.index;
    // L'objet grandit en 4 paliers (0 à 0,6 s), la bannière se déplie en 5
    // paliers (0,4 à 0,9 s), puis l'objet flotte de 10 px (4 paliers, 1,6 s).
    final echelle = 0.25 + 0.75 * parPaliers(apparition / (600 / 900), 4);
    final banniere = parPaliers((apparition - 400 / 900) / (500 / 900), 5);
    final flotte = apparition < 1 ? 0.0 : -10 * parPaliers(_allerRetour(fraction(boucle * 1.5)), 4);

    return Stack(
      fit: StackFit.expand,
      children: [
        const PixelFondPoints(),
        if (eclatant)
          Positioned.fill(
            child: CustomPaint(
              painter: _RayonsPainter(couleur: couleur, angle: parPaliers(fraction(boucle * 1.2), 12) * math.pi / 6),
            ),
          ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
            child: Column(
              children: [
                ClipRect(
                  child: Align(
                    widthFactor: banniere == 0 ? 0.001 : banniere,
                    child: Semantics(
                      header: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: couleur,
                          border: Border.all(color: Color.lerp(couleur, Colors.white, .5)!, width: 3),
                          boxShadow: const [BoxShadow(color: PixelCouleurs.abysse, offset: Offset(0, 4))],
                        ),
                        child: Text(libelleRarete(objet.rarity).toUpperCase(),
                            style: PixelTextes.chiffres(14, PixelCouleurs.nuit)),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, flotte),
                      child: Transform.scale(
                        scale: echelle,
                        child: Opacity(
                          opacity: echelle.clamp(0.0, 1.0),
                          child: ItemIcon(item: objet, size: 192, showBackground: false, showRarityGlow: false, showRarityBorder: false),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(objet.name,
                    textAlign: TextAlign.center,
                    style: PixelTextes.chiffres(17, couleur).copyWith(
                      shadows: [Shadow(color: Color.lerp(couleur, Colors.black, .55)!, offset: const Offset(3, 3))],
                    )),
                const SizedBox(height: 10),
                Text(objet.description,
                    textAlign: TextAlign.center, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (remboursement > 0)
                      _Pastille('Doublon · +$remboursement cristaux', AppColors.crystalBlue)
                    else
                      _Pastille('Ajouté à l\'inventaire', couleur),
                    if (epiqueDans != null) _Pastille('Épique dans $epiqueDans', AppColors.rarityEpic),
                    if (legendaireDans != null) _Pastille('Légendaire dans $legendaireDans', PixelCouleurs.orClair),
                  ],
                ),
                const SizedBox(height: 32),
                PixelBouton(libelle: 'Continuer', onPressed: onContinuer),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _allerRetour(double t) => t < .5 ? t * 2 : 2 - t * 2;

class _Pastille extends StatelessWidget {
  final String texte;
  final Color couleur;
  const _Pastille(this.texte, this.couleur);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(border: Border.all(color: couleur, width: 2)),
        child: Text(texte, style: PixelTextes.corps(14, couleur: couleur, poids: FontWeight.w600)),
      );
}

/// Rayons tournants derrière un objet épique ou mieux (12 paliers).
class _RayonsPainter extends CustomPainter {
  final Color couleur;
  final double angle;
  _RayonsPainter({required this.couleur, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, 40 + 150 + 60);
    final r = size.longestSide;
    final p = Paint()..color = couleur.withValues(alpha: 0.25);
    for (var i = 0; i < 12; i++) {
      final a = angle + i * math.pi / 6;
      final chemin = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(centre.dx + r * math.cos(a), centre.dy + r * math.sin(a))
        ..lineTo(centre.dx + r * math.cos(a + .1), centre.dy + r * math.sin(a + .1))
        ..close();
      canvas.drawPath(chemin, p);
    }
    canvas.drawRect(Rect.fromCenter(center: centre, width: 220, height: 220),
        Paint()..color = couleur.withValues(alpha: 0.15));
  }

  @override
  bool shouldRepaint(_RayonsPainter old) => old.angle != angle || old.couleur != couleur;
}

// ─── Révélation de dix objets ────────────────────────────────────────────────

class _RevelationMultiple extends StatelessWidget {
  final List<Item> objets;
  final double boucle;
  final double ecouleMs;
  final int Function(int) debutCarte;
  final int remboursement;
  final int? epiqueDans;
  final int? legendaireDans;
  final bool enCours;
  final VoidCallback onToucher;
  final VoidCallback onContinuer;

  const _RevelationMultiple({
    required this.objets,
    required this.boucle,
    required this.ecouleMs,
    required this.debutCarte,
    required this.remboursement,
    required this.epiqueDans,
    required this.legendaireDans,
    required this.enCours,
    required this.onToucher,
    required this.onContinuer,
  });

  @override
  Widget build(BuildContext context) {
    final lueur = (boucle * 9.6).floor().isEven;
    return GestureDetector(
      onTap: enCours ? onToucher : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const PixelFondPoints(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text('${objets.length} invocations',
                        style: PixelTextes.chiffres(16, PixelCouleurs.texte).copyWith(
                          shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(3, 3))],
                        )),
                  ),
                  const SizedBox(height: 8),
                  Text(enCours ? 'Touche l\'écran pour tout retourner.' : 'Tous les objets sont dans ton inventaire.',
                      style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3 / 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final (i, o) in objets.indexed)
                        _Carte(
                          objet: o,
                          // retournement en 4 paliers sur 0,45 s
                          retournement: parPaliers((ecouleMs - debutCarte(i)) / 450, 4),
                          brille: !enCours && o.rarity.index >= QuestRarity.legendary.index && lueur,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PixelCadre(
                    child: Column(
                      children: [
                        if (remboursement > 0)
                          _Ligne('Doublons convertis', '+$remboursement cristaux', AppColors.crystalBlue),
                        if (epiqueDans != null) _Ligne('Épique garanti dans', '$epiqueDans', AppColors.rarityEpic),
                        if (legendaireDans != null)
                          _Ligne('Légendaire garanti dans', '$legendaireDans', PixelCouleurs.orClair),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PixelBouton(libelle: enCours ? 'Tout révéler' : 'Continuer', onPressed: enCours ? onToucher : onContinuer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final Item objet;
  final double retournement;
  final bool brille;
  const _Carte({required this.objet, required this.retournement, required this.brille});

  @override
  Widget build(BuildContext context) {
    final couleur = AppColors.getRarityColor(objet.rarity.name);
    // Dos de carte jusqu'à mi-course (largeur 1 → 0), puis la face (0 → 1).
    final face = retournement >= .5;
    final visible = retournement >= 1;
    final largeur = math.max((1 - 2 * retournement).abs(), 0.04);
    return Semantics(
      label: visible ? '${objet.name}, ${libelleRarete(objet.rarity)}' : 'Carte non retournée',
      excludeSemantics: true,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(largeur, 1, 1),
        child: Container(
          decoration: BoxDecoration(
            color: face ? PixelCouleurs.panneau : PixelCouleurs.violet,
            border: Border.all(
                color: face ? (brille ? PixelCouleurs.orClair : couleur) : PixelCouleurs.violetClair,
                width: brille ? 5 : 3),
            boxShadow: const [BoxShadow(color: PixelCouleurs.abysse, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: face
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ItemIcon(item: objet, size: 44, showBackground: false, showRarityGlow: false, showRarityBorder: false),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(libelleRarete(objet.rarity), style: PixelTextes.chiffres(7, couleur)),
                    ),
                  ],
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String libelle;
  final String valeur;
  final Color couleur;
  const _Ligne(this.libelle, this.valeur, this.couleur);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(libelle, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux))),
            Text(valeur, style: PixelTextes.chiffres(11, couleur)),
          ],
        ),
      );
}
