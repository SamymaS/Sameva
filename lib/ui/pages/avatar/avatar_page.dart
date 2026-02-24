import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Page avatar : personnage avec slots d'équipement et stats.
class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Avatar',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer2<EquipmentProvider, PlayerProvider>(
        builder: (context, equipment, player, _) {
          final stats = player.stats;
          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Zone personnage + équipement
                SizedBox(
                  height: 340,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Personnage dessiné
                      const CustomPaint(
                        size: Size(100, 180),
                        painter: _CharacterPainter(),
                      ),
                      // Helmet (haut)
                      Positioned(
                        top: 20,
                        child: _EquipSlot(
                          slot: EquipmentSlot.helmet,
                          equipment: equipment,
                          label: 'Casque',
                        ),
                      ),
                      // Weapon (gauche)
                      Positioned(
                        left: 20,
                        top: 100,
                        child: _EquipSlot(
                          slot: EquipmentSlot.weapon,
                          equipment: equipment,
                          label: 'Arme',
                        ),
                      ),
                      // Armor (centre, en dessous du personnage)
                      Positioned(
                        bottom: 100,
                        child: _EquipSlot(
                          slot: EquipmentSlot.armor,
                          equipment: equipment,
                          label: 'Armure',
                        ),
                      ),
                      // Ring (droite)
                      Positioned(
                        right: 20,
                        top: 100,
                        child: _EquipSlot(
                          slot: EquipmentSlot.ring,
                          equipment: equipment,
                          label: 'Anneau',
                        ),
                      ),
                      // Boots (bas)
                      Positioned(
                        bottom: 20,
                        child: _EquipSlot(
                          slot: EquipmentSlot.boots,
                          equipment: equipment,
                          label: 'Bottes',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Panel stats
                _StatsPanel(stats: stats, equipment: equipment),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  const _CharacterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryTurquoise.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.primaryTurquoise
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cx = size.width / 2;

    // Tête
    canvas.drawCircle(Offset(cx, 20), 18, paint);
    canvas.drawCircle(Offset(cx, 20), 18, strokePaint);

    // Corps
    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 22, 44, 44, 60), const Radius.circular(6));
    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, strokePaint);

    // Bras gauche
    canvas.drawLine(Offset(cx - 22, 54), Offset(cx - 40, 90), strokePaint);
    // Bras droit
    canvas.drawLine(Offset(cx + 22, 54), Offset(cx + 40, 90), strokePaint);
    // Jambe gauche
    canvas.drawLine(Offset(cx - 10, 104), Offset(cx - 10, 140), strokePaint);
    // Jambe droite
    canvas.drawLine(Offset(cx + 10, 104), Offset(cx + 10, 140), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EquipSlot extends StatelessWidget {
  final EquipmentSlot slot;
  final EquipmentProvider equipment;
  final String label;

  const _EquipSlot({
    required this.slot,
    required this.equipment,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final item = equipment.getSlot(slot);
    final color = item != null
        ? AppColors.getRarityColor(item.rarity.name)
        : Colors.grey;

    return GestureDetector(
      onTap: item != null
          ? () => _showUnequipDialog(context, item, slot)
          : () => _showEquipHint(context),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: item != null ? 0.2 : 0.05),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: item != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.getIcon(), color: color, size: 22),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_slotIcon(slot), color: Colors.grey.withValues(alpha: 0.5), size: 18),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 8)),
                ],
              ),
      ),
    );
  }

  IconData _slotIcon(EquipmentSlot slot) {
    return switch (slot) {
      EquipmentSlot.weapon => Icons.auto_fix_high,
      EquipmentSlot.armor => Icons.shield_outlined,
      EquipmentSlot.helmet => Icons.face,
      EquipmentSlot.boots => Icons.directions_walk,
      EquipmentSlot.ring => Icons.circle_outlined,
    };
  }

  void _showUnequipDialog(BuildContext context, Item item, EquipmentSlot slot) {
    final inventory = context.read<InventoryProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: Text(item.name,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: const Text('Retirer cet équipement ?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
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

class _StatsPanel extends StatelessWidget {
  final PlayerStats stats;
  final EquipmentProvider equipment;

  const _StatsPanel({required this.stats, required this.equipment});

  @override
  Widget build(BuildContext context) {
    final hpBonus = equipment.hpBonus;
    final xpBonus = equipment.xpBonusPercent;
    final goldBonus = equipment.goldBonusPercent;
    final moralBonus = equipment.moralBonus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 12),
          _StatRow('Niveau', '${stats.level}', null, null),
          _StatRow('HP',
              '${stats.healthPoints} / ${stats.maxHealthPoints}',
              hpBonus > 0 ? '+$hpBonus' : null,
              AppColors.primaryTurquoise),
          _StatRow('XP bonus', '${xpBonus}%', null, null),
          _StatRow('Or bonus', '${goldBonus}%', null, null),
          _StatRow('Moral', '${(stats.moral * 100).round()}%',
              moralBonus > 0 ? '+$moralBonus' : null,
              AppColors.primaryTurquoise),
          _StatRow('Streak', '${stats.streak} jours', null, null),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String? bonus;
  final Color? bonusColor;

  const _StatRow(this.label, this.value, this.bonus, this.bonusColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                const SizedBox(width: 6),
                Text(bonus!,
                    style: TextStyle(
                        color: bonusColor ?? AppColors.primaryTurquoise,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
