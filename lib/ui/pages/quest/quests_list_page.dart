import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../../presentation/view_models/quests_list_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/common/quest_detail_sheet.dart';
import '../../widgets/pixel/pixel_ui.dart';
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
      context.read<QuestViewModel>(),
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
        backgroundColor: PixelCouleurs.nuit,
        appBar: AppBar(
          backgroundColor: PixelCouleurs.nuit,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: _searchOpen
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: PixelTextes.corps(17),
                  cursorColor: PixelCouleurs.violetClair,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une quête…',
                    hintStyle: PixelTextes.corps(17, couleur: PixelCouleurs.texteDoux),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _vm?.setSearchQuery(v),
                )
              : Semantics(
                  header: true,
                  child: Text(
                    'Quêtes',
                    style: PixelTextes.chiffres(15, PixelCouleurs.texte).copyWith(
                      shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(3, 3))],
                    ),
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(_searchOpen ? Icons.close : Icons.search, color: PixelCouleurs.texteDoux, size: 22),
              tooltip: _searchOpen ? 'Fermer la recherche' : 'Rechercher',
              onPressed: _toggleSearch,
            ),
            if (!_searchOpen) ...[
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined, color: PixelCouleurs.texteDoux, size: 22),
                tooltip: 'Calendrier',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuestCalendarPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: PixelCouleurs.texteDoux, size: 22),
                tooltip: 'Réglages',
                onPressed: () => context.push(Routes.parametres),
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
              return const Center(child: CircularProgressIndicator(color: PixelCouleurs.violetClair));
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
                    color: PixelCouleurs.violetClair,
                    backgroundColor: PixelCouleurs.panneau,
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
        // Bouton d'action carré, or, ombre franche (style pixel).
        floatingActionButton: FloatingActionButton(
          heroTag: 'quests_list_fab',
          backgroundColor: PixelCouleurs.or,
          foregroundColor: PixelCouleurs.nuit,
          elevation: 0,
          shape: const RoundedRectangleBorder(side: BorderSide(color: PixelCouleurs.orClair, width: 3)),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateQuestChoicePage()),
            );
            await _load();
          },
          tooltip: 'Nouvelle quête',
          child: const Icon(Icons.add, size: 30, semanticLabel: 'Nouvelle quête'),
        ),
      ),
    );
  }
}

// ── Onglets ──────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              label: 'À faire',
              count: activeCount,
              missedCount: missedCount,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: 'Terminées',
              count: completedCount,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
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
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? PixelCouleurs.violet : PixelCouleurs.panneau,
            border: Border.all(color: selected ? PixelCouleurs.violetClair : PixelCouleurs.trait, width: 3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: PixelTextes.corps(16,
                      couleur: selected ? PixelCouleurs.texte : PixelCouleurs.texteDoux, poids: FontWeight.w700)),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: selected ? PixelCouleurs.nuit : PixelCouleurs.violetSombre,
                  child: Text('$count', style: PixelTextes.chiffres(9, PixelCouleurs.texte)),
                ),
              ],
              if (missedCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: PixelCouleurs.nuit,
                    border: Border.all(color: AppColors.coralRare, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.coralRare, size: 12),
                      const SizedBox(width: 2),
                      Text('$missedCount', style: PixelTextes.chiffres(9, AppColors.coralRare)),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
      height: 52,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
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
              icon: Icons.filter_alt_off_outlined,
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
      backgroundColor: PixelCouleurs.panneau,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: PixelCouleurs.trait, width: 3),
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
                style: PixelTextes.corps(17,
                    couleur: selected ? PixelCouleurs.violetClair : PixelCouleurs.texte,
                    poids: selected ? FontWeight.w700 : FontWeight.w400),
              ),
              trailing: selected ? const Icon(Icons.check, color: PixelCouleurs.violetClair) : null,
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
            ? PixelCouleurs.texte
            : PixelCouleurs.texteDoux;

    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? PixelCouleurs.violet : PixelCouleurs.panneau,
            border: Border.all(
              color: danger
                  ? AppColors.coralRare
                  : active
                      ? PixelCouleurs.violetClair
                      : PixelCouleurs.trait,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: PixelTextes.corps(15, couleur: color, poids: active ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
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
      return const _Vide(icone: Icons.explore_outlined, texte: 'Aucune quête en cours');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (missed.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.coralRare, size: 16),
              const SizedBox(width: 6),
              Text('En retard', style: PixelTextes.chiffres(10, AppColors.coralRare)),
            ],
          ),
          const SizedBox(height: 8),
          ...missed.map((q) => _QuestCard(quest: q, missed: true, onReload: onReload)),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('À venir', style: PixelTextes.chiffres(10, PixelCouleurs.texteDoux)),
            const SizedBox(height: 8),
          ],
        ],
        ...active.map((q) => _QuestCard(quest: q, onReload: onReload)),
      ],
    );
  }
}

/// État vide : icône et texte, centrés (défilables pour garder le
/// « tirer pour rafraîchir »).
class _Vide extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _Vide({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => ListView(
          children: [
            SizedBox(
              height: c.maxHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, size: 44, color: PixelCouleurs.trait),
                  const SizedBox(height: 12),
                  Text(texte, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
                ],
              ),
            ),
          ],
        ),
      );
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
    if (quests.isEmpty) return _Vide(icone: emptyIcon, texte: emptyLabel);

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

// ── Carte de quête ────────────────────────────────────────────────────────────

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

  Color get _rarityColor => AppColors.getRarityColor(quest.rarity.name);

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
    AppNotification.show(
      context,
      message: '"${quest.title}" supprimée',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bord = missed
        ? AppColors.coralRare
        : completed
            ? PixelCouleurs.trait
            : _rarityColor;
    final (icone, couleurIcone) = switch (quest.validationType) {
      ValidationType.photo => (Icons.photo_camera_outlined, PixelCouleurs.oracle),
      ValidationType.timer => (Icons.timer_outlined, PixelCouleurs.orClair),
      ValidationType.geolocation => (Icons.place_outlined, AppColors.mintMagic),
      ValidationType.manual => (Icons.check_box_outlined, PixelCouleurs.violetClair),
    };
    final duree = quest.estimatedDurationMinutes > 0 ? '${quest.estimatedDurationMinutes} min' : null;

    final tile = MergeSemantics(
      child: Semantics(
        button: true,
        hint: 'Difficulté ${quest.difficulty} sur 5',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => QuestDetailSheet.show(
            context,
            quest: quest,
            onValidate: completed
                ? null
                : () {
                    context
                        .push(Routes.validerQuete(quest.id ?? ''), extra: quest)
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PixelCadre(
              bord: bord,
              fond: completed ? const Color(0xFF140C30) : PixelCouleurs.panneau,
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PixelCouleurs.panneauProfond,
                      border: Border.all(color: completed ? PixelCouleurs.trait : couleurIcone, width: 2),
                    ),
                    child: Icon(icone, color: completed ? PixelCouleurs.texteDoux : couleurIcone, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PixelTextes.corps(17,
                                  couleur: completed ? PixelCouleurs.texteDoux : PixelCouleurs.texte,
                                  poids: FontWeight.w600)
                              .copyWith(decoration: completed ? TextDecoration.lineThrough : null),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(duree == null ? quest.category : '${quest.category} · $duree',
                                style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                            // difficulté : 5 cases
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (i) => Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  width: 6,
                                  height: 6,
                                  color: i < quest.difficulty
                                      ? (completed ? PixelCouleurs.trait : _rarityColor)
                                      : PixelCouleurs.violetSombre,
                                ),
                              ),
                            ),
                            _SmallBadge(label: _frequencyLabel),
                            _ValidationBadge(type: quest.validationType),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    completed ? Icons.check_circle : Icons.chevron_right,
                    color: completed ? AppColors.mintMagic : PixelCouleurs.texteDoux,
                    size: 22,
                  ),
                ],
              ),
            ),
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
          color: AppColors.coralRare.withValues(alpha: 0.18),
          border: Border.all(color: AppColors.coralRare, width: 3),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.coralRare, semanticLabel: 'Supprimer'),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: PixelCouleurs.nuit,
        border: Border.all(color: PixelCouleurs.trait, width: 2),
      ),
      child: Text(label, style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
    );
  }
}

class _ValidationBadge extends StatelessWidget {
  final ValidationType type;

  const _ValidationBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ValidationType.photo => ('Oracle', PixelCouleurs.oracle),
      ValidationType.timer => ('Minuteur', PixelCouleurs.orClair),
      ValidationType.geolocation => ('Lieu', AppColors.mintMagic),
      ValidationType.manual => ('Déclarative', PixelCouleurs.texteDoux),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: PixelCouleurs.nuit,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(label, style: PixelTextes.corps(13, couleur: color)),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: PixelCouleurs.texteDoux),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
            const SizedBox(height: 24),
            PixelBouton(libelle: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
