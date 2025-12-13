import 'package:flutter/material.dart';
import '../../../../presentation/providers/quest_provider.dart';
import '../../../theme/app_colors.dart';

class QuestList extends StatelessWidget {
  final List<Quest> quests;
  final Function(String) onQuestCompleted;
  final void Function(Quest)? onQuestTap;

  const QuestList({
    super.key,
    required this.quests,
    required this.onQuestCompleted,
    this.onQuestTap,
  });

  Color _getRarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return AppColors.rarityCommon;
      case QuestRarity.uncommon:
        return AppColors.rarityUncommon;
      case QuestRarity.rare:
        return AppColors.rarityRare;
      case QuestRarity.veryRare:
        return AppColors.rarityEpic; // veryRare = epic selon Figma
      case QuestRarity.epic:
        return AppColors.rarityEpic;
      case QuestRarity.legendary:
        return AppColors.rarityLegendary;
      case QuestRarity.mythic:
        return AppColors.rarityMythic;
    }
  }

  String _getFrequencyText(QuestFrequency frequency) {
    switch (frequency) {
      case QuestFrequency.once:
        return 'Unique';
      case QuestFrequency.daily:
        return 'Quotidienne';
      case QuestFrequency.weekly:
        return 'Hebdomadaire';
      case QuestFrequency.monthly:
        return 'Mensuelle';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune quête en cours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première quête pour commencer l\'aventure !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final rarityColor = _getRarityColor(quest.rarity);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onQuestTap?.call(quest),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rarityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quest.rarity.toString().split('.').last,
                            style: TextStyle(
                              color: rarityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getFrequencyText(quest.frequency),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      quest.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (quest.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        quest.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Durée: ${quest.estimatedDuration.inHours}h ${quest.estimatedDuration.inMinutes % 60}min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => onQuestCompleted(quest.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Terminer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 