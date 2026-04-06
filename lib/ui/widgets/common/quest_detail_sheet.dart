import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/quest_rewards_calculator.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet de détail d'une quête.
/// Affiche description, rareté, récompenses et sous-tâches cochables (état local).
///
/// Usage :
/// ```dart
/// await QuestDetailSheet.show(context, quest: q, onValidate: () { ... });
/// ```
class QuestDetailSheet extends StatefulWidget {
  final Quest quest;
  final VoidCallback? onValidate;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const QuestDetailSheet({
    super.key,
    required this.quest,
    this.onValidate,
    this.onDelete,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required Quest quest,
    VoidCallback? onValidate,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestDetailSheet(
        quest: quest,
        onValidate: onValidate,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    );
  }

  @override
  State<QuestDetailSheet> createState() => _QuestDetailSheetState();
}

class _QuestDetailSheetState extends State<QuestDetailSheet> {
  late List<bool> _subTasksDone;

  static String _hiveKey(String? id) => 'subtasks_${id ?? 'none'}';

  @override
  void initState() {
    super.initState();
    _subTasksDone = _loadSubTasks();
  }

  List<bool> _loadSubTasks() {
    final count = widget.quest.subQuests.length;
    if (count == 0 || widget.quest.id == null) {
      return List.filled(count, false);
    }
    try {
      final raw = Hive.box('settings').get(_hiveKey(widget.quest.id));
      if (raw == null) return List.filled(count, false);
      final list = (jsonDecode(raw as String) as List).cast<bool>();
      if (list.length != count) return List.filled(count, false);
      return list;
    } catch (_) {
      return List.filled(count, false);
    }
  }

  Future<void> _saveSubTasks() async {
    if (widget.quest.id == null) return;
    await Hive.box('settings')
        .put(_hiveKey(widget.quest.id), jsonEncode(_subTasksDone));
  }

  Quest get _q => widget.quest;
  Color get _rarityColor => _rarityColorFor(_q.rarity);
  bool get _canValidate => !_q.isCompleted && widget.onValidate != null;
  bool get _canEdit => !_q.isCompleted && widget.onEdit != null;
  bool get _canDelete => widget.onDelete != null;

  int get _subTasksDoneCount => _subTasksDone.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundDarkPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // En-tête rareté + titre
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _rarityColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _rarityLabel(_q.rarity),
                          style: TextStyle(
                              color: _rarityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_q.isCompleted) ...[
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 4),
                        const Text('Terminée',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _q.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_q.description != null &&
                      _q.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _q.description!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Méta-infos
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                          icon: Icons.category_outlined,
                          label: _q.category),
                      _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '${_q.estimatedDurationMinutes} min'),
                      _InfoChip(
                          icon: Icons.repeat,
                          label: _frequencyLabel(_q.frequency)),
                      _InfoChip(
                          icon: Icons.bar_chart,
                          label: 'Difficulté ${_q.difficulty}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Récompenses
                  _RewardsRow(quest: _q),
                  const SizedBox(height: 16),

                  // Sous-tâches
                  if (_q.subQuests.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Sous-tâches',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const Spacer(),
                        Text(
                          '$_subTasksDoneCount/${_q.subQuests.length}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Barre de progression sous-tâches
                    if (_q.subQuests.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _subTasksDoneCount / _q.subQuests.length,
                          backgroundColor: AppColors.backgroundNightBlue,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryTurquoise),
                          minHeight: 4,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...List.generate(_q.subQuests.length, (i) {
                      final done = _subTasksDone[i];
                      return CheckboxListTile(
                        value: done,
                        onChanged: _q.isCompleted
                            ? null
                            : (v) {
                                setState(() => _subTasksDone[i] = v ?? false);
                                _saveSubTasks();
                              },
                        title: Text(
                          _q.subQuests[i],
                          style: TextStyle(
                            color: done
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        activeColor: AppColors.primaryTurquoise,
                        checkColor: AppColors.backgroundNightBlue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

                  // Bouton valider
                  if (_canValidate)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onValidate!();
                        },
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Valider la quête'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTurquoise,
                          foregroundColor: AppColors.backgroundNightBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  // Bouton éditer
                  if (_canEdit) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onEdit!();
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primaryTurquoise),
                        label: const Text('Modifier',
                            style: TextStyle(color: AppColors.primaryTurquoise)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.primaryTurquoise.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  // Bouton supprimer
                  if (_canDelete) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.coralRare),
                        label: const Text('Supprimer',
                            style: TextStyle(color: AppColors.coralRare)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.coralRare.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: const Text('Supprimer la quête',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Supprimer "${_q.title}" ? Cette action est irréversible.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.coralRare)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      widget.onDelete!();
    }
  }

  Color _rarityColorFor(QuestRarity r) => switch (r) {
        QuestRarity.common => AppColors.rarityCommon,
        QuestRarity.uncommon => AppColors.rarityUncommon,
        QuestRarity.rare => AppColors.rarityRare,
        QuestRarity.epic => AppColors.rarityEpic,
        QuestRarity.legendary => AppColors.rarityLegendary,
        QuestRarity.mythic => AppColors.rarityMythic,
      };

  String _rarityLabel(QuestRarity r) => switch (r) {
        QuestRarity.common => 'Commune',
        QuestRarity.uncommon => 'Peu commune',
        QuestRarity.rare => 'Rare',
        QuestRarity.epic => 'Épique',
        QuestRarity.legendary => 'Légendaire',
        QuestRarity.mythic => 'Mythique',
      };

  String _frequencyLabel(QuestFrequency f) => switch (f) {
        QuestFrequency.oneOff => 'Unique',
        QuestFrequency.daily => 'Quotidienne',
        QuestFrequency.weekly => 'Hebdomadaire',
        QuestFrequency.monthly => 'Mensuelle',
      };
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundNightBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RewardsRow extends StatelessWidget {
  final Quest quest;

  const _RewardsRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    final base = QuestRewardsCalculator.calculateBaseRewards(quest.difficulty);
    final xp = quest.xpReward ?? base.experience;
    final gold = quest.goldReward ?? base.gold;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundNightBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RewardItem(
              icon: Icons.star_outline,
              color: AppColors.primaryTurquoise,
              value: '+$xp',
              label: 'XP'),
          Container(
              width: 1, height: 32, color: AppColors.textMuted.withValues(alpha: 0.3)),
          _RewardItem(
              icon: Icons.monetization_on,
              color: AppColors.gold,
              value: '+$gold',
              label: 'Or'),
        ],
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _RewardItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
