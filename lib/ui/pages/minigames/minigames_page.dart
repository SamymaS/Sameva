import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_colors.dart';
import '../../../domain/services/minigame_service.dart';
import 'anagram_game_page.dart';
import 'memory_game_page.dart';
import 'numbers_game_page.dart';
import 'reaction_game_page.dart';
import 'sequence_game_page.dart';

/// Hub des mini-jeux.
class MinigamesPage extends StatefulWidget {
  const MinigamesPage({super.key});

  @override
  State<MinigamesPage> createState() => _MinigamesPageState();
}

class _MinigamesPageState extends State<MinigamesPage> with RouteAware {
  late final Box _settings;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings = Hive.box('settings');
    _ready = true;
  }


  Future<void> _play(String gameKey, Widget page) async {
    if (!MinigameService.canPlay(_settings, gameKey)) return;
    await MinigameService.recordPlay(_settings, gameKey);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();

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
            remaining: MinigameService.remainingPlays(_settings, 'memory'),
            onPlay: () => _play('memory', const MemoryGamePage()),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.flash_on,
            title: 'Réaction rapide',
            reward: 'Jusqu\'à 100 or (10 or / cible)',
            color: AppColors.primaryTurquoise,
            remaining: MinigameService.remainingPlays(_settings, 'reaction'),
            onPlay: () => _play('reaction', const ReactionGamePage()),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.calculate_outlined,
            title: 'Suite de nombres',
            reward: 'Jusqu\'à 100 or (20 or / réponse)',
            color: AppColors.gold,
            remaining: MinigameService.remainingPlays(_settings, 'numbers'),
            onPlay: () => _play('numbers', const NumbersGamePage()),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.touch_app,
            title: 'Tap Séquence',
            reward: 'Niveau × 15 or (max 100)',
            color: const Color(0xFF48BB78),
            remaining: MinigameService.remainingPlays(_settings, 'sequence'),
            onPlay: () => _play('sequence', const SequenceGamePage()),
          ),
          const SizedBox(height: 12),
          _GameTile(
            icon: Icons.sort_by_alpha,
            title: 'Anagramme',
            reward: 'Jusqu\'à 90 or (30 or / mot)',
            color: const Color(0xFFE53E3E),
            remaining: MinigameService.remainingPlays(_settings, 'anagram'),
            onPlay: () => _play('anagram', const AnagramGamePage()),
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
  final int remaining;
  final VoidCallback onPlay;

  const _GameTile({
    required this.icon,
    required this.title,
    required this.reward,
    required this.color,
    required this.remaining,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final canPlay = remaining > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: canPlay ? 0.4 : 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: canPlay ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: canPlay ? color : AppColors.textMuted, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: canPlay ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
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
            Text(
              canPlay
                  ? '$remaining partie${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}'
                  : 'Limite quotidienne atteinte',
              style: TextStyle(
                color: canPlay ? AppColors.success : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: canPlay ? onPlay : null,
          style: FilledButton.styleFrom(backgroundColor: color),
          child: const Text('Jouer'),
        ),
      ),
    );
  }
}
