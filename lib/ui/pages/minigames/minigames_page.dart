import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'anagram_game_page.dart';
import 'memory_game_page.dart';
import 'numbers_game_page.dart';
import 'reaction_game_page.dart';
import 'sequence_game_page.dart';

/// Hub des mini-jeux.
class MinigamesPage extends StatelessWidget {
  const MinigamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Mini-Jeux',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GameTile(
            icon: Icons.extension_outlined,
            title: 'Mémoire de sorts',
            reward: '10–100 or selon votre temps',
            color: AppColors.secondaryViolet,
            onPlay: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MemoryGamePage()),
            ),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.flash_on,
            title: 'Réaction rapide',
            reward: 'Jusqu\'à 100 or (10 or / cible)',
            color: AppColors.primaryTurquoise,
            onPlay: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReactionGamePage()),
            ),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.calculate_outlined,
            title: 'Suite de nombres',
            reward: 'Jusqu\'à 100 or (20 or / réponse)',
            color: AppColors.gold,
            onPlay: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NumbersGamePage()),
            ),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.touch_app,
            title: 'Tap Séquence',
            reward: 'Niveau × 15 or (max 100)',
            color: const Color(0xFF48BB78),
            onPlay: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SequenceGamePage()),
            ),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.sort_by_alpha,
            title: 'Anagramme',
            reward: 'Jusqu\'à 90 or (30 or / mot)',
            color: const Color(0xFFE53E3E),
            onPlay: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AnagramGamePage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reward;
  final Color color;
  final VoidCallback onPlay;

  const _GameTile({
    required this.icon,
    required this.title,
    required this.reward,
    required this.color,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.gold, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reward,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Disponible maintenant !',
              style: TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: onPlay,
          style: FilledButton.styleFrom(backgroundColor: color),
          child: const Text('Jouer'),
        ),
      ),
    );
  }
}
