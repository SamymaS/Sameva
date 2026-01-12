import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/minimalist/hud_header.dart';
import '../../widgets/minimalist/minimalist_card.dart';
import '../../widgets/magical/animated_background.dart';
import '../../widgets/magical/glowing_card.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/services/item_factory.dart';

/// MARCHÉ — Page du marché avec achat réel
/// Selon pages.md : "Le Marché Astral" avec timer de rafraîchissement
class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  // Timer de rafraîchissement (selon pages.md)
  DateTime? _lastRefresh;
  Duration _refreshCooldown = const Duration(hours: 24); // Rafraîchissement quotidien

  // Items disponibles à l'achat
  List<Item> get availableItems => ItemFactory.createDefaultItems();

  @override
  void initState() {
    super.initState();
    _lastRefresh = DateTime.now();
  }

  bool get canRefresh => _lastRefresh == null || 
      DateTime.now().difference(_lastRefresh!) >= _refreshCooldown;

  Duration get timeUntilRefresh {
    if (_lastRefresh == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastRefresh!);
    if (elapsed >= _refreshCooldown) return Duration.zero;
    return _refreshCooldown - elapsed;
  }

  Widget _buildRefreshTimer() {
    final timeLeft = timeUntilRefresh;
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;
    
    if (canRefresh) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryTurquoise.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryTurquoise),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 16, color: AppColors.primaryTurquoise),
            const SizedBox(width: 6),
            Text(
              'Prêt à rafraîchir',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryTurquoise,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'Rafraîchissement dans: ${hours}h ${minutes}m',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMagicalBackground(
        child: Stack(
          children: [
            // Header HUD
          Consumer<PlayerProvider>(
            builder: (context, playerProvider, _) {
              final stats = playerProvider.stats;
              return HUDHeader(
                level: stats?.level ?? 1,
                experience: stats?.experience ?? 0,
                maxExperience: playerProvider.experienceForLevel(stats?.level ?? 1),
                healthPoints: stats?.healthPoints ?? 100,
                maxHealthPoints: stats?.maxHealthPoints ?? 100,
                gold: stats?.gold ?? 0,
                crystals: stats?.crystals ?? 0,
                onSettingsTap: () {
                  // Navigation vers settings
                },
              );
            },
          ),
          // Contenu
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80), // Espace pour le header
                // Titre et timer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Le Marché Astral',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRefreshTimer(),
                    ],
                  ),
                ),
                // Grille d'items
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Padding en bas pour le dock
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

        return GlowingCard(
          glowColor: _rarityColor,
          borderWidth: 2,
          onTap: () => _showItemDetails(context, item),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _rarityColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _rarityLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
