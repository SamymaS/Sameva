import 'package:flutter/widgets.dart';

import 'pixel_sprite.dart';

/// États de MougiBot, l'esprit de l'Oracle (Paco en sweat sarcelle).
enum EtatMougiBot { repos, observe, accepte, refuse }

/// MougiBot animé en pixel art.
class MougiBotSprite extends StatelessWidget {
  const MougiBotSprite({super.key, required this.etat, this.cote = 96});

  final EtatMougiBot etat;
  final double cote;

  static const _libelles = {
    EtatMougiBot.repos: 'MougiBot attend ta photo',
    EtatMougiBot.observe: "MougiBot analyse la photo",
    EtatMougiBot.accepte: 'MougiBot valide la preuve',
    EtatMougiBot.refuse: 'MougiBot refuse la preuve',
  };

  @override
  Widget build(BuildContext context) => AvecManifeste(
        cote: cote,
        builder: (context, m) => PixelSprite(
          feuille: 'assets/sprites/mougibot.png',
          animation: m.animation('mougibot', etat.name),
          taille: m.taille('mougibot'),
          cote: cote,
          semanticLabel: _libelles[etat],
        ),
      );
}
