import 'package:flutter/material.dart';

import '../../../data/models/item_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/item_icon.dart';
import '../../widgets/pixel/pixel_ui.dart';
import 'sequence_invocation.dart' show libelleRarete;

/// Portail au repos (maquette « Portail (repos) ») : anneaux pixelisés qui
/// pulsent, étincelles qui clignotent, essence qui flotte. Tout est piloté par
/// une seule horloge en boucle de 4,8 s ([horloge]).
class PortailRepos extends StatelessWidget {
  final Animation<double> horloge;
  const PortailRepos({super.key, required this.horloge});

  static const _etincelles = [
    (x: -105.0, y: -60.0, cote: 8.0, couleur: PixelCouleurs.orClair, decalage: 0.0),
    (x: 95.0, y: -22.0, cote: 8.0, couleur: Color(0xFFE9D5FF), decalage: 1 / 3),
    (x: -78.0, y: 78.0, cote: 6.0, couleur: AppColors.crystalBlue, decalage: 2 / 3),
    (x: 82.0, y: 90.0, cote: 6.0, couleur: PixelCouleurs.orClair, decalage: 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: horloge,
      builder: (_, __) {
        final t = horloge.value;
        // Pulsation : 3 paliers d'opacité, aller-retour en 2 s.
        final aller = fraction(t * 1.2);
        final pulse = 0.55 + 0.45 * parPaliers(aller < .5 ? aller * 2 : 2 - aller * 2, 3);
        // Flottement de 12 px en 4 paliers, aller-retour en 1,6 s.
        final f = fraction(t * 1.5);
        final flotte = -12 * parPaliers(f < .5 ? f * 2 : 2 - f * 2, 4);
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: pulse, child: const PixelAnneau(cote: 268, couleur: PixelCouleurs.violetSombre)),
            const PixelAnneau(cote: 236, couleur: PixelCouleurs.violet),
            const PixelAnneau(cote: 212, couleur: PixelCouleurs.violetClair),
            const PixelAnneau(cote: 196, couleur: PixelCouleurs.panneau),
            Opacity(opacity: pulse, child: const PixelAnneau(cote: 160, couleur: PixelCouleurs.panneauProfond)),
            for (final e in _etincelles)
              Transform.translate(
                offset: Offset(e.x, e.y),
                // Clignotement : allumée la moitié du temps, toutes les 1,2 s.
                child: Opacity(
                  opacity: fraction(t * 4 + e.decalage) < .5 ? 1 : .15,
                  child: Container(width: e.cote, height: e.cote, color: e.couleur),
                ),
              ),
            Transform.translate(
              offset: Offset(0, flotte),
              child: Semantics(
                image: true,
                label: 'Essence mystique au cœur du portail',
                child: Image.asset('assets/sprites/objets/material_essence.png',
                    width: 96, height: 96, fit: BoxFit.contain,
                    filterQuality: FilterQuality.none, isAntiAlias: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Jauge d'une garantie : progression vers le seuil du serveur. Les petits
/// seuils (20) sont dessinés en cases, les grands en barre pleine.
class JaugeGarantie extends StatelessWidget {
  final String libelle;
  final int actuel;
  final int seuil;
  final Color couleur;

  const JaugeGarantie({
    super.key,
    required this.libelle,
    required this.actuel,
    required this.seuil,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final rempli = actuel.clamp(0, seuil);
    final reste = seuil - rempli;
    return Semantics(
      label: reste == 0 ? '$libelle au prochain tirage' : '$libelle dans $reste tirages',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(libelle, style: PixelTextes.corps(15, couleur: couleur, poids: FontWeight.w600))),
              Text('$rempli/$seuil', style: PixelTextes.chiffres(10, PixelCouleurs.texteDoux)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 10,
            child: seuil <= 30
                ? Row(
                    // étirer : une case sans enfant aurait sinon une hauteur nulle
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < seuil; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(child: ColoredBox(color: i < rempli ? couleur : PixelCouleurs.violetSombre)),
                      ],
                    ],
                  )
                : ColoredBox(
                    color: PixelCouleurs.violetSombre,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rempli / seuil,
                      child: ColoredBox(color: couleur),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Derniers tirages : une rangée d'icônes encadrées de la couleur de rareté.
class DerniersTirages extends StatelessWidget {
  final List<Item> objets;
  const DerniersTirages({super.key, required this.objets});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Derniers tirages', style: PixelTextes.chiffres(11, PixelCouleurs.texte)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in objets)
              Semantics(
                label: '${o.name}, ${libelleRarete(o.rarity)}',
                excludeSemantics: true,
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: PixelCouleurs.panneau,
                    border: Border.all(color: AppColors.getRarityColor(o.rarity.name), width: 2),
                  ),
                  child: ItemIcon(item: o, size: 32, showBackground: false, showRarityGlow: false, showRarityBorder: false),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
