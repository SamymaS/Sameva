import 'package:flutter/material.dart';
import '../../../domain/services/achievement_service.dart';
import '../../theme/app_colors.dart';

/// Page de tous les achievements du joueur.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = AchievementService.getUnlocked();
    final all = AchievementService.all;
    final unlockedCount = all.where((a) => unlocked.containsKey(a.id)).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Succès',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$unlockedCount / ${all.length}',
                style: const TextStyle(
                    color: AppColors.primaryTurquoise,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression globale
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: all.isEmpty ? 0 : unlockedCount / all.length,
                minHeight: 6,
                backgroundColor: AppColors.backgroundDarkPanel,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryTurquoise),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: all.length,
              itemBuilder: (context, i) {
                final a = all[i];
                final isUnlocked = unlocked.containsKey(a.id);
                final unlockedAt = isUnlocked
                    ? DateTime.tryParse(unlocked[a.id]!)
                    : null;
                return _AchievementCard(
                  achievement: a,
                  isUnlocked: isUnlocked,
                  unlockedAt: unlockedAt,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked
        ? achievement.color
        : AppColors.textMuted.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.1)
              : AppColors.backgroundDarkPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnlocked
                ? achievement.color.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.15),
            width: isUnlocked ? 1.5 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: achievement.color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(achievement.icon, color: color, size: 32),
                if (!isUnlocked)
                  const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked ? achievement.name : '???',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                _dateLabel(unlockedAt!),
                style: TextStyle(
                    color: achievement.color.withValues(alpha: 0.8),
                    fontSize: 9),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(achievement.icon,
                color: isUnlocked
                    ? achievement.color
                    : AppColors.textMuted,
                size: 48),
            const SizedBox(height: 12),
            Text(
              isUnlocked ? achievement.name : '???',
              style: TextStyle(
                color: isUnlocked
                    ? achievement.color
                    : AppColors.textMuted,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked
                  ? achievement.description
                  : 'Continuez à jouer pour débloquer ce succès.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Débloqué le ${_dateLabel(unlockedAt!)}',
                style: TextStyle(
                    color: achievement.color.withValues(alpha: 0.7),
                    fontSize: 11),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer',
                style: TextStyle(color: AppColors.primaryTurquoise)),
          ),
        ],
      ),
    );
  }
}
