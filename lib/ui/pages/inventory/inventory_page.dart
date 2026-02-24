import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Page inventaire : grille 50 slots avec gestion équipement.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

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
          Consumer<InventoryProvider>(
            builder: (_, inv, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${inv.items.length}/50',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<InventoryProvider, EquipmentProvider>(
        builder: (context, inventory, equipment, _) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 50,
            itemBuilder: (context, index) {
              final item = index < inventory.items.length
                  ? inventory.items[index]
                  : null;
              return _InventorySlot(
                item: item,
                equipment: equipment,
                onTap: item != null
                    ? () => _showItemSheet(context, item, inventory, equipment)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showItemSheet(BuildContext context, Item item,
      InventoryProvider inventory, EquipmentProvider equipment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDarkPanel,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ItemBottomSheet(
        item: item,
        inventory: inventory,
        equipment: equipment,
      ),
    );
  }
}

class _InventorySlot extends StatelessWidget {
  final Item? item;
  final EquipmentProvider equipment;
  final VoidCallback? onTap;

  const _InventorySlot(
      {required this.item, required this.equipment, this.onTap});

  bool get _isEquipped {
    if (item == null) return false;
    return equipment.equipped.values.any((e) => e?.id == item!.id);
  }

  Color _rarityColor(QuestRarity rarity) =>
      AppColors.getRarityColor(rarity.name);

  @override
  Widget build(BuildContext context) {
    final color = item != null
        ? _rarityColor(item!.rarity)
        : AppColors.backgroundDarkPanel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: item != null ? 0.2 : 0.05),
          border: Border.all(
            color: item != null ? color : AppColors.inputBorder,
            width: item != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: item == null
            ? null
            : Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item!.getIcon(), color: color, size: 22),
                        if (item!.stackable && item!.quantity > 1)
                          Text(
                            '${item!.quantity}',
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  if (_isEquipped)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(Icons.check_circle,
                          size: 10,
                          color: AppColors.primaryTurquoise),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ItemBottomSheet extends StatelessWidget {
  final Item item;
  final InventoryProvider inventory;
  final EquipmentProvider equipment;

  const _ItemBottomSheet({
    required this.item,
    required this.inventory,
    required this.equipment,
  });

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  bool get _isEquipped =>
      equipment.equipped.values.any((e) => e?.id == item.id);

  @override
  Widget build(BuildContext context) {
    final slot = Item.slotForItem(item);
    final cosSlot = Item.cosmeticSlotForItem(item);
    final player = context.read<PlayerProvider>();
    final userId = context.read<AuthProvider>().userId ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.getIcon(), color: _rarityColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                          color: _rarityColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.rarity.name.toUpperCase(),
                      style: TextStyle(
                          color: _rarityColor.withValues(alpha: 0.7),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description,
              style: const TextStyle(color: AppColors.textSecondary)),
          if (item.stats.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: item.stats.entries
                  .map((e) => Chip(
                        label: Text(
                          '${_statLabel(e.key)} +${e.value}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 11),
                        ),
                        backgroundColor:
                            AppColors.primaryTurquoise.withValues(alpha: 0.2),
                        side: const BorderSide(color: AppColors.primaryTurquoise),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (slot != null && !_isEquipped)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTurquoise),
                    onPressed: () {
                      equipment.equip(item, slot, inventory);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text('Équiper'),
                  ),
                )
              else if (_isEquipped)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final s = equipment.equipped.entries
                          .firstWhere((e) => e.value?.id == item.id)
                          .key;
                      equipment.unequip(s, inventory);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Déséquiper'),
                  ),
                ),
              if (item.type == ItemType.cosmetic && cosSlot != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: equipment.getCosmeticSlot(cosSlot)?.id == item.id
                      ? OutlinedButton.icon(
                          onPressed: () {
                            equipment.unequipCosmetic(cosSlot, inventory);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 16),
                          label: const Text('Retirer'),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondaryViolet),
                          onPressed: () {
                            equipment.equipCosmetic(item, cosSlot, inventory);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.face_retouching_natural,
                              size: 16),
                          label: const Text('Porter'),
                        ),
                ),
              ],
              if (item.type == ItemType.potion) ...[
                if (slot != null) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success),
                    onPressed: () {
                      if (player.stats != null) {
                        player.heal(userId, item.stats['hpBonus'] ?? 20);
                      }
                      inventory.removeItem(item.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.local_pharmacy, size: 16),
                    label: const Text('Utiliser'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final sellPrice = (item.goldValue * 0.5).round();
                    inventory.removeItem(item.id);
                    if (player.stats != null) {
                      player.addGold(userId, sellPrice);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Vendu pour $sellPrice or'),
                    ));
                  },
                  icon: const Icon(Icons.sell_outlined, size: 16),
                  label: const Text('Vendre'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statLabel(String key) {
    return switch (key) {
      'xpBonus' => 'XP',
      'goldBonus' => 'Or',
      'hpBonus' => 'HP',
      'moralBonus' => 'Moral',
      _ => key,
    };
  }
}
