import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/minimalist/hud_header.dart';
import '../../widgets/magical/animated_background.dart';
import '../../widgets/magical/glowing_card.dart';
import '../home/widgets/player_stats_card.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/bonus_malus_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final username = authUser?.userMetadata?['display_name'] as String? ??
        authUser?.userMetadata?['name'] as String? ??
        (authUser?.email?.split('@').first ?? 'Héros');
    final stats = playerProvider.stats;

    return Scaffold(
      body: AnimatedMagicalBackground(
        child: Stack(
          children: [
            // Header HUD
            HUDHeader(
              level: stats?.level ?? 1,
              experience: stats?.experience ?? 0,
              maxExperience:
                  playerProvider.experienceForLevel(stats?.level ?? 1),
              healthPoints: stats?.healthPoints ?? 100,
              maxHealthPoints: stats?.maxHealthPoints ?? 100,
              gold: stats?.gold ?? 0,
              crystals: stats?.crystals ?? 0,
              onSettingsTap: () {},
            ),
            // Contenu
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                children: [
                  // Titre de page centré
                  Center(
                    child: Text(
                      'Le Hall des Héros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cinzel',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Avatar avec bouton d'édition
                  _buildAvatarSection(username),
                  const SizedBox(height: 24),
                  // Carte de stats
                  const PlayerStatsCard(),
                  const SizedBox(height: 16),
                  // Section Statistiques supplémentaires
                  _buildExtraStatsSection(context, stats),
                  const SizedBox(height: 16),
                  // Section Achievements
                  _buildAchievementsSection(stats),
                  const SizedBox(height: 16),
                  // Section Historique
                  _buildHistorySection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String username) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryTurquoise,
                  size: 48,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurquoise,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTurquoise.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Aventurier',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtraStatsSection(BuildContext context, PlayerStats? stats) {
    if (stats == null) return const SizedBox.shrink();

    final questProvider = context.watch<QuestProvider>();
    final bonusMalus = BonusMalusService.calculateTotalBonusMalus(
      completedQuestsToday: questProvider.getCompletedQuestsToday(),
      activeQuestsToday: questProvider.getActiveQuestsToday(),
      missedQuests: questProvider.getMissedQuests(),
      streak: stats.streak,
      lastActiveDate: stats.lastActiveDate,
    );

    return GlowingCard(
      glowColor: AppColors.primaryTurquoise,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cinzel',
            ),
          ),
          const SizedBox(height: 16),
          // Grille 2x2 de stats
          Row(
            children: [
              Expanded(
                child: _statTile(
                  Icons.check_circle_outline,
                  '${stats.totalQuestsCompleted}',
                  'Quêtes',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  Icons.local_fire_department,
                  '${stats.streak}j',
                  'Streak',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  Icons.emoji_events,
                  '${stats.maxStreak}j',
                  'Record',
                  AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  Icons.speed,
                  'x${bonusMalus.toStringAsFixed(2)}',
                  'Multiplicateur',
                  bonusMalus >= 1.0
                      ? AppColors.primaryTurquoise
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de moral
          Text(
            'Moral',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.moral,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.moral > 0.5
                    ? AppColors.success
                    : (stats.moral > 0.2 ? AppColors.warning : Colors.red),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(stats.moral * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(PlayerStats? stats) {
    final achievements = stats?.achievements ?? {};
    final definitions = PlayerProvider.achievementDefinitions;

    return GlowingCard(
      glowColor: AppColors.primaryTurquoise,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Succès et Hauts-Faits',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cinzel',
                ),
              ),
              Text(
                '${achievements.length}/${definitions.length}',
                style: TextStyle(
                  color: AppColors.primaryTurquoise,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: definitions.length,
            itemBuilder: (context, index) {
              final def = definitions[index];
              final isUnlocked = achievements.containsKey(def['id']);
              return _AchievementBadge(
                name: def['name']!,
                description: def['description']!,
                iconName: def['icon']!,
                isUnlocked: isUnlocked,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Consumer<QuestProvider>(
      builder: (context, questProvider, _) {
        final completed = questProvider.completedQuests;
        // Trier par date de complétion (plus récentes d'abord) et limiter à 10
        final recent = List.of(completed)
          ..sort((a, b) {
            final aDate = a.completedAt ?? a.createdAt;
            final bDate = b.completedAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });
        final limited = recent.take(10).toList();

        return GlowingCard(
          glowColor: AppColors.secondaryViolet,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des Activités',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cinzel',
                ),
              ),
              const SizedBox(height: 12),
              if (limited.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Aucune quête complétée pour le moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...limited.map((quest) => _buildHistoryItem(quest)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(Quest quest) {
    final completedAt = quest.completedAt;
    final dateStr = completedAt != null
        ? '${completedAt.day.toString().padLeft(2, '0')}/${completedAt.month.toString().padLeft(2, '0')}/${completedAt.year}'
        : 'Date inconnue';
    final xpReward = 10 * quest.difficulty;
    final goldReward = 25 * quest.difficulty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${xpReward}XP  +${goldReward}G',
            style: TextStyle(
              color: AppColors.primaryTurquoise.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge d'achievement
class _AchievementBadge extends StatelessWidget {
  final String name;
  final String description;
  final String iconName;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.name,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
  });

  IconData _getIcon() {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      case 'bolt':
        return Icons.bolt;
      case 'trending_up':
        return Icons.trending_up;
      case 'school':
        return Icons.school;
      case 'psychology':
        return Icons.psychology;
      case 'paid':
        return Icons.paid;
      case 'diamond':
        return Icons.diamond;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'warehouse':
        return Icons.warehouse;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? AppColors.gold : Colors.white.withOpacity(0.2);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUnlocked ? '$name - $description' : '$name (verrouillé) - $description',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isUnlocked ? AppColors.success : AppColors.backgroundDarkPanel,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.gold.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? AppColors.gold.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              color: color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
