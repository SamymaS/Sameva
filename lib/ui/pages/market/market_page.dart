import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/services/item_factory.dart';

/// MARCHÉ — Page du marché avec achat réel
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  // Items disponibles à l'achat
  static List<Item> get availableItems => ItemFactory.createDefaultItems();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec titre et or du joueur
            Consumer<PlayerProvider>(
              builder: (context, playerProvider, child) {
                final stats = playerProvider.stats;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Marché',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stats?.gold ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            // Grille d'items
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: availableItems.length,
                itemBuilder: (context, index) {
                  final item = availableItems[index];
                  return _MarketItemCard(
                    item: item,
                    onBuy: () => _buyItem(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyItem(BuildContext context, Item item) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final stats = playerProvider.stats;

    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Statistiques non chargées'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (stats.gold < item.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Or insuffisant'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Vérifier si l'inventaire a de la place
    if (inventoryProvider.isFull && !inventoryProvider.items.any((slot) => slot.item.id == item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inventaire plein'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Acheter l'item
    final success = await inventoryProvider.addItem('', item);
    if (success) {
      await playerProvider.addGold('', -item.value);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} acheté !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'acheter l\'item'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _MarketItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onBuy;

  const _MarketItemCard({
    required this.item,
    required this.onBuy,
  });

  Color get _rarityColor {
    switch (item.rarity) {
      case ItemRarity.common:
        return AppColors.common;
      case ItemRarity.uncommon:
        return AppColors.uncommon;
      case ItemRarity.rare:
        return AppColors.rare;
      case ItemRarity.veryRare:
        return AppColors.veryRare;
      case ItemRarity.epic:
        return AppColors.epic;
      case ItemRarity.legendary:
        return AppColors.legendary;
      case ItemRarity.mythic:
        return AppColors.mythic;
    }
  }

  String get _rarityLabel {
    switch (item.rarity) {
      case ItemRarity.common:
        return 'COMMUN';
      case ItemRarity.uncommon:
        return 'PEU COMMUN';
      case ItemRarity.rare:
        return 'RARE';
      case ItemRarity.veryRare:
        return 'TRÈS RARE';
      case ItemRarity.epic:
        return 'ÉPIQUE';
      case ItemRarity.legendary:
        return 'LÉGENDAIRE';
      case ItemRarity.mythic:
        return 'MYTHIQUE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final stats = playerProvider.stats;
        final canAfford = stats != null && stats.gold >= item.value;

        return FantasyCard(
          backgroundColor: AppColors.backgroundDarkPanel.withOpacity(0.3),
          border: Border.all(
            color: _rarityColor.withOpacity(0.5),
            width: 2,
          ),
          child: InkWell(
            onTap: () => _showItemDetails(context, item),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zone image avec badge
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image de l'item
                        if (item.imagePath != null)
                          Image.asset(
                            item.imagePath!,
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              _getItemIcon(item.type),
                              size: 48,
                              color: _rarityColor.withOpacity(0.7),
                            ),
                          )
                        else
                          Icon(
                            _getItemIcon(item.type),
                            size: 48,
                            color: _rarityColor.withOpacity(0.7),
                          ),
                        // Badge de rareté
                        Positioned(
                          top: 0,
                          right: 0,
                          child: FantasyBadge(
                            label: _rarityLabel,
                            variant: BadgeVariant.default_,
                            backgroundColor: _rarityColor,
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nom
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: _rarityColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Stats de l'item
                  if (item.attackBonus != null || item.defenseBonus != null || item.healthBonus != null)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      alignment: WrapAlignment.center,
                      children: [
                        if (item.attackBonus != null)
                          Text(
                            '⚔️ +${item.attackBonus}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        if (item.defenseBonus != null)
                          Text(
                            '🛡️ +${item.defenseBonus}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        if (item.healthBonus != null)
                          Text(
                            '❤️ +${item.healthBonus}',
                            style: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  // Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? const Color(0xFFF59E0B) : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bouton d'achat
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canAfford ? onBuy : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? AppColors.primaryTurquoise : AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Acheter',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getItemIcon(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return Icons.sports_martial_arts;
      case ItemType.armor:
        return Icons.shield;
      case ItemType.helmet:
        return Icons.construction;
      case ItemType.shield:
        return Icons.shield_outlined;
      case ItemType.potion:
        return Icons.local_drink;
      case ItemType.consumable:
        return Icons.fastfood;
      case ItemType.cosmetic:
        return Icons.checkroom;
      default:
        return Icons.inventory_2;
    }
  }

  void _showItemDetails(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          item.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (item.attackBonus != null)
                Text('Attaque: +${item.attackBonus}'),
              if (item.defenseBonus != null)
                Text('Défense: +${item.defenseBonus}'),
              if (item.healthBonus != null)
                Text('PV: +${item.healthBonus}'),
              if (item.experienceBonus != null)
                Text('XP: +${item.experienceBonus}'),
              if (item.goldBonus != null)
                Text('Or: +${item.goldBonus}'),
              const SizedBox(height: 8),
              Text('Prix: ${item.value} pièces d\'or'),
              if (item.isEquippable)
                const Text('✓ Équipable', style: TextStyle(color: AppColors.success)),
              if (item.isConsumable)
                const Text('✓ Consommable', style: TextStyle(color: AppColors.info)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          Consumer<PlayerProvider>(
            builder: (context, playerProvider, child) {
              final stats = playerProvider.stats;
              final canAfford = stats != null && stats.gold >= item.value;
              return ElevatedButton(
                onPressed: canAfford ? () {
                  Navigator.of(context).pop();
                  onBuy();
                } : null,
                child: const Text('Acheter'),
              );
            },
          ),
        ],
      ),
    );
  }
}
