import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../domain/services/bonus_malus_service.dart';
import '../../../domain/services/item_factory.dart';

class QuestDetailPage extends StatefulWidget {
  final Quest quest;
  const QuestDetailPage({super.key, required this.quest});

  @override
  State<QuestDetailPage> createState() => _QuestDetailPageState();
}

class _QuestDetailPageState extends State<QuestDetailPage> {
  late List<bool> _localSubCompleted;

  @override
  void initState() {
    super.initState();
    _localSubCompleted = List<bool>.filled(widget.quest.subQuests.length, false);
  }

  Color _rarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common: return AppColors.rarityCommon;
      case QuestRarity.uncommon: return AppColors.rarityUncommon;
      case QuestRarity.rare: return AppColors.rarityRare;
      case QuestRarity.epic: return AppColors.rarityEpic;
      case QuestRarity.legendary: return AppColors.rarityLegendary;
      case QuestRarity.mythic: return AppColors.rarityMythic;
    }
  }

  Future<void> _completeQuest() async {
    final userId = context.read<AuthProvider>().userId ?? '';
    if (userId.isEmpty) return;

    final questProvider = context.read<QuestProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    // Compléter la quête
    if (widget.quest.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Quête sans ID')),
      );
      return;
    }
    await questProvider.completeQuest(widget.quest.id!);

    // Calculer les récompenses avec bonus/malus
    final completedAt = DateTime.now();
    final hasStreakBonus = playerProvider.hasStreakBonus;
    final baseRewards = questProvider.calculateRewards(
      widget.quest,
      completedAt,
      hasStreakBonus: hasStreakBonus,
    );

    // Calculer le bonus/malus total
    final completedQuestsToday = questProvider.getCompletedQuestsToday();
    final activeQuestsToday = questProvider.getActiveQuestsToday();
    final missedQuests = questProvider.getMissedQuests();
    final stats = playerProvider.stats;
    
    final totalBonusMalus = BonusMalusService.calculateTotalBonusMalus(
      completedQuestsToday: completedQuestsToday,
      activeQuestsToday: activeQuestsToday,
      missedQuests: missedQuests,
      streak: stats?.streak ?? 0,
      lastActiveDate: stats?.lastActiveDate,
    );

    // Appliquer les récompenses avec bonus/malus
    final finalExperience = BonusMalusService.calculateExperienceModifier(
      totalBonusMalus,
      baseRewards.experience,
    );
    final finalGold = BonusMalusService.calculateGoldModifier(
      totalBonusMalus,
      baseRewards.gold,
    );

    if (finalExperience > 0) {
      await playerProvider.addExperience(userId, finalExperience);
    }
    if (finalGold > 0) {
      await playerProvider.addGold(userId, finalGold);
    }
    if (baseRewards.crystals > 0) {
      await playerProvider.addCrystals(userId, baseRewards.crystals);
    }

    // Mettre à jour le streak
    await playerProvider.updateStreak(userId);

    // Appliquer les pénalités de moral si nécessaire
    if (baseRewards.moralPenalty != null) {
      await playerProvider.updateMoral(userId, baseRewards.moralPenalty!);
    }

    // Régénérer les PV si la quête est complétée à temps
    if (baseRewards.bonusType == 'on_time' || baseRewards.bonusType == 'early') {
      final healAmount = (stats?.maxHealthPoints ?? 100) ~/ 10; // Régénérer 10% des PV max
      await playerProvider.heal(userId, healAmount);
    }

    // Ajouter des items de récompense selon la rareté
    final rewardItem = ItemFactory.createQuestRewardItem(widget.quest.rarity);
    if (rewardItem != null) {
      await inventoryProvider.addItem(userId, rewardItem);
    }

    if (mounted) {
      final bonusText = totalBonusMalus > 1.0
          ? ' (+${((totalBonusMalus - 1.0) * 100).toStringAsFixed(0)}% bonus)'
          : totalBonusMalus < 1.0
              ? ' (${((1.0 - totalBonusMalus) * 100).toStringAsFixed(0)}% malus)'
              : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quête terminée ! +$finalExperience XP, +$finalGold or$bonusText'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(widget.quest.rarity);

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la quête')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [rarityColor.withOpacity(0.15), Colors.white]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: rarityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.quest.rarity.toString().split('.').last, style: TextStyle(color: rarityColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.quest.frequency.toString().split('.').last, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.quest.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.quest.description != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.quest.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Durée estimée: ${widget.quest.estimatedDurationMinutes ~/ 60}h ${widget.quest.estimatedDurationMinutes % 60}min'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.quest.subQuests.isNotEmpty) ...[
            Text('Sous-quêtes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(widget.quest.subQuests.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  value: _localSubCompleted[i],
                  onChanged: (v) => setState(() => _localSubCompleted[i] = v ?? false),
                  title: Text(widget.quest.subQuests[i]),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _completeQuest,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Terminer la quête'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
