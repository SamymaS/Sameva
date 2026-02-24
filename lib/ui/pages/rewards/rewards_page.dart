import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Récompenses — Goal Gradient (progression XP visible), Jakob (listes familières).
/// Miller : peu d'éléments affichés.
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final stats = playerProvider.stats;
    final level = stats?.level ?? 1;
    final experience = stats?.experience ?? 0;
    final gold = stats?.gold ?? 0;
    final streak = stats?.streak ?? 0;

    // P0.2 : utilise experienceForLevel() — même formule que addExperience()
    // (100 × level × 1.5), au lieu du calcul incorrect `level * 100`.
    final xpNeeded = playerProvider.experienceForLevel(level);
    final progress = xpNeeded > 0 ? (experience / xpNeeded).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Récompenses'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Niveau $level',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 4),
            Text(
              '$experience / $xpNeeded XP vers le niveau ${level + 1}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.monetization_on, color: AppColors.primary),
              title: const Text('Or'),
              trailing: Text('$gold', style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: Icon(Icons.local_fire_department, color: AppColors.warning),
              title: const Text('Série de jours'),
              trailing: Text(
                '$streak jour${streak > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Continuez à valider des quêtes pour gagner de l\'XP et progresser.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
