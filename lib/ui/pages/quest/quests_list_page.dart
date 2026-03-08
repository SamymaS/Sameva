import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/quest_detail_sheet.dart';
import 'create_quest_choice_page.dart';

/// Mes Quêtes — liste épurée avec cards colorées par rareté.
class QuestsListPage extends StatefulWidget {
  const QuestsListPage({super.key});

  @override
  State<QuestsListPage> createState() => _QuestsListPageState();
}

class _QuestsListPageState extends State<QuestsListPage> {
  int _tab = 0; // 0 = À faire, 1 = Terminées

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<QuestProvider>().loadQuests(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        elevation: 0,
        title: const Text(
          'Quêtes',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textMuted, size: 20),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Consumer<QuestProvider>(
        builder: (context, qp, _) {
          if (qp.error != null) {
            return _ErrorState(error: qp.error!, onRetry: _load);
          }
          if (qp.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryTurquoise),
            );
          }

          final active = qp.activeQuests;
          final completed = qp.completedQuests;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Onglets ──────────────────────────────────────────────
              _TabBar(
                selected: _tab,
                activeCount: active.length,
                completedCount: completed.length,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 4),
              // ── Liste ────────────────────────────────────────────────
              Expanded(
                child: _tab == 0
                    ? _QuestList(
                        quests: active,
                        emptyLabel: 'Aucune quête en cours',
                        emptyIcon: Icons.explore_outlined,
                        onReload: _load,
                      )
                    : _QuestList(
                        quests: completed,
                        emptyLabel: 'Aucune quête terminée',
                        emptyIcon: Icons.check_circle_outline,
                        completed: true,
                        onReload: _load,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'quests_list_fab',
        backgroundColor: AppColors.primaryTurquoise,
        foregroundColor: AppColors.backgroundNightBlue,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateQuestChoicePage()),
          );
          await _load();
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// ── Onglets personnalisés ─────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int selected;
  final int activeCount;
  final int completedCount;
  final ValueChanged<int> onChanged;

  const _TabBar({
    required this.selected,
    required this.activeCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _TabItem(
            label: 'À faire',
            count: activeCount,
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 8),
          _TabItem(
            label: 'Terminées',
            count: completedCount,
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primaryTurquoise
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.primaryTurquoise
                    : AppColors.textMuted,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryTurquoise
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? AppColors.backgroundNightBlue
                        : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Liste de quêtes ───────────────────────────────────────────────────────────

class _QuestList extends StatelessWidget {
  final List<Quest> quests;
  final String emptyLabel;
  final IconData emptyIcon;
  final bool completed;
  final VoidCallback? onReload;

  const _QuestList({
    required this.quests,
    required this.emptyLabel,
    required this.emptyIcon,
    this.completed = false,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 44, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              emptyLabel,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: quests.length,
      itemBuilder: (context, index) => _QuestCard(
        quest: quests[index],
        completed: completed,
        onReload: onReload,
      ),
    );
  }
}

// ── Card quête ────────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final bool completed;
  final VoidCallback? onReload;

  const _QuestCard({required this.quest, this.completed = false, this.onReload});

  Color get _rarityColor => switch (quest.rarity) {
        QuestRarity.common => AppColors.rarityCommon,
        QuestRarity.uncommon => AppColors.rarityUncommon,
        QuestRarity.rare => AppColors.rarityRare,
        QuestRarity.epic => AppColors.rarityEpic,
        QuestRarity.legendary => AppColors.rarityLegendary,
        QuestRarity.mythic => AppColors.rarityMythic,
      };

  String get _frequencyLabel => switch (quest.frequency) {
        QuestFrequency.oneOff => 'Unique',
        QuestFrequency.daily => 'Quotidienne',
        QuestFrequency.weekly => 'Hebdomadaire',
        QuestFrequency.monthly => 'Mensuelle',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => QuestDetailSheet.show(
        context,
        quest: quest,
        onValidate: completed
            ? null
            : () {
                Navigator.of(context)
                    .pushNamed('/quest/validate', arguments: quest)
                    .then((_) => onReload?.call());
              },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _rarityColor.withValues(alpha: completed ? 0.15 : 0.25)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Bande de rareté
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _rarityColor
                      .withValues(alpha: completed ? 0.3 : 0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre
                            Text(
                              quest.title,
                              style: TextStyle(
                                color: completed
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Méta : catégorie + durée + difficulté
                            Row(
                              children: [
                                Text(
                                  quest.category,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 2,
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    color: AppColors.textMuted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${quest.estimatedDurationMinutes} min',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11),
                                ),
                                const SizedBox(width: 8),
                                // Difficulté — 5 points
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Container(
                                      margin:
                                          const EdgeInsets.only(right: 2),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i < quest.difficulty
                                            ? _rarityColor.withValues(
                                                alpha: completed ? 0.4 : 0.9)
                                            : AppColors.textMuted
                                                .withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Fréquence + type validation
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _SmallBadge(label: _frequencyLabel),
                                const SizedBox(width: 6),
                                _ValidationBadge(type: quest.validationType),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icône droite
                      Icon(
                        completed
                            ? Icons.check_circle
                            : Icons.chevron_right,
                        color: completed
                            ? AppColors.success
                            : AppColors.textMuted.withValues(alpha: 0.5),
                        size: completed ? 20 : 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;

  const _SmallBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundNightBlue,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style:
              const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  final ValidationType type;

  const _ValidationBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (type) {
      ValidationType.photo => (
          Icons.camera_alt_outlined,
          'Photo',
          AppColors.secondaryViolet
        ),
      ValidationType.timer => (
          Icons.timer_outlined,
          'Timer',
          AppColors.warning
        ),
      ValidationType.geolocation => (
          Icons.location_on_outlined,
          'Lieu',
          AppColors.primaryTurquoise
        ),
      ValidationType.manual => (
          Icons.check_outlined,
          'Manuel',
          AppColors.textMuted
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── État d'erreur ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTurquoise,
                  foregroundColor: AppColors.backgroundNightBlue),
            ),
          ],
        ),
      ),
    );
  }
}
