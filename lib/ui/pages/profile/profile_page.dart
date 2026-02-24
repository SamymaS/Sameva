import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/view_models/profile_view_model.dart';
import '../../theme/app_colors.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null && _vm == null) {
      _vm = ProfileViewModel(
        context.read<AuthProvider>(),
        context.read<PlayerProvider>(),
        context.read<QuestProvider>(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _vm != null) _vm!.load(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<ProfileViewModel>.value(
      value: _vm!,
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundNightBlue,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _ProfileContent(vm: vm);
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileViewModel vm;

  const _ProfileContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final inventory = context.watch<InventoryProvider>();
    final equipment = context.watch<EquipmentProvider>();
    final stats = player.stats;

    final level = stats?.level ?? 1;
    final experience = stats?.experience ?? 0;
    final xpForNext = player.experienceForLevel(level);
    final xpProgress = xpForNext > 0 ? (experience / xpForNext).clamp(0.0, 1.0) : 0.0;

    final quests = context.watch<QuestProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      body: CustomScrollView(
        slivers: [
          // AppBar avec dégradé
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.backgroundNightBlue,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(
                vm: vm,
                level: level,
                experience: experience,
                xpForNext: xpForNext,
                xpProgress: xpProgress,
                stats: stats,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Ligne de stats rapides
                _QuickStatsRow(stats: stats, vm: vm),
                const SizedBox(height: 16),

                // Équipement résumé
                _EquipmentSummary(equipment: equipment),
                const SizedBox(height: 16),

                // Inventaire
                _InventorySummary(inventory: inventory),
                const SizedBox(height: 16),

                // Statistiques
                _StatisticsSection(quests: quests),
                const SizedBox(height: 16),

                // Achievements
                _AchievementsSection(stats: stats),
                const SizedBox(height: 24),

                // Déconnexion
                _LogoutButton(vm: vm),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ProfileViewModel vm;
  final int level;
  final int experience;
  final int xpForNext;
  final double xpProgress;
  final PlayerStats? stats;

  const _HeroHeader({
    required this.vm,
    required this.level,
    required this.experience,
    required this.xpForNext,
    required this.xpProgress,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundDeepViolet, AppColors.backgroundNightBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryTurquoise, AppColors.secondaryViolet],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTurquoise.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.userEmail != null)
                      Text(
                        vm.userEmail!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTurquoise.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primaryTurquoise, width: 1),
                          ),
                          child: Text(
                            'Niv. $level',
                            style: const TextStyle(
                              color: AppColors.primaryTurquoise,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if ((stats?.streak ?? 0) >= 7)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: Colors.orange, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '${stats!.streak}j',
                                  style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Barre XP
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: xpProgress,
                              backgroundColor:
                                  AppColors.backgroundNightBlue,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryTurquoise),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$experience/$xpForNext',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats rapides ────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final PlayerStats? stats;
  final ProfileViewModel vm;

  const _QuickStatsRow({required this.stats, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.monetization_on,
          color: AppColors.gold,
          label: '${stats?.gold ?? 0}',
          sublabel: 'Or',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.diamond,
          color: AppColors.secondaryVioletGlow,
          label: '${stats?.crystals ?? 0}',
          sublabel: 'Cristaux',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.favorite,
          color: Colors.redAccent,
          label: '${stats?.healthPoints ?? 100}',
          sublabel: 'HP',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          label: '${vm.completedCount}',
          sublabel: 'Quêtes',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              sublabel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Équipement ───────────────────────────────────────────────────────────────

class _EquipmentSummary extends StatelessWidget {
  final EquipmentProvider equipment;

  const _EquipmentSummary({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final equipped =
        equipment.equipped.values.where((i) => i != null).toList();
    final xp = equipment.xpBonusPercent;
    final gold = equipment.goldBonusPercent;
    final hp = equipment.hpBonus;

    return _SectionCard(
      title: 'Équipement',
      icon: Icons.shield_outlined,
      child: equipped.isEmpty
          ? const Text(
              'Aucun équipement actif.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: equipped.map((item) {
                    final color =
                        AppColors.getRarityColor(item!.rarity.name);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.getIcon(), color: color, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            item.name,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (xp > 0 || gold > 0 || hp > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (xp > 0)
                        _BonusBadge('+$xp% XP', AppColors.primaryTurquoise),
                      if (gold > 0)
                        _BonusBadge('+$gold% Or', AppColors.gold),
                      if (hp > 0)
                        _BonusBadge('+$hp HP', Colors.redAccent),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _BonusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _BonusBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Inventaire ───────────────────────────────────────────────────────────────

class _InventorySummary extends StatelessWidget {
  final InventoryProvider inventory;

  const _InventorySummary({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final items = inventory.items;
    final weapons = items.where((i) => i.type == ItemType.weapon).length;
    final armors = items
        .where((i) =>
            i.type == ItemType.armor ||
            i.type == ItemType.helmet ||
            i.type == ItemType.boots ||
            i.type == ItemType.ring)
        .length;
    final potions = items.where((i) => i.type == ItemType.potion).length;

    return _SectionCard(
      title: 'Inventaire',
      icon: Icons.inventory_2_outlined,
      trailing: Text(
        '${items.length}/50',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      child: items.isEmpty
          ? const Text(
              'Inventaire vide.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          : Row(
              children: [
                _InvTypeChip(Icons.auto_fix_high, '$weapons', 'Armes',
                    AppColors.rarityLegendary),
                const SizedBox(width: 8),
                _InvTypeChip(Icons.shield_outlined, '$armors', 'Armures',
                    AppColors.rarityRare),
                const SizedBox(width: 8),
                _InvTypeChip(Icons.local_pharmacy, '$potions', 'Potions',
                    AppColors.success),
              ],
            ),
    );
  }
}

class _InvTypeChip extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _InvTypeChip(this.icon, this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(count,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Achievements ─────────────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final PlayerStats? stats;

  const _AchievementsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final unlocked = stats?.achievements ?? {};
    final definitions = PlayerProvider.achievementDefinitions;
    final unlockedCount = unlocked.length;

    return _SectionCard(
      title: 'Succès',
      icon: Icons.emoji_events_outlined,
      trailing: Text(
        '$unlockedCount/${definitions.length}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: definitions.length,
        itemBuilder: (context, i) {
          final def = definitions[i];
          final isUnlocked = unlocked.containsKey(def['id']);
          return GestureDetector(
            onTap: () => _showAchievementTooltip(context, def, isUnlocked),
            child: Container(
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnlocked
                      ? AppColors.gold.withValues(alpha: 0.6)
                      : AppColors.inputBorder,
                  width: isUnlocked ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconForName(def['icon'] ?? 'star'),
                    color: isUnlocked
                        ? AppColors.gold
                        : AppColors.textMuted.withValues(alpha: 0.4),
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  if (isUnlocked)
                    const Icon(Icons.check,
                        color: AppColors.gold, size: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAchievementTooltip(
      BuildContext context, Map<String, String> def, bool isUnlocked) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(_iconForName(def['icon'] ?? 'star'),
              color: isUnlocked ? AppColors.gold : AppColors.textMuted,
              size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(def['description'] ?? '',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (!isUnlocked)
            const Text('🔒',
                style: TextStyle(fontSize: 16)),
        ],
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: isUnlocked
          ? AppColors.gold.withValues(alpha: 0.2)
          : AppColors.backgroundDarkPanel,
    ));
  }

  IconData _iconForName(String name) {
    return switch (name) {
      'star' => Icons.star,
      'military_tech' => Icons.military_tech,
      'emoji_events' => Icons.emoji_events,
      'workspace_premium' => Icons.workspace_premium,
      'local_fire_department' => Icons.local_fire_department,
      'whatshot' => Icons.whatshot,
      'bolt' => Icons.bolt,
      'trending_up' => Icons.trending_up,
      'school' => Icons.school,
      'psychology' => Icons.psychology,
      'paid' => Icons.paid,
      'diamond' => Icons.diamond,
      'inventory_2' => Icons.inventory_2,
      'warehouse' => Icons.warehouse,
      'self_improvement' => Icons.self_improvement,
      _ => Icons.star_outline,
    };
  }
}

// ─── Déconnexion ──────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final ProfileViewModel vm;

  const _LogoutButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.backgroundDarkPanel,
            title: const Text('Déconnexion',
                style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('Voulez-vous vraiment vous déconnecter ?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Déconnecter'),
              ),
            ],
          ),
        );
        if (confirmed == true) await vm.signOut();
      },
      icon: const Icon(Icons.logout),
      label: const Text('Se déconnecter'),
    );
  }
}

// ─── Statistiques ─────────────────────────────────────────────────────────────

class _StatisticsSection extends StatelessWidget {
  final QuestProvider quests;

  const _StatisticsSection({required this.quests});

  @override
  Widget build(BuildContext context) {
    final completed = quests.completedQuests;

    // Quêtes par catégorie
    final byCategory = <String, int>{};
    for (final q in completed) {
      byCategory[q.category] = (byCategory[q.category] ?? 0) + 1;
    }
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = sortedCategories.isEmpty ? 1 : sortedCategories.first.value;

    // 7 derniers jours
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final byDay = <DateTime, int>{for (final d in days) d: 0};
    for (final q in completed) {
      if (q.completedAt == null) continue;
      final d = DateTime(q.completedAt!.year, q.completedAt!.month, q.completedAt!.day);
      if (byDay.containsKey(d)) byDay[d] = byDay[d]! + 1;
    }
    final maxDay = byDay.values.isEmpty ? 1 : byDay.values.reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Statistiques',
      icon: Icons.bar_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7 derniers jours
          const Text(
            '7 derniers jours',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((d) {
              final count = byDay[d] ?? 0;
              final ratio = maxDay > 0 ? count / maxDay : 0.0;
              final isToday = d == DateTime(now.year, now.month, now.day);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Text(
                          '$count',
                          style: const TextStyle(
                              color: AppColors.primaryTurquoise,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 4 + ratio * 48,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primaryTurquoise
                              : AppColors.primaryTurquoise.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayLabel(d),
                        style: TextStyle(
                          color: isToday
                              ? AppColors.primaryTurquoise
                              : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (sortedCategories.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Par catégorie',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...sortedCategories.take(5).map((entry) {
              final ratio = maxCat > 0 ? entry.value / maxCat : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor:
                              AppColors.backgroundNightBlue,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondaryViolet),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                          color: AppColors.secondaryVioletGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Taux de réussite
          if (quests.quests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final total = quests.quests.length;
              final rate = completed.length / total;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Taux de réussite',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '${(rate * 100).round()}%  (${completed.length}/$total)',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const labels = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    return labels[d.weekday - 1];
  }
}

// ─── Carte section réutilisable ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.inputBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryTurquoise, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
