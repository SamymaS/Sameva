import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/providers/character_provider.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/character/character_painter.dart';

/// Page avatar : personnalisation du personnage + équipement combat + stats.
class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Personnage',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTurquoise,
          labelColor: AppColors.primaryTurquoise,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Apparence'),
            Tab(text: 'Combat'),
          ],
        ),
      ),
      body: Consumer3<CharacterProvider, EquipmentProvider, PlayerProvider>(
        builder: (context, character, equipment, player, _) {
          // Extraire les couleurs cosmétiques
          final hatItem = equipment.getCosmeticSlot('hat');
          final outfitItem = equipment.getCosmeticSlot('outfit');
          final pantsItem = equipment.getCosmeticSlot('pants');
          final shoesItem = equipment.getCosmeticSlot('shoes');
          final auraItem = equipment.getCosmeticSlot('aura');

          final hatStyle = hatItem?.stats['styleIndex'] ?? 0;
          final hatColor = hatItem != null
              ? Color(hatItem.stats['colorValue'] ?? 0xFF805AD5)
              : const Color(0xFF805AD5);
          final outfitColor = outfitItem != null
              ? Color(outfitItem.stats['colorValue'] ?? 0xFF4FD1C5)
              : const Color(0xFF4FD1C5);
          final pantsColor = pantsItem != null
              ? Color(pantsItem.stats['colorValue'] ?? 0xFF2D3748)
              : const Color(0xFF2D3748);
          final shoesColor = shoesItem != null
              ? Color(shoesItem.stats['colorValue'] ?? 0xFF3D2B1A)
              : const Color(0xFF3D2B1A);
          final auraColor = auraItem != null
              ? Color(auraItem.stats['colorValue'] ?? 0xFFF6E05E)
              : null;

          final painter = CharacterPainter(
            appearance: character.appearance,
            outfitColor: outfitColor,
            pantsColor: pantsColor,
            shoesColor: shoesColor,
            hatColor: hatColor,
            hatStyle: hatStyle,
            auraColor: auraColor,
          );

          return Column(
            children: [
              // Aperçu du personnage (fixe en haut)
              _CharacterPreview(painter: painter),

              // Onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet Apparence
                    _AppearanceTab(
                      character: character,
                      equipment: equipment,
                    ),
                    // Onglet Combat
                    _CombatTab(
                      equipment: equipment,
                      player: player,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Character Preview ──────────────────────────────────────────────────────

class _CharacterPreview extends StatelessWidget {
  final CharacterPainter painter;

  const _CharacterPreview({required this.painter});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDarkPanel,
            AppColors.backgroundDeepViolet.withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF2D3748),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(140, 220),
          painter: painter,
        ),
      ),
    );
  }
}

// ── Appearance Tab ─────────────────────────────────────────────────────────

class _AppearanceTab extends StatelessWidget {
  final CharacterProvider character;
  final EquipmentProvider equipment;

  const _AppearanceTab({required this.character, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section cosmétiques
          _SectionHeader(title: 'Cosmétiques', icon: Icons.auto_awesome),
          const SizedBox(height: 12),
          _CosmeticsRow(equipment: equipment),
          const SizedBox(height: 24),

          // Section personnalisation
          _SectionHeader(title: 'Personnalisation', icon: Icons.tune),
          const SizedBox(height: 16),

          // Genre
          _SubLabel(label: 'Genre'),
          const SizedBox(height: 8),
          _GenderSelector(character: character),
          const SizedBox(height: 16),

          // Teinte de peau
          _SubLabel(label: 'Teinte de peau'),
          const SizedBox(height: 8),
          _SkinTonePicker(character: character),
          const SizedBox(height: 16),

          // Style de cheveux
          _SubLabel(label: 'Style de cheveux'),
          const SizedBox(height: 8),
          _HairStylePicker(character: character),
          const SizedBox(height: 16),

          // Couleur des cheveux
          _SubLabel(label: 'Couleur des cheveux'),
          const SizedBox(height: 8),
          _HairColorPicker(character: character),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Cosmetics Row ──────────────────────────────────────────────────────────

class _CosmeticsRow extends StatelessWidget {
  final EquipmentProvider equipment;

  const _CosmeticsRow({required this.equipment});

  @override
  Widget build(BuildContext context) {
    const slots = [
      ('hat', 'Chapeau', Icons.auto_awesome),
      ('outfit', 'Tenue', Icons.dry_cleaning),
      ('pants', 'Pantalon', Icons.format_list_bulleted),
      ('shoes', 'Chaussures', Icons.hiking),
      ('aura', 'Aura', Icons.flare),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: slots
          .map((s) => _CosmeticSlotButton(
                slot: s.$1,
                label: s.$2,
                icon: s.$3,
                equipment: equipment,
              ))
          .toList(),
    );
  }
}

class _CosmeticSlotButton extends StatelessWidget {
  final String slot;
  final String label;
  final IconData icon;
  final EquipmentProvider equipment;

  const _CosmeticSlotButton({
    required this.slot,
    required this.label,
    required this.icon,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final item = equipment.getCosmeticSlot(slot);
    final color = item != null
        ? Color(item.stats['colorValue'] ?? 0xFF805AD5)
        : AppColors.textMuted;

    return GestureDetector(
      onTap: item != null
          ? () => _showCosmeticOptions(context, item)
          : () => _showEquipSheet(context),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: item != null ? 0.18 : 0.05),
              border: Border.all(
                  color: color.withValues(alpha: item != null ? 0.7 : 0.25),
                  width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item != null ? item.getIcon() : icon,
              color: color.withValues(alpha: item != null ? 1.0 : 0.45),
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item != null
                ? (item.name.length > 7
                    ? '${item.name.substring(0, 6)}…'
                    : item.name)
                : label,
            style: TextStyle(
              color: item != null ? color : AppColors.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCosmeticOptions(BuildContext context, Item item) {
    final inventory = context.read<InventoryProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: Text(item.name,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(item.description,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              equipment.unequipCosmetic(slot, inventory);
              Navigator.pop(context);
            },
            child: const Text('Retirer'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTurquoise),
            onPressed: () {
              Navigator.pop(context);
              _showEquipSheet(context);
            },
            child: const Text('Changer',
                style: TextStyle(color: AppColors.backgroundNightBlue)),
          ),
        ],
      ),
    );
  }

  void _showEquipSheet(BuildContext context) {
    final inventory = context.read<InventoryProvider>();
    final available = inventory.items
        .where((i) => i.type == ItemType.cosmetic && i.cosmeticSlot == slot)
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Aucun cosmétique "$label" dans votre inventaire.'),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDarkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CosmeticPickerSheet(
        slot: slot,
        label: label,
        items: available,
        equipment: equipment,
        inventory: inventory,
      ),
    );
  }
}

class _CosmeticPickerSheet extends StatelessWidget {
  final String slot;
  final String label;
  final List<Item> items;
  final EquipmentProvider equipment;
  final InventoryProvider inventory;

  const _CosmeticPickerSheet({
    required this.slot,
    required this.label,
    required this.items,
    required this.equipment,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir un $label',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final item = items[i];
                final color = Color(item.stats['colorValue'] ?? 0xFF805AD5);
                return GestureDetector(
                  onTap: () {
                    equipment.equipCosmetic(item, slot, inventory);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.getIcon(), color: color, size: 26),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            item.name,
                            style: TextStyle(
                                color: color,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Gender Selector ────────────────────────────────────────────────────────

class _GenderSelector extends StatelessWidget {
  final CharacterProvider character;

  const _GenderSelector({required this.character});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CharacterGender.values.map((gender) {
        final isSelected = character.appearance.gender == gender;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: gender == CharacterGender.male ? 8 : 0),
            child: GestureDetector(
              onTap: () => character.setGender(gender),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTurquoise.withValues(alpha: 0.2)
                      : AppColors.backgroundDarkPanel,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryTurquoise
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      gender == CharacterGender.male
                          ? Icons.male
                          : Icons.female,
                      color: isSelected
                          ? AppColors.primaryTurquoise
                          : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      gender.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryTurquoise
                            : AppColors.textMuted,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Skin Tone Picker ───────────────────────────────────────────────────────

class _SkinTonePicker extends StatelessWidget {
  final CharacterProvider character;

  const _SkinTonePicker({required this.character});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SkinTone.values.map((tone) {
        final isSelected = character.appearance.skinTone == tone;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => character.setSkinTone(tone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: tone.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Hair Style Picker ──────────────────────────────────────────────────────

class _HairStylePicker extends StatelessWidget {
  final CharacterProvider character;

  const _HairStylePicker({required this.character});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: HairStyle.values.map((style) {
        final isSelected = character.appearance.hairStyle == style;
        return GestureDetector(
          onTap: () => character.setHairStyle(style),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondaryViolet.withValues(alpha: 0.25)
                  : AppColors.backgroundDarkPanel,
              border: Border.all(
                color: isSelected
                    ? AppColors.secondaryViolet
                    : AppColors.textMuted.withValues(alpha: 0.25),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  style.icon,
                  color: isSelected
                      ? AppColors.secondaryViolet
                      : AppColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  style.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.secondaryViolet
                        : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Hair Color Picker ──────────────────────────────────────────────────────

class _HairColorPicker extends StatelessWidget {
  final CharacterProvider character;

  const _HairColorPicker({required this.character});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kHairColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final color = kHairColors[i];
          final isSelected =
              character.appearance.hairColor.value == color.value;
          return GestureDetector(
            onTap: () => character.setHairColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ── Combat Tab ─────────────────────────────────────────────────────────────

class _CombatTab extends StatelessWidget {
  final EquipmentProvider equipment;
  final PlayerProvider player;

  const _CombatTab({required this.equipment, required this.player});

  @override
  Widget build(BuildContext context) {
    final stats = player.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionHeader(title: 'Équipement', icon: Icons.shield),
          const SizedBox(height: 16),
          _EquipmentGrid(equipment: equipment),
          const SizedBox(height: 24),
          if (stats != null) ...[
            _SectionHeader(title: 'Statistiques', icon: Icons.bar_chart),
            const SizedBox(height: 12),
            _StatsPanel(stats: stats, equipment: equipment),
          ],
        ],
      ),
    );
  }
}

// ── Equipment Grid ─────────────────────────────────────────────────────────

class _EquipmentGrid extends StatelessWidget {
  final EquipmentProvider equipment;

  const _EquipmentGrid({required this.equipment});

  @override
  Widget build(BuildContext context) {
    const slots = [
      (EquipmentSlot.helmet, 'Casque'),
      (EquipmentSlot.armor, 'Armure'),
      (EquipmentSlot.weapon, 'Arme'),
      (EquipmentSlot.ring, 'Anneau'),
      (EquipmentSlot.boots, 'Bottes'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.15)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: slots
            .map((s) => _EquipSlot(
                  slot: s.$1,
                  label: s.$2,
                  equipment: equipment,
                ))
            .toList(),
      ),
    );
  }
}

class _EquipSlot extends StatelessWidget {
  final EquipmentSlot slot;
  final String label;
  final EquipmentProvider equipment;

  const _EquipSlot({
    required this.slot,
    required this.label,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final item = equipment.getSlot(slot);
    final color = item != null
        ? AppColors.getRarityColor(item.rarity.name)
        : Colors.grey;

    return GestureDetector(
      onTap: item != null
          ? () => _showUnequipDialog(context, item)
          : () => _showEquipHint(context),
      child: Container(
        width: 58,
        height: 68,
        decoration: BoxDecoration(
          color: color.withValues(alpha: item != null ? 0.18 : 0.05),
          border: Border.all(
              color: color.withValues(alpha: item != null ? 0.7 : 0.25),
              width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item != null ? item.getIcon() : _slotIcon(slot),
              color: color.withValues(alpha: item != null ? 1.0 : 0.45),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              item?.name.split(' ').first ?? label,
              style: TextStyle(
                color: item != null ? color : Colors.grey,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _slotIcon(EquipmentSlot slot) => switch (slot) {
        EquipmentSlot.weapon => Icons.auto_fix_high,
        EquipmentSlot.armor => Icons.shield_outlined,
        EquipmentSlot.helmet => Icons.face,
        EquipmentSlot.boots => Icons.directions_walk,
        EquipmentSlot.ring => Icons.circle_outlined,
      };

  void _showUnequipDialog(BuildContext context, Item item) {
    final inventory = context.read<InventoryProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: Text(item.name,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(item.description,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              equipment.unequip(slot, inventory);
              Navigator.pop(context);
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _showEquipHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Équipez un item depuis votre inventaire.'),
      duration: Duration(seconds: 2),
    ));
  }
}

// ── Stats Panel ────────────────────────────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  final PlayerStats stats;
  final EquipmentProvider equipment;

  const _StatsPanel({required this.stats, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDarkPanel,
            AppColors.backgroundDeepViolet.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _StatRow('Niveau', '${stats.level}', null),
          _StatRow(
            'HP',
            '${stats.healthPoints} / ${stats.maxHealthPoints}',
            equipment.hpBonus > 0 ? '+${equipment.hpBonus} HP' : null,
          ),
          _StatRow(
            'XP bonus',
            '+${equipment.xpBonusPercent}%',
            null,
          ),
          _StatRow(
            'Or bonus',
            '+${equipment.goldBonusPercent}%',
            null,
          ),
          _StatRow(
            'Moral',
            '${(stats.moral * 100).round()}%',
            equipment.moralBonus > 0
                ? '+${equipment.moralBonus}' : null,
          ),
          _StatRow('Streak', '${stats.streak} jours', null),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String? bonus;

  const _StatRow(this.label, this.value, this.bonus);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
              if (bonus != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurquoise.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bonus!,
                    style: const TextStyle(
                        color: AppColors.primaryTurquoise,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── UI Helpers ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTurquoise, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String label;

  const _SubLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
