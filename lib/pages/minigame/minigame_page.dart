import 'package:flutter/material.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';
import 'games/memory_quest_game.dart';
import 'games/speed_challenge_game.dart';
import 'games/puzzle_quest_game.dart';
import 'games/platformer_game.dart';
import 'games/runner_game.dart';
import 'games/match3_game.dart';

/// Page de mini-jeux
class MiniGamePage extends StatelessWidget {
  const MiniGamePage({super.key});

  // Liste des mini-jeux disponibles
  static const List<Map<String, dynamic>> _minigames = [
    {
      'name': 'Plateformer',
      'description': '3 niveaux à compléter',
      'icon': Icons.gamepad,
      'color': Color(0xFF60A5FA),
      'unlocked': true,
      'game': 'platformer',
    },
    {
      'name': 'Runner Endless',
      'description': 'Course infinie',
      'icon': Icons.directions_run,
      'color': Color(0xFF22C55E),
      'unlocked': true,
      'game': 'runner',
    },
    {
      'name': 'Match-3',
      'description': 'Alignez les gemmes',
      'icon': Icons.grid_view,
      'color': Color(0xFFA855F7),
      'unlocked': true,
      'game': 'match3',
    },
    {
      'name': 'Memory Quest',
      'description': 'Testez votre mémoire',
      'icon': Icons.memory,
      'color': Color(0xFFFF9800),
      'unlocked': true,
      'game': 'memory',
    },
    {
      'name': 'Speed Challenge',
      'description': 'Complétez rapidement',
      'icon': Icons.speed,
      'color': Color(0xFFE91E63),
      'unlocked': true,
      'game': 'speed',
    },
    {
      'name': 'Puzzle Quest',
      'description': 'Résolvez des puzzles',
      'icon': Icons.extension,
      'color': Color(0xFF00BCD4),
      'unlocked': true,
      'game': 'puzzle',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mini-Jeux',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amusez-vous tout en progressant',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  FantasyBadge(
                    label: '${_minigames.where((g) => g['unlocked'] == true).length}/${_minigames.length}',
                    variant: BadgeVariant.secondary,
                  ),
                ],
              ),
            ),
            // Liste des mini-jeux
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1, // Augmenté pour éviter le débordement
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _minigames.length,
                itemBuilder: (context, index) {
                  final game = _minigames[index];
                  return _MinigameCard(
                    name: game['name'] as String,
                    description: game['description'] as String,
                    icon: game['icon'] as IconData,
                    color: game['color'] as Color,
                    isUnlocked: game['unlocked'] as bool,
                    onTap: () {
                      if (game['unlocked'] as bool) {
                        _launchGame(context, game['game'] as String?);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${game['name']} sera bientôt disponible !'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, String? gameType) {
    Widget gamePage;
    
    switch (gameType) {
      case 'platformer':
        gamePage = const PlatformerGame();
        break;
      case 'runner':
        gamePage = const RunnerGame();
        break;
      case 'match3':
        gamePage = const Match3Game();
        break;
      case 'memory':
        gamePage = const MemoryQuestGame();
        break;
      case 'speed':
        gamePage = const SpeedChallengeGame();
        break;
      case 'puzzle':
        gamePage = const PuzzleQuestGame();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jeu non disponible'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => gamePage,
      ),
    );
  }
}

class _MinigameCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _MinigameCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FantasyCard(
      backgroundColor: isUnlocked ? AppColors.card : AppColors.card.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône du mini-jeu
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isUnlocked ? color : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              // Nom du mini-jeu
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUnlocked ? AppColors.textSecondary : AppColors.textMuted,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Badge de statut
              FantasyBadge(
                label: isUnlocked ? 'Disponible' : 'Verrouillé',
                variant: isUnlocked ? BadgeVariant.secondary : BadgeVariant.outline,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
