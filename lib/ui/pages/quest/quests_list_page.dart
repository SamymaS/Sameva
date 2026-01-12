import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/minimalist/minimalist_card.dart';
import '../../widgets/minimalist/minimalist_button.dart';
import '../../widgets/minimalist/fade_in_animation.dart';
import '../../widgets/magical/animated_background.dart';
import '../../widgets/magical/glowing_card.dart';
import '../../theme/app_colors.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import 'quest_detail_page.dart';

/// Page pour voir toutes les quêtes - Refactorée "Magie Minimaliste"
class QuestsListPage extends StatefulWidget {
  const QuestsListPage({super.key});

  @override
  State<QuestsListPage> createState() => _QuestsListPageState();
}

class _QuestsListPageState extends State<QuestsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;

  final List<String> _categories = [
    'Tous',
    'Maison',
    'Sport',
    'Santé',
    'Études',
    'Créatif',
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

  List<Quest> _filterQuestsByCategory(List<Quest> quests) {
    if (_selectedCategory == null || _selectedCategory == 'Tous') {
      return quests;
    }
    return quests
        .where((quest) => quest.category.toLowerCase() == _selectedCategory!.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();

    return Scaffold(
      body: AnimatedMagicalBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header minimaliste
              _buildHeader(questProvider.quests.length),

              // Filtres par catégorie
              _buildCategoryFilters(),

              const SizedBox(height: 12),

              // Tabs minimalistes
              _buildTabs(),

              const SizedBox(height: 12),

              // Liste des quêtes
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestsList(_filterQuestsByCategory(questProvider.activeQuests)),
                    _buildQuestsList(_filterQuestsByCategory(questProvider.completedQuests)),
                    _buildQuestsList([]), // Archivées
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalQuests) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes Quêtes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalQuests quêtes au total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Flexible(
            child: MinimalistButton(
              label: 'Nouvelle',
              icon: Icons.add,
              onPressed: () {
                Navigator.of(context).pushNamed('/create-quest');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTurquoise.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryTurquoise
                        : Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryTurquoise : Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryTurquoise.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.primaryTurquoise,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Actives'),
          Tab(text: 'Terminées'),
          Tab(text: 'Archivées'),
        ],
      ),
    );
  }

  Widget _buildQuestsList(List<Quest> quests) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune quête',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première quête pour commencer',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Padding en bas pour éviter le dock
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return FadeInAnimation(
          delay: Duration(milliseconds: index * 50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MinimalistQuestListCard(quest: quest),
          ),
        );
      },
    );
  }

}

/// Carte de quête pour la liste - Style minimaliste
class _MinimalistQuestListCard extends StatelessWidget {
  final Quest quest;

  const _MinimalistQuestListCard({required this.quest});

  Color _getRarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return AppColors.rarityCommon;
      case QuestRarity.uncommon:
        return AppColors.rarityUncommon;
      case QuestRarity.rare:
        return AppColors.rarityRare;
      case QuestRarity.epic:
        return AppColors.rarityEpic;
      case QuestRarity.legendary:
        return AppColors.rarityLegendary;
      case QuestRarity.mythic:
        return AppColors.rarityMythic;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'maison':
        return Icons.home_outlined;
      case 'sport':
        return Icons.fitness_center_outlined;
      case 'santé':
        return Icons.favorite_outline;
      case 'études':
        return Icons.menu_book_outlined;
      case 'créatif':
        return Icons.palette_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(quest.rarity);
    final categoryIcon = _getCategoryIcon(quest.category);

    return GlowingCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestDetailPage(quest: quest),
          ),
        );
      },
      glowColor: rarityColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône de catégorie
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: rarityColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  categoryIcon,
                  color: rarityColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Titre et catégorie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          quest.category,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star_outline,
                          size: 12,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${quest.xpReward ?? 0} XP',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicateur de rareté
              Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  color: rarityColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (quest.description != null) ...[
            const SizedBox(height: 12),
            Text(
              quest.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
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
                Icons.access_time_outlined,
                size: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                '${quest.estimatedDurationMinutes ~/ 60}h',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.trending_up_outlined,
                size: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Difficulté: ${quest.difficulty}/5',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
