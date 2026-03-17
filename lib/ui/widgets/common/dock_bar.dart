import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Barre de navigation flottante — 5 onglets principaux.
class DockBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.cottage_outlined,        label: 'Sanctuaire'),
    (icon: Icons.assignment_outlined,     label: 'Quêtes'),
    (icon: Icons.inventory_2_outlined,    label: 'Inventaire'),
    (icon: Icons.pets_outlined,           label: 'Chat'),
    (icon: Icons.store_outlined,          label: 'Marché'),
    (icon: Icons.account_circle_outlined, label: 'Profil'),
  ];

  const DockBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68 + bottomInset,
          color: AppColors.backgroundDarkPanel.withValues(alpha: 0.90),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                return Expanded(
                  child: _DockItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? AppColors.primaryTurquoise
                    : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppColors.primaryTurquoise
                    : AppColors.textMuted,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
