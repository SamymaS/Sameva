import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/magical_avatar.dart';
import '../../widgets/common/header_bar.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../quest/quest_detail_page.dart';
import 'dart:math' as math;

/// Page Sanctuary - Accueil avec avatar magique et quêtes actives
/// Inspirée du design Figma SanctuaryV2
class SanctuaryPage extends StatelessWidget {
  const SanctuaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
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
          ),

          // Ambient glows
          Positioned(
            top: 80,
            left: 40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryViolet.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTurquoise.withOpacity(0.15),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Header Bar
              const HeaderBar(),

              // Central Scene - Avatar with magical effects
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Magical Avatar
                      const MagicalAvatar(
                        emoji: '🧙‍♀️',
                        size: 120,
                        companionEmoji: '🦊',
                        showMagicCircle: true,
                      ),

                      const SizedBox(height: 60),

                      // Active Quests Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quêtes Actives',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigation handled by bottom nav
                              },
                              child: Text(
                                'Voir toutes',
                                style: TextStyle(
                                  color: AppColors.primaryTurquoise,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quests Carousel
                      Consumer<QuestProvider>(
                        builder: (context, questProvider, _) {
                          final activeQuests = questProvider.activeQuests.take(5).toList();
                          
                          if (activeQuests.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: GlassmorphicCard(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 48,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucune quête active',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/create-quest');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryTurquoise,
                                      ),
                                      child: const Text('Créer une quête'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: activeQuests.length,
                              itemBuilder: (context, index) {
                                final quest = activeQuests[index];
                                return _QuestCard(quest: quest);
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_circle_outline,
                                label: 'Nouvelle Quête',
                                color: AppColors.primaryTurquoise,
                                onTap: () {
                                  Navigator.of(context).pushNamed('/create-quest');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Inventaire',
                                color: AppColors.gold,
                                onTap: () {
                                  // Navigation handled by bottom nav
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final dynamic quest; // Quest from QuestProvider

  const _QuestCard({required this.quest});

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'étude':
      case 'study':
        return AppColors.rarityRare;
      case 'sport':
        return AppColors.rarityUncommon;
      case 'bien-être':
      case 'selfcare':
        return AppColors.rarityEpic;
      case 'créativité':
      case 'creative':
        return AppColors.secondaryViolet;
      case 'social':
        return AppColors.rarityUncommon;
      default:
        return AppColors.primaryTurquoise;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'étude':
      case 'study':
        return Icons.menu_book;
      case 'sport':
        return Icons.fitness_center;
      case 'bien-être':
      case 'selfcare':
        return Icons.favorite;
      case 'créativité':
      case 'creative':
        return Icons.palette;
      case 'social':
        return Icons.people;
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(quest.category);
    final categoryIcon = _getCategoryIcon(quest.category);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestDetailPage(quest: quest),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        child: GlassmorphicCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryIcon,
                      size: 16,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quest.title ?? 'Quête',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.3, // TODO: Calculate actual progress
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '30%', // TODO: Calculate actual progress
                    style: TextStyle(
                      fontSize: 11,
                      color: categoryColor.withOpacity(0.8),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+50 XP', // TODO: Get from quest rewards
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

