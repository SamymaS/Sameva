import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../../../core/avatar/apparence_avatar.dart';
import '../../../core/visuels/visuels.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';
import '../character/character_painter.dart';

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

/// L'avatar du joueur (ADR 0008).
///
/// Tant que la direction artistique n'a pas livré son personnage, il est
/// dessiné par le code à partir de l'[apparence] et de la [tenue]. Dès qu'un
/// visuel `avatar` figure au manifeste de la DA, c'est lui qui est affiché :
/// les écrans qui montrent l'avatar ne changent pas.
class AvatarJoueur extends StatefulWidget {
  const AvatarJoueur({
    super.key,
    required this.apparence,
    this.tenue = const TenueAvatar(),
    this.hauteur = 160,
    this.anime = true,
    this.semanticLabel = 'Ton personnage',
  });

  final CharacterAppearance apparence;
  final TenueAvatar tenue;
  final double hauteur;

  /// Léger flottement au repos (coupé si l'utilisateur réduit les animations).
  final bool anime;
  final String? semanticLabel;

  /// Proportions du personnage dessiné (largeur / hauteur).
  static const proportion = 140 / 290;

  @override
  State<AvatarJoueur> createState() => _AvatarJoueurState();
}

class _AvatarJoueurState extends State<AvatarJoueur> with SingleTickerProviderStateMixin {
  late final AnimationController _repos =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _regler();
  }

  @override
  void didUpdateWidget(AvatarJoueur old) {
    super.didUpdateWidget(old);
    _regler();
  }

  void _regler() {
    final reduit = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final doitBouger = widget.anime && !reduit;
    if (doitBouger && !_repos.isAnimating) _repos.repeat(reverse: true);
    if (!doitBouger && _repos.isAnimating) _repos.stop();
  }

  @override
  void dispose() {
    _repos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hauteur;
    final l = h * AvatarJoueur.proportion;
    final visuel = Visuels.avatar;
    final t = widget.tenue;

    final Widget corps = visuel != null
        ? Image.asset(visuel.chemin,
            width: l, height: h, fit: BoxFit.contain, filterQuality: visuel.filtre, excludeFromSemantics: true)
        : CustomPaint(
            size: Size(l, h),
            painter: CharacterPainter(
              appearance: widget.apparence,
              outfitColor: t.haut ?? const Color(0xFF4FD1C5),
              pantsColor: t.bas ?? const Color(0xFF2D3748),
              shoesColor: t.chaussures ?? const Color(0xFF3D2B1A),
              hatColor: t.chapeau ?? const Color(0xFF805AD5),
              hatStyle: t.styleChapeau,
              auraColor: t.aura,
            ),
          );

    final contenu = SizedBox(
      width: l,
      height: h,
      child: AnimatedBuilder(
        animation: _repos,
        builder: (_, enfant) => Transform.translate(
          offset: Offset(0, -h * 0.012 * Curves.easeInOut.transform(_repos.value)),
          child: enfant,
        ),
        child: corps,
      ),
    );
    return widget.semanticLabel == null
        ? ExcludeSemantics(child: contenu)
        : Semantics(image: true, label: widget.semanticLabel, child: ExcludeSemantics(child: contenu));
  }
}

/// L'avatar du joueur connecté : apparence enregistrée et cosmétiques équipés.
class AvatarJoueurConnecte extends ConsumerWidget {
  const AvatarJoueurConnecte({super.key, this.hauteur = 160, this.anime = true, this.semanticLabel = 'Ton personnage'});

  final double hauteur;
  final bool anime;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apparence = ref.watch(apparenceAvatarProvider);
    final equipement = p.Provider.of<EquipmentViewModel>(context);
    return AvatarJoueur(
      apparence: apparence,
      tenue: TenueAvatar.depuisCosmetiques(equipement.getCosmeticSlot),
      hauteur: hauteur,
      anime: anime,
      semanticLabel: semanticLabel,
    );
  }
}
