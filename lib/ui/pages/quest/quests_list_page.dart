import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
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
  String? _selectedCategory; // Filtre par catégorie selon pages.md

  // Catégories disponibles selon pages.md : Travail, Sport, Maison, Personnel...
  final List<String> _categories = [
    'Tous',
    'Travail',
    'Sport',
    'Maison',
    'Personnel',
    'Étude',
    'Bien-être',
    'Créativité',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedCategory = 'Tous';
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<QuestProvider>().loadQuests(userId);
    }
  }

  // Filtre les quêtes par catégorie sélectionnée
  List<dynamic> _filterQuestsByCategory(List<dynamic> quests) {
    if (_selectedCategory == null || _selectedCategory == 'Tous') {
      return quests;
    }
    return quests.where((quest) {
      final questCategory = quest.category?.toString() ?? '';
      return questCategory.toLowerCase() == _selectedCategory!.toLowerCase();
    }).toList();
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
              AppColors.backgroundDeepViolet,
              AppColors.backgroundNightBlue,
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
                      color: AppColors.primaryTurquoise,
                      onPressed: () {
                        Navigator.of(context).pushNamed('/create-quest');
                      },
                    ),
                  ],
                ),
              ),
              // Filtres par catégorie (selon pages.md)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'Tous';
                          });
                        },
                        backgroundColor: AppColors.backgroundDarkPanel.withOpacity(0.3),
                        selectedColor: AppColors.primaryTurquoise.withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryTurquoise : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryTurquoise : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDarkPanel.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryTurquoise.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.primaryTurquoise,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Actives'),
                    Tab(text: 'Terminées'),
                    Tab(text: 'Archivées'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Liste des quêtes (filtrées par catégorie)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestsList(_filterQuestsByCategory(questProvider.activeQuests)),
                    _buildQuestsList(_filterQuestsByCategory(questProvider.completedQuests)),
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
        return AppColors.primaryTurquoise;
      case 'spéciale':
        return AppColors.accent;
      default:
        return AppColors.primaryTurquoise;
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
                      color: AppColors.rarityLegendary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quest.difficulty * 10} XP',
                      style: TextStyle(
                        color: AppColors.rarityLegendary,
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

