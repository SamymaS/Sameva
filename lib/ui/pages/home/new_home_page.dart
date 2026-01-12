import 'package:flutter/material.dart';
import '../../widgets/fantasy/fantasy_button.dart';
import '../../widgets/fantasy/animated_background.dart';
import '../quest/fantasy_create_quest_page.dart';
import '../../theme/app_colors.dart';

/// ACCUEIL — Page d'accueil simplifiée
class NewHomePage extends StatelessWidget {
  const NewHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond animé
          const Positioned.fill(
            child: AnimatedBackground(),
          ),
          // Contenu
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // En-tête avec boutons d'accès rapide
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pushNamed('/profile'),
                        tooltip: 'Profil',
                      ),
                      const Text(
                        'Sameva',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pushNamed('/settings'),
                        tooltip: 'Paramètres',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Bouton créer quête
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FantasyButton(
                    label: 'Créer une quête',
                    icon: Icons.add,
                    glowColor: AppColors.gold,
                    onPressed: () {
                      Navigator.of(context).pushNamed('/create-quest');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Section Quêtes du jour
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quêtes du jour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigation vers la page Quêtes via l'index
                          // Note: La navigation se fait via le bottomNavigationBar
                          // Pour l'instant, on peut utiliser une route nommée
                        },
                        child: Text(
                          'Voir toutes',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Liste horizontale de quêtes
                SizedBox(
                  height: 140, // Augmenté pour éviter le débordement
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: const [
                      _QuestCard(title: 'Aller au sport', color: Color(0xFF22C55E)),
                      _QuestCard(title: 'Lire 20 min', color: Color(0xFF60A5FA)),
                      _QuestCard(title: 'Projet cours', color: Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String title;
  final Color color;

  const _QuestCard({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.3,
              color: color,
              backgroundColor: const Color(0xFF1B2336),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '30%',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
