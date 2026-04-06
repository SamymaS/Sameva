import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/quests_list_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/quest_detail_sheet.dart';
import 'create_quest_choice_page.dart';
import 'create_quest_page.dart';
import 'quest_calendar_page.dart';

const _kSortLabels = {
  QuestSortOrder.dateDesc: 'Date',
  QuestSortOrder.difficultyAsc: 'Difficulté',
  QuestSortOrder.durationAsc: 'Durée',
};

// Raccourci pour accéder au ViewModel depuis les sous-widgets
QuestsListViewModel _vmOf(BuildContext context) =>
    context.read<QuestsListViewModel>();

/// Mes Quêtes — liste épurée avec cards colorées par rareté.
class QuestsListPage extends StatefulWidget {
  const QuestsListPage({super.key});

  @override
  State<QuestsListPage> createState() => _QuestsListPageState();
}

class _QuestsListPageState extends State<QuestsListPage> {
  int _tab = 0; // 0 = À faire, 1 = Terminées
  QuestsListViewModel? _vm;
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= QuestsListViewModel(
      context.read<QuestRepository>(),
      context.read<AuthViewModel>(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        _vm?.clearSearch();
      }
    });
  }

  Future<void> _load() async {
    await _vm?.loadQuests();
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider<QuestsListViewModel>.value(
      value: _vm!,
      child: Scaffold(
        backgroundColor: AppColors.backgroundNightBlue,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundNightBlue,
          elevation: 0,
          title: _searchOpen
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une quête…',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _vm?.setSearchQuery(v),
                )
              : const Text(
                  'Quêtes',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _searchOpen ? Icons.close : Icons.search,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: _toggleSearch,
            ),
            if (!_searchOpen) ...[
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined,
                    color: AppColors.textMuted, size: 20),
                tooltip: 'Calendrier',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuestCalendarPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textMuted, size: 20),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ],
        ),
        body: Consumer<QuestsListViewModel>(
          builder: (context, vm, _) {
            if (vm.error != null) {
              return _ErrorState(error: vm.error!, onRetry: _load);
            }
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryTurquoise),
              );
            }

            final now = DateTime.now();
            final active = vm.activeQuests;
            final completed = vm.filteredCompletedQuests;
            final allMissed = active
                .where((q) => q.deadline != null && now.isAfter(q.deadline!))
                .toList();
            // filteredActiveQuests applique filtres + tri, on re-sépare missed/nonMissed
            final filtered = vm.filteredActiveQuests;
            final missed = filtered
                .where((q) => q.deadline != null && now.isAfter(q.deadline!))
                .toList();
            final nonMissed = filtered
                .where((q) => q.deadline == null || !now.isAfter(q.deadline!))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TabBar(
                  selected: _tab,
                  activeCount: active.length,
                  missedCount: allMissed.length,
                  completedCount: completed.length,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                if (_tab == 0) _FilterBar(vm: vm),
                const SizedBox(height: 4),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primaryVioletLight,
                    backgroundColor: AppColors.backgroundDarkPanel,
                    child: _tab == 0
                        ? _ActiveTabContent(
                            missed: missed,
                            active: nonMissed,
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
      ),
    );
  }
}

// ── Onglets personnalisés ─────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int selected;
  final int activeCount;
  final int missedCount;
  final int completedCount;
  final ValueChanged<int> onChanged;

  const _TabBar({
    required this.selected,
    required this.activeCount,
    required this.missedCount,
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
            missedCount: missedCount,
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
  final int missedCount;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    this.missedCount = 0,
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
            if (missedCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.coralRare.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.coralRare.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '⚠ $missedCount',
                  style: const TextStyle(
                    color: AppColors.coralRare,
                    fontSize: 10,
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

// ── Barre de filtres ─────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final QuestsListViewModel vm;

  const _FilterBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    final hasFilter = vm.categoryFilter != null || vm.frequencyFilter != null;

    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          // Bouton tri
          _FilterChip(
            label: _kSortLabels[vm.sortOrder]!,
            icon: Icons.sort,
            active: vm.sortOrder != QuestSortOrder.dateDesc,
            onTap: () => _showSortMenu(context),
          ),
          const SizedBox(width: 6),
          // Chips fréquence
          ...QuestFrequency.values.map((f) {
            final label = switch (f) {
              QuestFrequency.oneOff => 'Unique',
              QuestFrequency.daily => 'Quotidien',
              QuestFrequency.weekly => 'Hebdo',
              QuestFrequency.monthly => 'Mensuel',
            };
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: label,
                active: vm.frequencyFilter == f,
                onTap: () => vm.setFrequencyFilter(
                  vm.frequencyFilter == f ? null : f,
                ),
              ),
            );
          }),
          // Chips catégories
          ...vm.availableCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: cat,
                active: vm.categoryFilter == cat,
                onTap: () => vm.setCategoryFilter(
                  vm.categoryFilter == cat ? null : cat,
                ),
              ),
            );
          }),
          // Bouton reset si filtre actif
          if (hasFilter) ...[
            const SizedBox(width: 2),
            _FilterChip(
              label: 'Réinitialiser',
              icon: Icons.close,
              active: false,
              onTap: vm.clearFilters,
              danger: true,
            ),
          ],
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDarkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: QuestSortOrder.values.map((order) {
            final selected = vm.sortOrder == order;
            return ListTile(
              title: Text(
                _kSortLabels[order]!,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryTurquoise
                      : AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: AppColors.primaryTurquoise)
                  : null,
              onTap: () {
                vm.setSortOrder(order);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.coralRare
        : active
            ? AppColors.primaryTurquoise
            : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryTurquoise.withValues(alpha: 0.12)
              : AppColors.backgroundDarkPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: active ? 0.6 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet "À faire" avec section En retard ───────────────────────────────────

class _ActiveTabContent extends StatelessWidget {
  final List<Quest> missed;
  final List<Quest> active;
  final VoidCallback? onReload;

  const _ActiveTabContent({
    required this.missed,
    required this.active,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    if (missed.isEmpty && active.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_outlined,
                size: 44, color: Color(0x669CA3AF)),
            SizedBox(height: 12),
            Text('Aucune quête en cours',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (missed.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.coralRare, size: 14),
              SizedBox(width: 6),
              Text('En retard',
                  style: TextStyle(
                      color: AppColors.coralRare,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ...missed.map((q) => _QuestCard(quest: q, missed: true, onReload: onReload)),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('À faire',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
            const SizedBox(height: 6),
          ],
        ],
        ...active.map((q) => _QuestCard(quest: q, onReload: onReload)),
      ],
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
  final bool missed;
  final VoidCallback? onReload;

  const _QuestCard({
    required this.quest,
    this.completed = false,
    this.missed = false,
    this.onReload,
  });

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

  void _delete(BuildContext context) {
    final id = quest.id;
    if (id == null) return;
    _vmOf(context).deleteQuest(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${quest.title}" supprimée'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
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
        onDelete: completed ? null : () => _delete(context),
        onEdit: completed
            ? null
            : () => Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => CreateQuestPage(initialQuest: quest),
                    ))
                    .then((_) => onReload?.call()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: missed
              ? AppColors.coralRare.withValues(alpha: 0.06)
              : AppColors.backgroundDarkPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: missed
                ? AppColors.coralRare.withValues(alpha: 0.40)
                : _rarityColor.withValues(alpha: completed ? 0.15 : 0.25),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Bande de rareté / retard
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: missed
                      ? AppColors.coralRare.withValues(alpha: 0.7)
                      : _rarityColor.withValues(alpha: completed ? 0.3 : 0.8),
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

    if (completed || quest.id == null) return tile;

    return Dismissible(
      key: ValueKey(quest.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(context),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.coralRare.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.coralRare.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.coralRare),
      ),
      child: tile,
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
      ValidationType.ai => (
          Icons.psychology_outlined,
          'IA',
          AppColors.secondaryViolet
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
