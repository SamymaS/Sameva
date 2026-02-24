import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../theme/app_colors.dart';

/// Page d'accueil : sanctuaire du joueur avec stats, streak et quêtes du jour.
class SanctuaryPage extends StatefulWidget {
  const SanctuaryPage({super.key});

  @override
  State<SanctuaryPage> createState() => _SanctuaryPageState();
}

class _SanctuaryPageState extends State<SanctuaryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await context.read<QuestProvider>().loadQuests(userId);
    await context.read<PlayerProvider>().loadPlayerStats(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      body: SafeArea(
        child: Consumer2<PlayerProvider, QuestProvider>(
          builder: (context, player, quests, _) {
            final stats = player.stats;
            if (stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final todayQuests = quests.activeQuests.where((q) {
              final created = DateTime(q.createdAt.year, q.createdAt.month, q.createdAt.day);
              return created == today || q.frequency == QuestFrequency.daily;
            }).take(3).toList();

            final xpForNext = player.experienceForLevel(stats.level);

            return RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: AppColors.backgroundNightBlue,
                    floating: true,
                    title: const Text(
                      'Sanctuaire',
                      style: TextStyle(
                        color: AppColors.primaryTurquoise,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${stats.streak}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _StatsCard(stats: stats, xpForNext: xpForNext),
                        const SizedBox(height: 16),
                        _MoralBar(moral: stats.moral),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Aujourd'hui",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Voir tout',
                                style: TextStyle(color: AppColors.primaryTurquoise),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (quests.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (todayQuests.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDarkPanel,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "Aucune quête pour aujourd'hui.\nCréez votre première quête !",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          )
                        else
                          ...todayQuests.map((q) => _QuestTile(quest: q)),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final PlayerStats stats;
  final int xpForNext;

  const _StatsCard({required this.stats, required this.xpForNext});

  @override
  Widget build(BuildContext context) {
    final xpProgress =
        xpForNext > 0 ? (stats.experience / xpForNext).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.backgroundDarkPanel, AppColors.backgroundDeepViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Niveau ${stats.level}',
                    style: const TextStyle(
                      color: AppColors.primaryTurquoise,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${stats.experience} / $xpForNext XP',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Text('${stats.gold}',
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  const Icon(Icons.diamond,
                      color: AppColors.secondaryViolet, size: 18),
                  const SizedBox(width: 4),
                  Text('${stats.crystals}',
                      style: const TextStyle(
                          color: AppColors.secondaryVioletGlow,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              backgroundColor: AppColors.backgroundNightBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryTurquoise),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
              const SizedBox(width: 4),
              Text(
                '${stats.healthPoints} / ${stats.maxHealthPoints} HP',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoralBar extends StatelessWidget {
  final double moral;

  const _MoralBar({required this.moral});

  @override
  Widget build(BuildContext context) {
    final color = moral > 0.7
        ? AppColors.success
        : moral > 0.3
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Moral',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            Text(
              '${(moral * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: moral,
            backgroundColor: AppColors.backgroundDarkPanel,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _QuestTile extends StatelessWidget {
  final Quest quest;

  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined,
              color: AppColors.primaryTurquoise, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quest.title,
              style: const TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${quest.estimatedDurationMinutes} min',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
