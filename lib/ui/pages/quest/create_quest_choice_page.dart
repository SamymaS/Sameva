import 'package:flutter/material.dart';
import '../../widgets/pixel/mougibot_sprite.dart';
import '../../widgets/pixel/pixel_ui.dart';
import 'create_quest_by_theme_page.dart';
import 'create_quest_page.dart';
import 'generate_quests_page.dart';

/// Écran de choix : par thème (tâches préconfigurées), générée par MougiBot ou
/// quête personnalisée. Style pixel : trois cartes à bord épais.
class CreateQuestChoicePage extends StatelessWidget {
  const CreateQuestChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      appBar: AppBar(
        backgroundColor: PixelCouleurs.nuit,
        surfaceTintColor: Colors.transparent,
        foregroundColor: PixelCouleurs.texte,
        title: Text(
          'Créer une quête',
          style: PixelTextes.chiffres(13, PixelCouleurs.texte).copyWith(
            shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(2, 2))],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Comment veux-tu créer ta quête ?',
              style: PixelTextes.corps(17, couleur: PixelCouleurs.texteDoux)),
          const SizedBox(height: 16),
          _CarteChoix(
            icone: const Icon(Icons.category_outlined, color: PixelCouleurs.orClair, size: 28),
            accent: PixelCouleurs.or,
            titre: 'Par thème (Sport, Loisir, Maison)',
            description: 'Choisis une tâche préconfigurée dans un thème.',
            onTap: () async {
              // Attend le résultat : true = quête créée, on se ferme aussi.
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const CreateQuestByThemePage()),
              );
              if (created == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          _CarteChoix(
            icone: const MougiBotSprite(etat: EtatMougiBot.repos, cote: 48),
            accent: PixelCouleurs.oracle,
            titre: 'Générer avec IA',
            description: 'MougiBot propose des quêtes adaptées à ton profil.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GenerateQuestsPage()),
            ),
          ),
          _CarteChoix(
            icone: const Icon(Icons.edit_note, color: PixelCouleurs.violetClair, size: 30),
            accent: PixelCouleurs.violet,
            titre: 'Quête personnalisée',
            description: 'Tu sais déjà ce que tu veux faire ? Crée une quête sur mesure.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateQuestPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteChoix extends StatelessWidget {
  final Widget icone;
  final Color accent;
  final String titre;
  final String description;
  final VoidCallback onTap;

  const _CarteChoix({
    required this.icone,
    required this.accent,
    required this.titre,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: PixelCadre(
              bord: accent,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PixelCouleurs.panneauProfond,
                      border: Border.all(color: accent, width: 2),
                    ),
                    child: icone,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: PixelTextes.corps(17, poids: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(description, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: PixelCouleurs.texteDoux),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
