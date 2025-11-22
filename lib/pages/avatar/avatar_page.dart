import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_avatar.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/equipment_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/models/item.dart';
import '../../core/models/equipment.dart';

/// AVATAR — Personnalisation avec équipement réel
class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: const Text(
          'Personnalisation',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.of(context).pushNamed('/inventory'),
            tooltip: 'Inventaire',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar principal avec stats
            Consumer3<PlayerProvider, EquipmentProvider, InventoryProvider>(
              builder: (context, playerProvider, equipmentProvider, inventoryProvider, child) {
                final stats = playerProvider.stats;
                final equipment = equipmentProvider.playerEquipment;
                final items = Map<String, Item>.fromEntries(
                  inventoryProvider.items.map((slot) => MapEntry(slot.item.id, slot.item)),
                );
                final bonuses = equipment != null
                    ? equipment.calculateBonuses(items)
                    : {'attack': 0, 'defense': 0, 'health': 0};

                return FantasyCard(
                  title: 'Avatar actuel',
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Avatar avec équipement
                      Stack(
                        children: [
                          FantasyAvatar(
                            imageUrl: (equipment?.outfitId != null && items.containsKey(equipment!.outfitId))
                                ? items[equipment.outfitId]!.imagePath ?? 'assets/images/avatars/hero_base.png'
                                : 'assets/images/avatars/hero_base.png',
                            size: 120,
                            fallbackText: 'H',
                          ),
                          // Aura si équipée
                          if (equipment?.auraId != null && items.containsKey(equipment!.auraId))
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats du joueur
                      if (stats != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FantasyBadge(
                              label: 'Niveau ${stats.level}',
                              variant: BadgeVariant.secondary,
                            ),
                            const SizedBox(width: 8),
                            FantasyBadge(
                              label: '${stats.healthPoints}/${stats.maxHealthPoints} PV',
                              variant: BadgeVariant.default_,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Bonus d'équipement
                        if (bonuses['attack']! > 0 || bonuses['defense']! > 0 || bonuses['health']! > 0)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              if (bonuses['attack']! > 0)
                                FantasyBadge(
                                  label: '⚔️ +${bonuses['attack']}',
                                  variant: BadgeVariant.default_,
                                ),
                              if (bonuses['defense']! > 0)
                                FantasyBadge(
                                  label: '🛡️ +${bonuses['defense']}',
                                  variant: BadgeVariant.default_,
                                ),
                              if (bonuses['health']! > 0)
                                FantasyBadge(
                                  label: '❤️ +${bonuses['health']}',
                                  variant: BadgeVariant.default_,
                                ),
                            ],
                          ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Section Équipement
            Consumer2<EquipmentProvider, InventoryProvider>(
              builder: (context, equipmentProvider, inventoryProvider, child) {
                final equipment = equipmentProvider.playerEquipment;
                final items = Map<String, Item>.fromEntries(
                  inventoryProvider.items.map((slot) => MapEntry(slot.item.id, slot.item)),
                );

                return FantasyCard(
                  title: 'Équipement',
                  description: 'Gérez votre équipement actuel',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildEquipmentSlot(
                          context,
                          'Arme',
                          ItemType.weapon,
                          equipment?.weaponId,
                          items,
                          equipmentProvider,
                        ),
                        const SizedBox(height: 12),
                        _buildEquipmentSlot(
                          context,
                          'Armure',
                          ItemType.armor,
                          equipment?.armorId,
                          items,
                          equipmentProvider,
                        ),
                        const SizedBox(height: 12),
                        _buildEquipmentSlot(
                          context,
                          'Casque',
                          ItemType.helmet,
                          equipment?.helmetId,
                          items,
                          equipmentProvider,
                        ),
                        const SizedBox(height: 12),
                        _buildEquipmentSlot(
                          context,
                          'Bouclier',
                          ItemType.shield,
                          equipment?.shieldId,
                          items,
                          equipmentProvider,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Section Tenues (cosmétiques)
            Consumer2<EquipmentProvider, InventoryProvider>(
              builder: (context, equipmentProvider, inventoryProvider, child) {
                final cosmeticItems = inventoryProvider.getItemsByType(ItemType.cosmetic)
                    .where((slot) => slot.item.metadata?['subtype'] == 'outfit')
                    .toList();

                return FantasyCard(
                  title: 'Tenues',
                  description: 'Changez l\'apparence de votre avatar',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: cosmeticItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.checkroom_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune tenue disponible',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.of(context).pushNamed('/inventory'),
                                    icon: const Icon(Icons.inventory_2),
                                    label: const Text('Voir l\'inventaire'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: cosmeticItems.length,
                            itemBuilder: (context, index) {
                              final slot = cosmeticItems[index];
                              final isEquipped = equipmentProvider.playerEquipment?.outfitId == slot.item.id;
                              return _buildCosmeticItemCard(context, slot, isEquipped, equipmentProvider);
                            },
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Section Auras
            Consumer2<EquipmentProvider, InventoryProvider>(
              builder: (context, equipmentProvider, inventoryProvider, child) {
                final auraItems = inventoryProvider.getItemsByType(ItemType.cosmetic)
                    .where((slot) => slot.item.metadata?['subtype'] == 'aura')
                    .toList();

                return FantasyCard(
                  title: 'Auras',
                  description: 'Effets visuels pour votre avatar',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: auraItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune aura disponible',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: auraItems.length,
                            itemBuilder: (context, index) {
                              final slot = auraItems[index];
                              final isEquipped = equipmentProvider.playerEquipment?.auraId == slot.item.id;
                              return _buildCosmeticItemCard(context, slot, isEquipped, equipmentProvider);
                            },
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Section Compagnons
            Consumer<EquipmentProvider>(
              builder: (context, equipmentProvider, child) {
                final companion = equipmentProvider.companion;

                return FantasyCard(
                  title: 'Compagnon',
                  description: companion != null
                      ? '${companion.name} - Niveau ${companion.level}'
                      : 'Choisissez votre compagnon',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: companion != null
                        ? Column(
                            children: [
                              FantasyAvatar(
                                imageUrl: companion.imagePath ?? 'assets/images/companions/default.png',
                                size: 80,
                                fallbackText: companion.name[0],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                companion.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                companion.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FantasyBadge(
                                    label: '${companion.healthPoints}/${companion.maxHealthPoints} PV',
                                    variant: BadgeVariant.secondary,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.pets_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucun compagnon',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSlot(
    BuildContext context,
    String label,
    ItemType type,
    String? equippedId,
    Map<String, Item> items,
    EquipmentProvider equipmentProvider,
  ) {
    final item = equippedId != null && items.containsKey(equippedId) ? items[equippedId] : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _getItemIcon(type),
            size: 32,
            color: item != null ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item?.name ?? 'Aucun',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (item != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () async {
                await equipmentProvider.unequipItem('', type);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Équipement retiré'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              },
              tooltip: 'Déséquiper',
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/inventory'),
              child: const Text('Équiper'),
            ),
        ],
      ),
    );
  }

  Widget _buildCosmeticItemCard(
    BuildContext context,
    InventorySlot slot,
    bool isEquipped,
    EquipmentProvider equipmentProvider,
  ) {
    return GestureDetector(
      onTap: () async {
        if (isEquipped) {
          await equipmentProvider.unequipItem('', ItemType.cosmetic);
        } else {
          await equipmentProvider.equipItem('', slot.item);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEquipped ? '${slot.item.name} déséquipé' : '${slot.item.name} équipé'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEquipped ? AppColors.primary : AppColors.border,
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (slot.item.imagePath != null)
              Image.asset(
                slot.item.imagePath!,
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.checkroom,
                    size: 35,
                    color: AppColors.primary,
                  );
                },
              )
            else
              Icon(
                Icons.checkroom,
                size: 35,
                color: AppColors.primary,
              ),
            const SizedBox(height: 6),
            Text(
              slot.item.name,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isEquipped)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FantasyBadge(
                  label: 'Équipé',
                  variant: BadgeVariant.default_,
                ),
              ),
          ],
        ),
      ),
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
      default:
        return Icons.inventory_2;
    }
  }
}
