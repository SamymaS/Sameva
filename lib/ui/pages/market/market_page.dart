import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/item_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Page marché : boutique + vente d'items.
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
                  _SellTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  final _catalog = ItemFactory.getMarketCatalog();

  _ShopTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _catalog.length,
      itemBuilder: (context, i) {
        final item = _catalog[i];
        return _ShopItemTile(item: item);
      },
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  final Item item;

  const _ShopItemTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

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
                Text(item.name,
                    style: TextStyle(
                        color: _rarityColor, fontWeight: FontWeight.bold)),
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
                        ? () => _buy(ctx, player, inventory, item)
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

  void _buy(BuildContext context, PlayerProvider player,
      InventoryProvider inventory, Item item) {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? '';
    player.addGold(userId, -item.goldValue);
    final newItem = item.copyWith(id: UniqueKey().toString());
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
                border:
                    Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(item.getIcon(), color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.name,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold)),
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
                    onPressed: () {
                      final player = context.read<PlayerProvider>();
                      final auth = context.read<AuthProvider>();
                      final userId = auth.userId ?? '';
                      inventory.removeItem(item.id);
                      if (player.stats != null) {
                        player.addGold(userId, sellPrice);
                      }
                    },
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
}
