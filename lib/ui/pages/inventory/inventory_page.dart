import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/item_icon.dart';
import '../cat/cat_page.dart';

/// Page inventaire — grille 4 colonnes avec cartes item visuelles.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  QuestRarity? _rarityFilter;
  ItemType? _typeFilter;

  List<Item> _applyFilters(List<Item> items) {
    return items.where((item) {
      if (_rarityFilter != null && item.rarity != _rarityFilter) return false;
      if (_typeFilter != null && item.type != _typeFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Inventaire',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<InventoryViewModel>(
            builder: (_, inv, __) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDarkPanel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryTurquoise.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          color: AppColors.primaryTurquoise.withValues(alpha: 0.8),
                          size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${inv.items.length}/50',
                        style: const TextStyle(
                            color: AppColors.primaryTurquoise,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.pets_outlined,
                color: AppColors.textSecondary, size: 22),
            tooltip: 'Chat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatPage()),
            ),
          ),
        ],
      ),
      body: Consumer2<InventoryViewModel, EquipmentViewModel>(
        builder: (context, inventory, equipment, _) {
          final filtered = _applyFilters(inventory.items);
          final hasFilter = _rarityFilter != null || _typeFilter != null;

          return Column(
            children: [
              // ── Chips de filtre ─────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    // Reset
                    if (hasFilter)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: const Text('Tout'),
                          avatar: const Icon(Icons.clear, size: 14),
                          backgroundColor: AppColors.backgroundDarkPanel,
                          labelStyle: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                          onPressed: () => setState(() {
                            _rarityFilter = null;
                            _typeFilter = null;
                          }),
                        ),
                      ),
                    // Filtre type
                    ...ItemType.values.map((t) {
                      final selected = _typeFilter == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_typeLabel(t)),
                          selected: selected,
                          selectedColor:
                              AppColors.primaryTurquoise.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primaryTurquoise,
                          backgroundColor: AppColors.backgroundDarkPanel,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.primaryTurquoise
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primaryTurquoise
                                : AppColors.textMuted.withValues(alpha: 0.2),
                          ),
                          onSelected: (_) => setState(() =>
                              _typeFilter = selected ? null : t),
                        ),
                      );
                    }),
                    // Filtre rareté
                    ...QuestRarity.values.map((r) {
                      final selected = _rarityFilter == r;
                      final color = _rarityColor(r);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_rarityLabel(r)),
                          selected: selected,
                          selectedColor: color.withValues(alpha: 0.15),
                          checkmarkColor: color,
                          backgroundColor: AppColors.backgroundDarkPanel,
                          labelStyle: TextStyle(
                            color: selected ? color : AppColors.textMuted,
                            fontSize: 11,
                          ),
                          side: BorderSide(
                            color: selected
                                ? color
                                : AppColors.textMuted.withValues(alpha: 0.2),
                          ),
                          onSelected: (_) => setState(() =>
                              _rarityFilter = selected ? null : r),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // ── Grille ──────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty && inventory.items.isEmpty
                    ? _EmptyInventory()
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun objet correspondant',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: hasFilter
                                ? filtered.length
                                : 50,
                            itemBuilder: (context, index) {
                              final item = index < filtered.length
                                  ? filtered[index]
                                  : null;
                              if (item == null) {
                                return _EmptySlot(index: index);
                              }
                              return _FilledSlot(
                                item: item,
                                isEquipped: equipment.equipped.values
                                    .any((e) => e?.id == item.id),
                                onTap: () => _showItemSheet(
                                    context, item, inventory, equipment),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showItemSheet(BuildContext context, Item item,
      InventoryViewModel inventory, EquipmentViewModel equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemSheet(
        item: item,
        inventory: inventory,
        equipment: equipment,
      ),
    );
  }

  String _typeLabel(ItemType t) => switch (t) {
        ItemType.weapon   => 'Arme',
        ItemType.armor    => 'Armure',
        ItemType.helmet   => 'Casque',
        ItemType.boots    => 'Bottes',
        ItemType.ring     => 'Bague',
        ItemType.potion   => 'Potion',
        ItemType.material => 'Matériau',
        ItemType.cosmetic => 'Cosmétique',
      };

  String _rarityLabel(QuestRarity r) => switch (r) {
        QuestRarity.common    => 'Commun',
        QuestRarity.uncommon  => 'Peu commun',
        QuestRarity.rare      => 'Rare',
        QuestRarity.epic      => 'Épique',
        QuestRarity.legendary => 'Légendaire',
        QuestRarity.mythic    => 'Mythique',
      };

  Color _rarityColor(QuestRarity r) => switch (r) {
        QuestRarity.common    => AppColors.rarityCommon,
        QuestRarity.uncommon  => AppColors.rarityUncommon,
        QuestRarity.rare      => AppColors.rarityRare,
        QuestRarity.epic      => AppColors.rarityEpic,
        QuestRarity.legendary => AppColors.rarityLegendary,
        QuestRarity.mythic    => AppColors.rarityMythic,
      };
}

// ── Slot rempli ──────────────────────────────────────────────────────────────

class _FilledSlot extends StatelessWidget {
  final Item item;
  final bool isEquipped;
  final VoidCallback onTap;

  const _FilledSlot({
    required this.item,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRarityColor(item.rarity.name);
    final isHighRarity = item.rarity == QuestRarity.epic ||
        item.rarity == QuestRarity.legendary ||
        item.rarity == QuestRarity.mythic;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isHighRarity ? 0.8 : 0.45),
            width: isHighRarity ? 1.5 : 1,
          ),
          boxShadow: isHighRarity
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Icône centrée
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),
                  ItemIcon(item: item, size: 40, showBackground: false),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Badge quantité
            if (item.stackable && item.quantity > 1)
              Positioned(
                bottom: 4,
                right: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundNightBlue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '×${item.quantity}',
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            // Badge équipé
            if (isEquipped)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurquoise,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.backgroundNightBlue, width: 1.5),
                  ),
                  child: const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ),
            // Indicateur point de rareté (bas-gauche)
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slot vide ────────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  final int index;

  const _EmptySlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.inputBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.2),
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ── Inventaire vide ──────────────────────────────────────────────────────────

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Inventaire vide',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Validez des quêtes ou visitez\nla boutique pour obtenir des items.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet Item ─────────────────────────────────────────────────────────

class _ItemSheet extends StatelessWidget {
  final Item item;
  final InventoryViewModel inventory;
  final EquipmentViewModel equipment;

  const _ItemSheet({
    required this.item,
    required this.inventory,
    required this.equipment,
  });

  Color get _color => AppColors.getRarityColor(item.rarity.name);

  bool get _isEquipped =>
      equipment.equipped.values.any((e) => e?.id == item.id);

  String _rarityLabel(QuestRarity r) => switch (r) {
        QuestRarity.common => 'Commune',
        QuestRarity.uncommon => 'Peu commune',
        QuestRarity.rare => 'Rare',
        QuestRarity.epic => 'Épique',
        QuestRarity.legendary => 'Légendaire',
        QuestRarity.mythic => 'Mythique',
      };

  @override
  Widget build(BuildContext context) {
    final slot = Item.slotForItem(item);
    final cosSlot = Item.cosmeticSlotForItem(item);
    final player = context.read<PlayerViewModel>();
    final userId = context.read<AuthViewModel>().userId ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // En-tête avec dégradé
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color.withValues(alpha: 0.25),
                  _color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                // Icône large avec glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _color.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ItemIcon(
                        item: item, size: 56, showBackground: false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge rareté
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _color.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _rarityLabel(item.rarity).toUpperCase(),
                          style: TextStyle(
                            color: _color,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Nom
                      Text(
                        item.name,
                        style: TextStyle(
                          color: _color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Type
                      Text(
                        _typeLabel(item.type),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Corps
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                // Stats
                if (item.stats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _StatsGrid(stats: item.stats, color: _color),
                ],

                // Comparaison avec l'item actuellement équipé
                if (slot != null && !_isEquipped) ...[
                  const SizedBox(height: 16),
                  _EquipComparison(
                    newItem: item,
                    currentItem: equipment.getSlot(slot),
                  ),
                ],

                // Valeur de vente
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: AppColors.gold.withValues(alpha: 0.7), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Vaut ${(item.goldValue * 0.5).round()} or (revente 50%)',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Boutons d'action
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
            child: _ActionButtons(
              item: item,
              slot: slot,
              cosSlot: cosSlot,
              isEquipped: _isEquipped,
              equipment: equipment,
              inventory: inventory,
              player: player,
              userId: userId,
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(ItemType t) => switch (t) {
        ItemType.weapon => 'Arme',
        ItemType.armor => 'Armure',
        ItemType.helmet => 'Casque',
        ItemType.boots => 'Bottes',
        ItemType.ring => 'Anneau',
        ItemType.potion => 'Potion',
        ItemType.material => 'Matériau',
        ItemType.cosmetic => 'Cosmétique',
      };
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  final Color color;

  const _StatsGrid({required this.stats, required this.color});

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.where((e) => e.value != 0).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final label = switch (e.key) {
          'xpBonus' => '✦ XP +${e.value}%',
          'goldBonus' => '✦ Or +${e.value}%',
          'hpBonus' => '✦ HP +${e.value}',
          'moralBonus' => '✦ Moral +${e.value}',
          _ => '${e.key} +${e.value}',
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EquipComparison extends StatelessWidget {
  final Item newItem;
  final Item? currentItem;

  const _EquipComparison({required this.newItem, required this.currentItem});

  static const _statKeys = ['hpBonus', 'xpBonus', 'goldBonus', 'moralBonus'];
  static const _statLabels = {
    'hpBonus': 'HP',
    'xpBonus': 'XP%',
    'goldBonus': 'Or%',
    'moralBonus': 'Moral',
  };

  @override
  Widget build(BuildContext context) {
    // Filtrer les stats pertinentes (present dans l'un ou l'autre)
    final keys = _statKeys.where((k) =>
        (newItem.stats[k] ?? 0) != 0 ||
        (currentItem?.stats[k] ?? 0) != 0).toList();

    if (keys.isEmpty && currentItem == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundNightBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                currentItem == null ? 'Emplacement vide' : 'vs ${currentItem!.name}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (keys.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...keys.map((k) {
              final cur = currentItem?.stats[k] ?? 0;
              final nw = newItem.stats[k] ?? 0;
              final delta = nw - cur;
              final label = _statLabels[k] ?? k;
              final deltaColor = delta > 0
                  ? AppColors.success
                  : delta < 0
                      ? AppColors.coralRare
                      : AppColors.textMuted;
              final deltaStr = delta > 0 ? '+$delta' : '$delta';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(label,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ),
                    Text('$cur',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward,
                          size: 10, color: AppColors.textMuted),
                    ),
                    Text('$nw',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (delta != 0)
                      Text(
                        '($deltaStr)',
                        style: TextStyle(
                            color: deltaColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Item item;
  final EquipmentSlot? slot;
  final String? cosSlot;
  final bool isEquipped;
  final EquipmentViewModel equipment;
  final InventoryViewModel inventory;
  final PlayerViewModel player;
  final String userId;

  const _ActionButtons({
    required this.item,
    required this.slot,
    required this.cosSlot,
    required this.isEquipped,
    required this.equipment,
    required this.inventory,
    required this.player,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRarityColor(item.rarity.name);
    final buttons = <Widget>[];

    // Équiper / Déséquiper
    if (slot != null) {
      if (!isEquipped) {
        buttons.add(Expanded(
          child: _ActionBtn(
            label: 'Équiper',
            icon: Icons.shield_outlined,
            color: color,
            onTap: () async {
              // Retirer le bonus de l'item actuellement en slot (s'il y en a un)
              final current = equipment.getSlot(slot!);
              if (current != null) {
                final oldHp = current.stats['hpBonus'] ?? 0;
                final oldMoral = current.stats['moralBonus'] ?? 0;
                if (oldHp > 0) await player.adjustMaxHp(userId, -oldHp);
                if (oldMoral > 0) await player.updateMoral(userId, -(oldMoral / 100.0));
              }
              equipment.equip(item, slot!, inventory);
              // Appliquer les bonus du nouvel item
              final hp = item.stats['hpBonus'] ?? 0;
              final moral = item.stats['moralBonus'] ?? 0;
              if (hp > 0) await player.adjustMaxHp(userId, hp);
              if (moral > 0) await player.updateMoral(userId, moral / 100.0);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ));
      } else {
        buttons.add(Expanded(
          child: _ActionBtn(
            label: 'Retirer',
            icon: Icons.remove_circle_outline,
            color: AppColors.textMuted,
            outlined: true,
            onTap: () async {
              final s = equipment.equipped.entries
                  .firstWhere((e) => e.value?.id == item.id)
                  .key;
              // Retirer les bonus avant de déséquiper
              final hp = item.stats['hpBonus'] ?? 0;
              final moral = item.stats['moralBonus'] ?? 0;
              if (hp > 0) await player.adjustMaxHp(userId, -hp);
              if (moral > 0) await player.updateMoral(userId, -(moral / 100.0));
              equipment.unequip(s, inventory);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ));
      }
    }

    // Cosmétique
    if (item.type == ItemType.cosmetic && cosSlot != null) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
      final isWorn = equipment.getCosmeticSlot(cosSlot!)?.id == item.id;
      buttons.add(Expanded(
        child: _ActionBtn(
          label: isWorn ? 'Retirer' : 'Porter',
          icon: isWorn
              ? Icons.remove_circle_outline
              : Icons.face_retouching_natural,
          color: isWorn ? AppColors.textMuted : AppColors.primaryViolet,
          outlined: isWorn,
          onTap: () {
            if (isWorn) {
              equipment.unequipCosmetic(cosSlot!, inventory);
            } else {
              equipment.equipCosmetic(item, cosSlot!, inventory);
            }
            Navigator.pop(context);
          },
        ),
      ));
    }

    // Potion
    if (item.type == ItemType.potion) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
      buttons.add(Expanded(
        child: _ActionBtn(
          label: 'Utiliser',
          icon: Icons.local_pharmacy,
          color: AppColors.success,
          onTap: () async {
            if (player.stats != null) {
              final hp = item.stats['hpBonus'] ?? 0;
              final xp = item.stats['xpBonus'] ?? 0;
              final moralRaw = item.stats['moralBonus'] ?? 0;
              final moral = moralRaw / 100.0;
              if (hp > 0) await player.heal(userId, hp);
              if (xp > 0) await player.addExperience(userId, xp);
              if (moral > 0) await player.updateMoral(userId, moral);
              if (hp == 0 && xp == 0 && moralRaw == 0) {
                await player.heal(userId, 20);
              }
            }
            inventory.removeItem(item.id);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ));
    }

    // Vendre (toujours)
    if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
    buttons.add(Expanded(
      child: _ActionBtn(
        label: 'Vendre',
        icon: Icons.sell_outlined,
        color: AppColors.gold,
        outlined: true,
        onTap: () {
          final price = (item.goldValue * 0.5).round();
          inventory.removeItem(item.id);
          if (player.stats != null) player.addGold(userId, price);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Vendu pour $price or'),
            backgroundColor: AppColors.backgroundDarkPanel,
          ));
        },
      ),
    ));

    return Row(children: buttons);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: outlined ? color.withValues(alpha: 0.5) : color,
            width: outlined ? 1 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
