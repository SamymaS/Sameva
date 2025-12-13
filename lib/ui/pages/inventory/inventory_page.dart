import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../domain/entities/item.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ItemType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Inventaire',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTurquoise,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryTurquoise,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Équipement'),
            Tab(text: 'Consommables'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllItemsTab(),
          _buildEquippableItemsTab(),
          _buildConsumableItemsTab(),
        ],
      ),
    );
  }

  Widget _buildAllItemsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final items = inventoryProvider.items;
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre inventaire est vide',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final slot = items[index];
            return _buildItemCard(slot);
          },
        );
      },
    );
  }

  Widget _buildEquippableItemsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final items = inventoryProvider.getEquippableItems();
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.checkroom_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun équipement disponible',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final slot = items[index];
            return _buildItemCard(slot, showEquipButton: true);
          },
        );
      },
    );
  }

  Widget _buildConsumableItemsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final items = inventoryProvider.getItemsByType(ItemType.potion) +
            inventoryProvider.getItemsByType(ItemType.consumable);
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_drink_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun consommable disponible',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final slot = items[index];
            return _buildItemCard(slot, showUseButton: true);
          },
        );
      },
    );
  }

  Widget _buildItemCard(InventorySlot slot, {bool showEquipButton = false, bool showUseButton = false}) {
    final item = slot.item;
    final isEquipped = _isItemEquipped(item);
    
    return GestureDetector(
      onTap: () => _showItemDetails(item, slot.quantity),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkPanel.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEquipped ? AppColors.primaryTurquoise : AppColors.inputBorder,
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image de l'item
            if (item.imagePath != null)
              Image.asset(
                item.imagePath!,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getItemIcon(item.type),
                    size: 48,
                    color: AppColors.primary,
                  );
                },
              )
            else
              Icon(
                _getItemIcon(item.type),
                size: 48,
                color: AppColors.primary,
              ),
            const SizedBox(height: 8),
            // Nom de l'item
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Quantité
            if (slot.quantity > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FantasyBadge(
                  label: 'x${slot.quantity}',
                  variant: BadgeVariant.secondary,
                ),
              ),
            // Badge de rareté
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FantasyBadge(
                label: _getRarityLabel(item.rarity),
                variant: _getRarityBadgeVariant(item.rarity),
              ),
            ),
            // Bouton équiper/utiliser
            if (showEquipButton && item.isEquippable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: isEquipped
                      ? () => _unequipItem(item)
                      : () => _equipItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped ? AppColors.success : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 24),
                  ),
                  child: Text(
                    isEquipped ? 'Équipé' : 'Équiper',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            if (showUseButton && item.isConsumable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: () => _useItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 24),
                  ),
                  child: const Text(
                    'Utiliser',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isItemEquipped(Item item) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final equippedId = equipmentProvider.getEquippedItemId(item.type);
    return equippedId == item.id;
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
      case ItemType.companion:
        return Icons.pets;
      default:
        return Icons.inventory_2;
    }
  }

  String _getRarityLabel(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return 'Commun';
      case ItemRarity.uncommon:
        return 'Peu commun';
      case ItemRarity.rare:
        return 'Rare';
      case ItemRarity.veryRare:
        return 'Très rare';
      case ItemRarity.epic:
        return 'Épique';
      case ItemRarity.legendary:
        return 'Légendaire';
      case ItemRarity.mythic:
        return 'Mythique';
    }
  }

  BadgeVariant _getRarityBadgeVariant(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return BadgeVariant.secondary;
      case ItemRarity.uncommon:
        return BadgeVariant.default_;
      case ItemRarity.rare:
        return BadgeVariant.default_;
      case ItemRarity.veryRare:
        return BadgeVariant.default_;
      case ItemRarity.epic:
        return BadgeVariant.default_;
      case ItemRarity.legendary:
        return BadgeVariant.default_;
      case ItemRarity.mythic:
        return BadgeVariant.default_;
    }
  }

  void _showItemDetails(Item item, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel.withOpacity(0.3),
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
              Text('Quantité: $quantity'),
              Text('Valeur: ${item.value} pièces d\'or'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _equipItem(Item item) async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final success = await equipmentProvider.equipItem('', item);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} équipé'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'équiper cet item'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _unequipItem(Item item) async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final success = await equipmentProvider.unequipItem('', item.type);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} déséquipé'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  void _useItem(Item item) async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    // Appliquer les effets de l'item
    if (item.healthBonus != null && item.healthBonus! > 0) {
      await playerProvider.heal('', item.healthBonus!);
    }
    if (item.experienceBonus != null && item.experienceBonus! > 0) {
      await playerProvider.addExperience('', item.experienceBonus!);
    }
    if (item.goldBonus != null && item.goldBonus! > 0) {
      await playerProvider.addGold('', item.goldBonus!);
    }
    
    // Retirer l'item de l'inventaire
    await inventoryProvider.removeItem('', item.id, quantity: 1);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} utilisé'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

