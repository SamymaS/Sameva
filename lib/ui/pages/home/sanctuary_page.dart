import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/magical_avatar.dart';
import '../../widgets/minimalist/hud_header.dart';
import '../../widgets/minimalist/quest_card_minimalist.dart';
import '../../widgets/magical/animated_background.dart';
import '../../theme/app_colors.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/quest_rewards_calculator.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../quest/quest_detail_page.dart';

/// Page Sanctuary - "Moderne Éthérée"
/// Structure en couches avec DraggableScrollableSheet
class SanctuaryPage extends StatefulWidget {
  const SanctuaryPage({super.key});

  @override
  State<SanctuaryPage> createState() => _SanctuaryPageState();
}

class _SanctuaryPageState extends State<SanctuaryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMagicalBackground(
        child: Stack(
          children: [

          // Couche 1 : Avatar (Centré en haut, fixe)
          _buildHeroAvatar(),

          // Couche 2 : Header HUD (Flottant en haut)
          Consumer<PlayerProvider>(
            builder: (context, playerProvider, _) {
              final stats = playerProvider.stats;
              return HUDHeader(
                level: stats?.level ?? 1,
                experience: stats?.experience ?? 0,
                maxExperience: playerProvider.experienceForLevel(stats?.level ?? 1),
                healthPoints: stats?.healthPoints ?? 100,
                maxHealthPoints: stats?.maxHealthPoints ?? 100,
                gold: stats?.gold ?? 0,
                crystals: stats?.crystals ?? 0,
                onSettingsTap: () {
                  // Navigation vers settings
                },
              );
            },
          ),

          // Couche 3 : Panneau de Quêtes Glissant (DraggableScrollableSheet)
          // Note: Le padding en bas est géré par app_new.dart pour éviter la superposition avec le dock
          _buildQuestsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAvatar() {
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_breathingController.value * 0.03),
              child: const MagicalAvatar(
                emoji: '🧙‍♀️',
                size: 120, // Taille réduite mais visible
                companionEmoji: '🦊',
                showMagicCircle: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestsPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.40, // Prend 40% de l'écran au début (ajusté pour le dock)
      minChildSize: 0.40,
      maxChildSize: 0.80, // Peut monter jusqu'en haut (sous le header, au-dessus du dock)
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            // Fond quasi opaque avec dégradé
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundNightBlue.withOpacity(0.95),
                AppColors.backgroundNightBlue.withOpacity(0.9),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle (poignée pour glisser)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Titre de section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quêtes en cours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cinzel', // Serif élégante
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigation vers liste complète
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Voir toutes',
                        style: TextStyle(
                          color: AppColors.primaryTurquoise,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des quêtes
              Expanded(
                child: Consumer<QuestProvider>(
                  builder: (context, questProvider, _) {
                    final activeQuests = questProvider.activeQuests;

                    if (activeQuests.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: activeQuests.length,
                      itemBuilder: (context, index) {
                        final quest = activeQuests[index];
                        return QuestCardMinimalist(
                          quest: quest,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuestDetailPage(quest: quest),
                              ),
                            );
                          },
                          onComplete: () => _completeQuest(quest),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeQuest(Quest quest) async {
    if (quest.id == null) return;

    final questProvider = Provider.of<QuestProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    try {
      final rewards = await questProvider.completeQuestWithRewards(
        quest.id!,
        playerProvider,
      );

      if (!mounted) return;

      _showRewardsDialog(quest.title, rewards);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRewardsDialog(String questTitle, QuestRewards rewards) {
    String bonusLabel;
    Color bonusColor;
    switch (rewards.bonusType) {
      case 'early':
        bonusLabel = 'En avance !';
        bonusColor = AppColors.primaryTurquoise;
        break;
      case 'on_time':
        bonusLabel = 'A temps';
        bonusColor = AppColors.success;
        break;
      case 'late':
        bonusLabel = 'En retard';
        bonusColor = AppColors.warning;
        break;
      default:
        bonusLabel = '';
        bonusColor = Colors.white;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundNightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              'Quête Accomplie !',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              questTitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bonusLabel.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bonusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bonusColor.withOpacity(0.5)),
                ),
                child: Text(
                  bonusLabel,
                  style: TextStyle(color: bonusColor, fontWeight: FontWeight.w600),
                ),
              ),
            _rewardRow('⚡ XP', '+${rewards.experience}', AppColors.primaryTurquoise),
            const SizedBox(height: 8),
            _rewardRow('🪙 Or', '+${rewards.gold}', AppColors.gold),
            if (rewards.crystals > 0) ...[
              const SizedBox(height: 8),
              _rewardRow('💎 Cristaux', '+${rewards.crystals}', AppColors.secondaryViolet),
            ],
            if (rewards.multiplier != 1.0) ...[
              const SizedBox(height: 12),
              Text(
                'Multiplicateur: x${rewards.multiplier.toStringAsFixed(2)}',
                style: TextStyle(
                  color: rewards.multiplier > 1.0 ? AppColors.primaryTurquoise : AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Continuer',
              style: TextStyle(color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune quête active',
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
