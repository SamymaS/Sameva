import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../../../core/avatar/apparence_avatar.dart';
import '../../../core/visuels/visuels.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';

/// Ce que porte l'avatar, en couches indépendantes de sa silhouette.
@immutable
class TenueAvatar {
  const TenueAvatar({this.haut, this.bas, this.chaussures, this.chapeau, this.styleChapeau = 0, this.aura});

  final Color? haut;
  final Color? bas;
  final Color? chaussures;
  final Color? chapeau;

  /// 0 aucun, 1 conique, 2 couronne, 3 bonnet, 4 bandana.
  final int styleChapeau;
  final Color? aura;

  static Color? _couleur(Item? objet) {
    final v = objet?.stats['colorValue'];
    return v == null ? null : Color(v);
  }

  /// Tenue lue depuis les cosmétiques équipés.
  factory TenueAvatar.depuisCosmetiques(Item? Function(String emplacement) cosmetique) {
    final chapeau = cosmetique('hat');
    return TenueAvatar(
      haut: _couleur(cosmetique('outfit')),
      bas: _couleur(cosmetique('pants')),
      chaussures: _couleur(cosmetique('shoes')),
      chapeau: _couleur(chapeau),
      styleChapeau: chapeau == null ? 0 : (chapeau.stats['styleIndex'] ?? 1),
      aura: _couleur(cosmetique('aura')),
    );
  }
}

/// Une couche de l'avatar : sa feuille d'images et la couleur qui la teinte.
typedef CoucheAvatar = ({String nom, Color? teinte});

/// Manifeste des couches de l'avatar (`assets/avatar/manifeste.json`, produit
/// par `tools/avatar3d/generer_avatar.py` avec Blender).
class ManifesteAvatar {
  ManifesteAvatar(this.dossier, Map<String, dynamic> json)
      : largeur = json['largeur'] as int,
        hauteur = json['hauteur'] as int,
        angles = json['angles'] as int,
        _couches = Map<String, String>.from(json['couches'] as Map);

  final String dossier;
  final int largeur;
  final int hauteur;
  final int angles;
  final Map<String, String> _couches;

  static final Map<String, Future<ManifesteAvatar>> _charges = {};
  static final Map<String, Future<ui.Image>> _feuilles = {};

  static Future<ManifesteAvatar> charger([AssetBundle? bundle]) {
    final dossier = Visuels.dossierAvatar;
    return _charges[dossier] ??= (bundle ?? rootBundle)
        .loadString('$dossier/manifeste.json')
        .then((s) => ManifesteAvatar(dossier, jsonDecode(s) as Map<String, dynamic>));
  }

  bool possede(String couche) => _couches.containsKey(couche);

  Future<ui.Image> feuille(String couche) => _feuilles['$dossier/$couche'] ??= () async {
        final data = await rootBundle.load('$dossier/${_couches[couche]}');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      }();

  static const _hautParDefaut = Color(0xFF4FD1C5);
  static const _basParDefaut = Color(0xFF3A4A66);
  static const _chaussuresParDefaut = Color(0xFF7A5230);
  static const _chapeauParDefaut = Color(0xFF805AD5);

  /// Les couches à empiler, de la plus profonde à la plus proche.
  ///
  /// Chaque couche a été rendue seule, masquée par les autres pièces du corps :
  /// l'empilement est juste sous tous les angles.
  List<CoucheAvatar> couches(CharacterAppearance a, TenueAvatar t) {
    final s = a.gender.name;
    final coiffure = 'cheveux_${a.hairStyle.name}';
    final cheveux = possede('${coiffure}_$s') ? '${coiffure}_$s' : coiffure;
    final chapeau = 'chapeau_${t.styleChapeau}';
    return [
      (nom: 'corps_$s', teinte: a.skinTone.color),
      (nom: 'bas_$s', teinte: t.bas ?? _basParDefaut),
      (nom: 'chaussures', teinte: t.chaussures ?? _chaussuresParDefaut),
      (nom: 'haut_$s', teinte: t.haut ?? _hautParDefaut),
      (nom: 'visage', teinte: null),
      (nom: 'sourcils', teinte: a.hairColor),
      (nom: cheveux, teinte: a.hairColor),
      if (t.styleChapeau > 0 && possede(chapeau)) (nom: chapeau, teinte: t.chapeau ?? _chapeauParDefaut),
    ].where((c) => possede(c.nom)).toList();
  }
}

/// Cadrage de l'avatar.
enum CadrageAvatar {
  /// Le personnage entier (format 1 : 2).
  entier,

  /// La tête et les épaules, dans un carré (vignettes, profil).
  buste,
}

/// L'avatar du joueur en 2.5D (ADR 0008).
///
/// Un personnage modélisé en 3D puis rendu en couches sous 8 angles : l'app
/// empile les couches et les teinte (peau, cheveux, cosmétiques). [angle] le
/// fait tourner (0 = de face). Les images viennent de `Visuels.dossierAvatar` :
/// la direction artistique remplacera le modèle sans toucher aux écrans.
class AvatarJoueur extends StatefulWidget {
  const AvatarJoueur({
    super.key,
    required this.apparence,
    this.tenue = const TenueAvatar(),
    this.hauteur = 160,
    this.angle = 0,
    this.cadrage = CadrageAvatar.entier,
    this.ombre = true,
    this.semanticLabel = 'Ton personnage',
  });

  final CharacterAppearance apparence;
  final TenueAvatar tenue;

  /// Hauteur du widget (côté du carré pour un buste).
  final double hauteur;

  /// Angle de vue, en huitièmes de tour.
  final int angle;
  final CadrageAvatar cadrage;

  /// Ombre au sol (personnage entier seulement).
  final bool ombre;
  final String? semanticLabel;

  @override
  State<AvatarJoueur> createState() => _AvatarJoueurState();
}

class _AvatarJoueurState extends State<AvatarJoueur> {
  ManifesteAvatar? _manifeste;
  final Map<String, ui.Image> _images = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void didUpdateWidget(AvatarJoueur old) {
    super.didUpdateWidget(old);
    _charger();
  }

  Future<void> _charger() async {
    try {
      final m = _manifeste ?? await ManifesteAvatar.charger();
      if (!mounted) return;
      _manifeste = m;
      for (final c in m.couches(widget.apparence, widget.tenue)) {
        if (_images.containsKey(c.nom)) continue;
        final img = await m.feuille(c.nom);
        if (!mounted) return;
        _images[c.nom] = img;
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Images absentes (tests sans bundle) : rien n'est dessiné.
    }
  }

  @override
  Widget build(BuildContext context) {
    final buste = widget.cadrage == CadrageAvatar.buste;
    final m = _manifeste;
    final taille = Size(buste ? widget.hauteur : widget.hauteur / 2, widget.hauteur);
    final contenu = SizedBox.fromSize(
      size: taille,
      child: m == null
          ? null
          : CustomPaint(
              painter: _PeintreAvatar(
                manifeste: m,
                couches: m.couches(widget.apparence, widget.tenue),
                images: Map.of(_images),
                angle: widget.angle % m.angles,
                buste: buste,
                aura: widget.tenue.aura,
                ombre: widget.ombre && !buste,
              ),
            ),
    );
    return widget.semanticLabel == null
        ? ExcludeSemantics(child: contenu)
        : Semantics(image: true, label: widget.semanticLabel, child: ExcludeSemantics(child: contenu));
  }
}

class _PeintreAvatar extends CustomPainter {
  _PeintreAvatar({
    required this.manifeste,
    required this.couches,
    required this.images,
    required this.angle,
    required this.buste,
    required this.aura,
    required this.ombre,
  });

  final ManifesteAvatar manifeste;
  final List<CoucheAvatar> couches;
  final Map<String, ui.Image> images;
  final int angle;
  final bool buste;
  final Color? aura;
  final bool ombre;

  /// Zone de la tête dans une image du personnage (fractions de l'image).
  static const _zoneBuste = Rect.fromLTWH(0.14, 0.12, 0.72, 0.36);

  @override
  void paint(Canvas canvas, Size size) {
    final l = manifeste.largeur.toDouble(), h = manifeste.hauteur.toDouble();
    final zone = buste
        ? Rect.fromLTWH(_zoneBuste.left * l, _zoneBuste.top * h, _zoneBuste.width * l, _zoneBuste.height * h)
        : Rect.fromLTWH(0, 0, l, h);
    final src = zone.shift(Offset(angle * l, 0));
    final dst = Offset.zero & size;

    if (aura != null) {
      final centre = Offset(size.width / 2, size.height * (buste ? 0.55 : 0.5));
      canvas.drawCircle(
        centre,
        size.shortestSide * 0.62,
        Paint()
          ..shader = RadialGradient(colors: [aura!.withValues(alpha: 0.55), aura!.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: centre, radius: size.shortestSide * 0.62)),
      );
    }
    if (ombre) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.925), width: size.width * 0.5, height: size.height * 0.035),
        Paint()..color = const Color(0x59000000),
      );
    }
    for (final c in couches) {
      final img = images[c.nom];
      if (img == null) continue;
      final pinceau = Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true;
      // Les couches sont rendues en blanc : la couleur se multiplie à l'ombrage.
      if (c.teinte != null) pinceau.colorFilter = ColorFilter.mode(c.teinte!, BlendMode.modulate);
      canvas.drawImageRect(img, src, dst, pinceau);
    }
  }

  @override
  bool shouldRepaint(_PeintreAvatar old) =>
      old.angle != angle ||
      old.buste != buste ||
      old.aura != aura ||
      old.images.length != images.length ||
      !_memesCouches(old.couches, couches);

  static bool _memesCouches(List<CoucheAvatar> a, List<CoucheAvatar> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].nom != b[i].nom || a[i].teinte != b[i].teinte) return false;
    }
    return true;
  }
}

/// L'avatar du joueur connecté : apparence enregistrée et cosmétiques équipés.
class AvatarJoueurConnecte extends ConsumerWidget {
  const AvatarJoueurConnecte({
    super.key,
    this.hauteur = 160,
    this.angle = 0,
    this.cadrage = CadrageAvatar.entier,
    this.semanticLabel = 'Ton personnage',
  });

  final double hauteur;
  final int angle;
  final CadrageAvatar cadrage;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apparence = ref.watch(apparenceAvatarProvider);
    final equipement = p.Provider.of<EquipmentViewModel>(context);
    return AvatarJoueur(
      apparence: apparence,
      tenue: TenueAvatar.depuisCosmetiques(equipement.getCosmeticSlot),
      hauteur: hauteur,
      angle: angle,
      cadrage: cadrage,
      semanticLabel: semanticLabel,
    );
  }
}
