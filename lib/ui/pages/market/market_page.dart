import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/item_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Page marché : boutique filtrée par catégorie + vente d'items.
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Marché',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<PlayerProvider>(
            builder: (_, player, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${player.stats?.gold ?? 0}',
                    style: const TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primaryTurquoise,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryTurquoise,
              tabs: [
                Tab(text: 'Boutique'),
                Tab(text: 'Vendre'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ShopTab(),
                  const _SellTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Libellés et types de filtre pour la boutique.
enum _ShopFilter {
  all,
  weapon,
  armor,
  accessory,
  potion,
  cosmetic,
}

extension _ShopFilterLabel on _ShopFilter {
  String get label => switch (this) {
        _ShopFilter.all => 'Tout',
        _ShopFilter.weapon => 'Armes',
        _ShopFilter.armor => 'Armures',
        _ShopFilter.accessory => 'Accessoires',
        _ShopFilter.potion => 'Potions',
        _ShopFilter.cosmetic => 'Cosmétiques',
      };

  bool matches(ItemType type) => switch (this) {
        _ShopFilter.all => true,
        _ShopFilter.weapon => type == ItemType.weapon,
        _ShopFilter.armor =>
          type == ItemType.armor || type == ItemType.helmet || type == ItemType.boots,
        _ShopFilter.accessory => type == ItemType.ring,
        _ShopFilter.potion => type == ItemType.potion,
        _ShopFilter.cosmetic => type == ItemType.cosmetic,
      };
}

class _ShopTab extends StatefulWidget {
  _ShopTab();

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  final List<Item> _catalog = ItemFactory.getMarketCatalog();
  _ShopFilter _activeFilter = _ShopFilter.all;

  List<Item> get _filtered =>
      _catalog.where((item) => _activeFilter.matches(item.type)).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtres catégorie
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _ShopFilter.values.map((f) {
              final active = f == _activeFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: active
                            ? AppColors.backgroundNightBlue
                            : AppColors.textSecondary,
                      )),
                  selected: active,
                  onSelected: (_) => setState(() => _activeFilter = f),
                  selectedColor: AppColors.primaryTurquoise,
                  backgroundColor: AppColors.backgroundDarkPanel,
                  checkmarkColor: AppColors.backgroundNightBlue,
                  side: BorderSide(
                    color: active
                        ? AppColors.primaryTurquoise
                        : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),
        // Indicateur inventaire plein
        Consumer<InventoryProvider>(
          builder: (_, inventory, __) {
            if (!inventory.isFull) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Inventaire plein — vendez des objets pour faire de la place.',
                    style: TextStyle(color: AppColors.error, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
        // Liste d'items
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text('Aucun objet dans cette catégorie.',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) =>
                      _ShopItemTile(item: _filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  final Item item;

  const _ShopItemTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  String get _typeLabel => switch (item.type) {
        ItemType.weapon => 'Arme',
        ItemType.armor => 'Armure',
        ItemType.helmet => 'Casque',
        ItemType.boots => 'Bottes',
        ItemType.ring => 'Anneau',
        ItemType.potion => 'Potion',
        ItemType.cosmetic => 'Cosmétique',
        ItemType.material => 'Matériau',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rarityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(item.getIcon(), color: _rarityColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name,
                        style: TextStyle(
                            color: _rarityColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _rarityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeLabel,
                        style: TextStyle(color: _rarityColor, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                Text(item.description,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.stats.isNotEmpty)
                  Text(
                    item.stats.entries
                        .map((e) => '+${e.value} ${_label(e.key)}')
                        .join(' · '),
                    style: const TextStyle(
                        color: AppColors.primaryTurquoise, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 2),
                  Text('${item.goldValue}',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Consumer2<PlayerProvider, InventoryProvider>(
                builder: (ctx, player, inventory, _) {
                  final canAfford =
                      (player.stats?.gold ?? 0) >= item.goldValue;
                  final hasSpace = !inventory.isFull;
                  return TextButton(
                    onPressed: canAfford && hasSpace
                        ? () => _confirmBuy(ctx, player, inventory, item)
                        : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Acheter',
                        style: TextStyle(fontSize: 12)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Demande confirmation pour les achats coûteux (≥ 200 or).
  Future<void> _confirmBuy(BuildContext context, PlayerProvider player,
      InventoryProvider inventory, Item item) async {
    if (item.goldValue >= 200) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundDarkPanel,
          title: const Text('Confirmer l\'achat',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acheter "${item.name}" pour',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 16),
                  const SizedBox(width: 4),
                  Text('${item.goldValue} pièces d\'or',
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTurquoise),
              child: const Text('Acheter',
                  style: TextStyle(color: AppColors.backgroundNightBlue)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!context.mounted) return;
    }
    _buy(context, player, inventory, item);
  }

  void _buy(BuildContext context, PlayerProvider player,
      InventoryProvider inventory, Item item) {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? '';
    player.addGold(userId, -item.goldValue);
    final newItem = item.copyWith(id: const Uuid().v4());
    inventory.addItem(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} acheté !')),
    );
  }

  String _label(String key) => switch (key) {
        'xpBonus' => 'XP',
        'goldBonus' => 'Or',
        'hpBonus' => 'HP',
        'moralBonus' => 'Moral',
        _ => key,
      };
}

class _SellTab extends StatelessWidget {
  const _SellTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        if (inventory.items.isEmpty) {
          return const Center(
            child: Text(
              'Votre inventaire est vide.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: inventory.items.length,
          itemBuilder: (context, i) {
            final item = inventory.items[i];
            final sellPrice = (item.goldValue * 0.5).round();
            final color = AppColors.getRarityColor(item.rarity.name);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(item.getIcon(), color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.bold)),
                        Text(
                          'Revente : $sellPrice pièces (50%)',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          color: AppColors.gold, size: 14),
                      const SizedBox(width: 2),
                      Text('$sellPrice',
                          style: const TextStyle(color: AppColors.gold)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _sell(context, inventory, item, sellPrice),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Vendre',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sell(BuildContext context, InventoryProvider inventory, Item item,
      int sellPrice) {
    final player = context.read<PlayerProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? '';
    inventory.removeItem(item.id);
    if (player.stats != null) {
      player.addGold(userId, sellPrice);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} vendu pour $sellPrice pièces.')),
    );
  }
}
