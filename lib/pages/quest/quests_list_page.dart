import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';
import '../../core/providers/quest_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'quest_detail_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Page pour voir toutes les quêtes
class QuestsListPage extends StatefulWidget {
  const QuestsListPage({super.key});

  @override
  State<QuestsListPage> createState() => _QuestsListPageState();
}

class _QuestsListPageState extends State<QuestsListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      await context.read<QuestProvider>().loadQuests(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
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
                          'Mes Quêtes',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${questProvider.quests.length} quêtes au total',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    // Bouton pour créer une quête
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                      onPressed: () {
                        // TODO: Navigation vers création de quête
                      },
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Actives'),
                    Tab(text: 'Terminées'),
                    Tab(text: 'Archivées'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Liste des quêtes
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestsList(questProvider.activeQuests),
                    _buildQuestsList(questProvider.completedQuests),
                    _buildQuestsList([]), // Archived quests - à implémenter
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestsList(List<dynamic> quests) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune quête',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première quête pour commencer !',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestCard(quest: quest)
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: (index * 50).ms);
      },
    );
  }
}

class _QuestCard extends StatelessWidget {
  final dynamic quest;

  const _QuestCard({required this.quest});

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'quotidienne':
        return const Color(0xFF22C55E);
      case 'hebdomadaire':
        return AppColors.primary;
      case 'spéciale':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(quest.category);

    return FantasyCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestDetailPage(quest: quest),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge de catégorie
                FantasyBadge(
                  label: quest.category ?? 'Quête',
                  variant: BadgeVariant.default_,
                  backgroundColor: categoryColor,
                  textColor: Colors.white,
                ),
                const Spacer(),
                // XP (calculé approximativement)
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.legendary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quest.difficulty * 10} XP',
                      style: TextStyle(
                        color: AppColors.legendary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Titre
            Text(
              quest.title ?? 'Quête sans titre',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (quest.description != null) ...[
              const SizedBox(height: 4),
              Text(
                quest.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Informations supplémentaires
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quest.estimatedDuration.inHours}h',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Difficulté: ${quest.difficulty}/5',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

