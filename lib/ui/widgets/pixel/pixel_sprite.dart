import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Une animation d'une feuille de sprites : indices d'images et durées.
class AnimationPixel {
  /// [images] et [dureesMs] ont la même longueur (vérifié par les tests du manifeste).
  const AnimationPixel(this.images, this.dureesMs, {this.boucle = true});

  final List<int> images;
  final List<int> dureesMs;
  final bool boucle;

  int get dureeTotaleMs => dureesMs.fold(0, (a, b) => a + b);

  /// Image à afficher après [ecouleMs] millisecondes.
  int imageA(int ecouleMs) {
    final total = dureeTotaleMs;
    if (total <= 0) return images.first;
    var t = boucle ? ecouleMs % total : ecouleMs.clamp(0, total - 1);
    for (var i = 0; i < images.length; i++) {
      if (t < dureesMs[i]) return images[i];
      t -= dureesMs[i];
    }
    return images.last;
  }

  factory AnimationPixel.fromJson(Map<String, dynamic> j) => AnimationPixel(
        (j['images'] as List).cast<int>(),
        (j['durees_ms'] as List).cast<int>(),
        boucle: j['boucle'] as bool? ?? true,
      );

  // Égalité par valeur : le manifeste recrée l'objet à chaque build, et une
  // même animation ne doit pas redémarrer pour autant.
  @override
  bool operator ==(Object other) =>
      other is AnimationPixel &&
      other.boucle == boucle &&
      listEquals(other.images, images) &&
      listEquals(other.dureesMs, dureesMs);

  @override
  int get hashCode => Object.hash(boucle, Object.hashAll(images), Object.hashAll(dureesMs));
}

/// Manifeste `assets/sprites/animations.json` (généré par tools/pixel).
class ManifestePixel {
  ManifestePixel(this._json);
  final Map<String, dynamic> _json;

  static const chemin = 'assets/sprites/animations.json';
  static Future<ManifestePixel>? _charge;

  static Future<ManifestePixel> charger([AssetBundle? bundle]) => _charge ??= (bundle ?? rootBundle)
      .loadString(chemin)
      .then((s) => ManifestePixel(jsonDecode(s) as Map<String, dynamic>));

  /// Côté (px) des images d'un groupe (chat, mougibot).
  int taille(String groupe) =>
      ((_json[groupe] as Map<String, dynamic>)['taille'] as int?) ?? 32;

  AnimationPixel animation(String groupe, String nom) {
    final g = Map<String, dynamic>.of(_json[groupe] as Map<String, dynamic>)..remove('taille');
    final a = (g[nom] ?? g.values.first) as Map<String, dynamic>;
    return AnimationPixel.fromJson(a);
  }

  /// Icône d'objet portée comme chapeau par le chat (ex. `crown` -> `hat_crown_gold`).
  String? chapeau(String id) => (_json['chapeaux'] as Map<String, dynamic>?)?[id] as String?;
}

/// Cache des feuilles décodées (une seule image GPU par feuille).
class _Feuilles {
  static final Map<String, Future<ui.Image>> _cache = {};

  static Future<ui.Image> charger(String asset) => _cache[asset] ??= () async {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      }();
}

/// Affiche une image (ou une animation) d'une feuille de sprites pixel art.
///
/// L'agrandissement est toujours un multiple entier de la taille du sprite,
/// sans lissage : les pixels restent nets à toutes les tailles d'écran.
class PixelSprite extends StatefulWidget {
  const PixelSprite({
    super.key,
    required this.feuille,
    this.animation,
    this.image = 0,
    this.taille = 32,
    required this.cote,
    this.semanticLabel,
  });

  /// Chemin de la feuille (une ligne d'images carrées de [taille] px).
  final String feuille;

  /// Animation à jouer ; sinon l'image fixe [image].
  final AnimationPixel? animation;
  final int image;
  final int taille;

  /// Côté du widget en pixels logiques.
  final double cote;
  final String? semanticLabel;

  @override
  State<PixelSprite> createState() => _PixelSpriteState();
}

// TickerProviderStateMixin : un changement d'animation remplace le ticker.
class _PixelSpriteState extends State<PixelSprite> with TickerProviderStateMixin {
  ui.Image? _feuille;
  Ticker? _ticker;
  int _image = 0;

  @override
  void initState() {
    super.initState();
    _image = widget.image;
    _charger();
    _demarrer();
  }

  @override
  void didUpdateWidget(PixelSprite old) {
    super.didUpdateWidget(old);
    if (old.feuille != widget.feuille) _charger();
    if (old.animation != widget.animation || old.image != widget.image) {
      _ticker?.dispose();
      _ticker = null;
      _image = widget.image;
      _demarrer();
    }
  }

  Future<void> _charger() async {
    try {
      final img = await _Feuilles.charger(widget.feuille);
      if (mounted) setState(() => _feuille = img);
    } catch (_) {
      // Asset absent (tests sans bundle) : rien n'est dessiné.
    }
  }

  void _demarrer() {
    final anim = widget.animation;
    if (anim == null || anim.images.length < 2) {
      if (anim != null) _image = anim.images.first;
      return;
    }
    // Animations coupées si l'utilisateur réduit les mouvements.
    final reduit = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduit) {
      _image = anim.images.first;
      return;
    }
    _ticker = createTicker((ecoule) {
      final i = anim.imageA(ecoule.inMilliseconds);
      if (i != _image) setState(() => _image = i);
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _feuille;
    final enfant = SizedBox.square(
      dimension: widget.cote,
      child: f == null
          ? null
          : CustomPaint(
              painter: _PeintreSprite(f, _image, widget.taille, MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0)),
    );
    return widget.semanticLabel == null
        ? ExcludeSemantics(child: enfant)
        : Semantics(image: true, label: widget.semanticLabel, child: enfant);
  }
}

class _PeintreSprite extends CustomPainter {
  _PeintreSprite(this.feuille, this.image, this.taille, this.dpr);
  final ui.Image feuille;
  final int image;
  final int taille;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final physique = size.shortestSide * dpr;
    // Agrandissement entier dès x2 (pixels réguliers) ; en dessous, le sprite
    // remplit sa place quitte à avoir des pixels inégaux (petites vignettes).
    final brut = physique / taille;
    final facteur = brut >= 2 ? brut.floorToDouble() : brut;
    final cote = facteur * taille / dpr;
    final dx = (size.width - cote) / 2, dy = (size.height - cote) / 2;
    final src = Rect.fromLTWH((image * taille).toDouble(), 0, taille.toDouble(), taille.toDouble());
    final dst = Rect.fromLTWH(dx, dy, cote, cote);
    canvas.drawImageRect(feuille, src, dst, Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_PeintreSprite old) =>
      old.image != image || old.feuille != feuille || old.dpr != dpr;
}

/// Charge le manifeste puis construit [builder] (rien tant qu'il n'est pas prêt).
class AvecManifeste extends StatelessWidget {
  const AvecManifeste({super.key, required this.builder, this.cote = 0});
  final Widget Function(BuildContext, ManifestePixel) builder;
  final double cote;

  @override
  Widget build(BuildContext context) => FutureBuilder<ManifestePixel>(
        future: ManifestePixel.charger(),
        builder: (context, s) => s.hasData ? builder(context, s.data!) : SizedBox.square(dimension: cote),
      );
}

/// Préchauffe le manifeste au démarrage (évite un blanc à la première image).
Future<void> prechargerPixel() async {
  try {
    await ManifestePixel.charger();
  } catch (_) {}
}

// Exposé pour les tests.
@visibleForTesting
void reinitialiserCachePixel() {
  ManifestePixel._charge = null;
}
