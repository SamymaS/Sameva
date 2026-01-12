import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../domain/entities/item.dart';
import '../../widgets/minimalist/minimalist_card.dart';
import '../../widgets/minimalist/minimalist_button.dart';
import '../../widgets/minimalist/fade_in_animation.dart';
import '../../widgets/magical/animated_background.dart';
import '../../widgets/magical/glowing_card.dart';
import '../../theme/app_colors.dart';

/// Page Inventaire - "Le Coffre Astral" - Refactorée "Magie Minimaliste"
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
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
      body: AnimatedMagicalBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header minimaliste
              _buildHeader(),

              // Tabs minimalistes
              _buildTabs(),

              const SizedBox(height: 12),

              // Grille d'items (avec padding en bas pour éviter le dock)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllItemsTab(),
                    _buildEquippableItemsTab(),
                    _buildConsumableItemsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le Coffre Astral',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<InventoryProvider>(
                builder: (context, inventoryProvider, _) {
                  return Text(
                    '${inventoryProvider.items.length} objets',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryTurquoise.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.primaryTurquoise,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'Équipement'),
          Tab(text: 'Consommables'),
        ],
      ),
    );
  }

  Widget _buildAllItemsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final items = inventoryProvider.items;

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'Votre inventaire est vide',
            subtitle: 'Obtenez des objets en complétant des quêtes',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding en bas pour éviter le dock
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final slot = items[index];
            return FadeInAnimation(
              delay: Duration(milliseconds: index * 30),
              child: _MinimalistItemCard(
                slot: slot,
                onTap: () => _showItemDetails(slot.item, slot.quantity),
              ),
            );
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
          return _buildEmptyState(
            icon: Icons.checkroom_outlined,
            message: 'Aucun équipement disponible',
            subtitle: 'Équipez-vous pour améliorer vos stats',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding en bas pour éviter le dock
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final slot = items[index];
            return FadeInAnimation(
              delay: Duration(milliseconds: index * 30),
              child: _MinimalistItemCard(
                slot: slot,
                showEquipButton: true,
                onTap: () => _showItemDetails(slot.item, slot.quantity),
                onEquip: () => _equipItem(slot.item),
                onUnequip: () => _unequipItem(slot.item),
              ),
            );
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
          return _buildEmptyState(
            icon: Icons.local_drink_outlined,
            message: 'Aucun consommable disponible',
            subtitle: 'Utilisez des potions pour restaurer vos stats',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding en bas pour éviter le dock
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final slot = items[index];
            return FadeInAnimation(
              delay: Duration(milliseconds: index * 30),
              child: _MinimalistItemCard(
                slot: slot,
                showUseButton: true,
                onTap: () => _showItemDetails(slot.item, slot.quantity),
                onUse: () => _useItem(slot.item),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Item item, int quantity) {
    showDialog(
      context: context,
      builder: (context) => MinimalistCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 16),
            if (item.attackBonus != null || item.defenseBonus != null || item.healthBonus != null)
              _buildStatRow('Stats', [
                if (item.attackBonus != null) '+${item.attackBonus} Attaque',
                if (item.defenseBonus != null) '+${item.defenseBonus} Défense',
                if (item.healthBonus != null) '+${item.healthBonus} PV',
              ]),
            const SizedBox(height: 12),
            _buildStatRow('Quantité', ['$quantity']),
            _buildStatRow('Valeur', ['${item.value} pièces d\'or']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          ...values.map((value) => Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )),
        ],
      ),
    );
  }

  void _equipItem(Item item) async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final success = await equipmentProvider.equipItem('', item);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} équipé'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _unequipItem(Item item) async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final success = await equipmentProvider.unequipItem('', item.type);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} déséquipé'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _useItem(Item item) async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // Appliquer les effets
    if (item.healthBonus != null && item.healthBonus! > 0) {
      await playerProvider.heal('', item.healthBonus!);
    }
    if (item.experienceBonus != null && item.experienceBonus! > 0) {
      await playerProvider.addExperience('', item.experienceBonus!);
    }
    if (item.goldBonus != null && item.goldBonus! > 0) {
      await playerProvider.addGold('', item.goldBonus!);
    }

    await inventoryProvider.removeItem('', item.id, quantity: 1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} utilisé'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Carte d'item minimaliste
class _MinimalistItemCard extends StatelessWidget {
  final InventorySlot slot;
  final bool showEquipButton;
  final bool showUseButton;
  final VoidCallback onTap;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;
  final VoidCallback? onUse;

  const _MinimalistItemCard({
    required this.slot,
    this.showEquipButton = false,
    this.showUseButton = false,
    required this.onTap,
    this.onEquip,
    this.onUnequip,
    this.onUse,
  });

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return AppColors.rarityCommon;
      case ItemRarity.uncommon:
        return AppColors.rarityUncommon;
      case ItemRarity.rare:
        return AppColors.rarityRare;
      case ItemRarity.veryRare:
      case ItemRarity.epic:
        return AppColors.rarityEpic;
      case ItemRarity.legendary:
        return AppColors.rarityLegendary;
      case ItemRarity.mythic:
        return AppColors.rarityMythic;
    }
  }

  bool _isItemEquipped(Item item, BuildContext context) {
    // Vérifie si l'item est équipé via EquipmentProvider
    try {
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final equippedId = equipmentProvider.getEquippedItemId(item.type);
      return equippedId == item.id;
    } catch (e) {
      return false;
    }
  }

  bool _shouldGlow(ItemRarity rarity) {
    return rarity == ItemRarity.epic ||
        rarity == ItemRarity.legendary ||
        rarity == ItemRarity.mythic;
  }

  IconData _getItemIcon(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return Icons.sports_martial_arts_outlined;
      case ItemType.armor:
        return Icons.shield_outlined;
      case ItemType.helmet:
        return Icons.construction_outlined;
      case ItemType.shield:
        return Icons.shield_outlined;
      case ItemType.potion:
        return Icons.local_drink_outlined;
      case ItemType.consumable:
        return Icons.fastfood_outlined;
      case ItemType.cosmetic:
        return Icons.checkroom_outlined;
      case ItemType.companion:
        return Icons.pets_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = slot.item;
    final isEquipped = _isItemEquipped(item, context);
    final rarityColor = _getRarityColor(item.rarity);
    final shouldGlow = _shouldGlow(item.rarity);

    return MinimalistCard(
      onTap: onTap,
      glowColor: rarityColor,
      showGlow: shouldGlow,
      borderColor: isEquipped
          ? AppColors.primaryTurquoise
          : rarityColor.withOpacity(shouldGlow ? 0.8 : 0.5),
      borderWidth: isEquipped ? 2.5 : (shouldGlow ? 2 : 1.5),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image ou icône
          if (item.imagePath != null)
            Image.asset(
              item.imagePath!,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  _getItemIcon(item.type),
                  size: 40,
                  color: rarityColor,
                );
              },
            )
          else
            Icon(
              _getItemIcon(item.type),
              size: 40,
              color: rarityColor,
            ),
          const SizedBox(height: 8),
          // Nom
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Quantité
          if (slot.quantity > 1) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryTurquoise.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryTurquoise.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'x${slot.quantity}',
                style: TextStyle(
                  color: AppColors.primaryTurquoise,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // Bouton équiper/utiliser
          if (showEquipButton && item.isEquippable) ...[
            const SizedBox(height: 8),
            MinimalistButton(
              label: isEquipped ? 'Équipé' : 'Équiper',
              onPressed: isEquipped ? onUnequip : onEquip,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              isOutlined: !isEquipped,
            ),
          ],
          if (showUseButton && item.isConsumable) ...[
            const SizedBox(height: 8),
            MinimalistButton(
              label: 'Utiliser',
              onPressed: onUse,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.accent,
            ),
          ],
        ],
      ),
    );
  }
}
