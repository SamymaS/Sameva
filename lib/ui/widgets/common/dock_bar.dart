import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Barre de navigation flottante — 8 onglets principaux.
/// [badges] : map index → count pour afficher un badge rouge sur un onglet.
class DockBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  static const _items = [
    (icon: Icons.cottage_outlined,        label: 'Accueil'),
    (icon: Icons.assignment_outlined,     label: 'Quêtes'),
    (icon: Icons.inventory_2_outlined,    label: 'Stock'),
    (icon: Icons.pets_outlined,           label: 'Chat'),
    (icon: Icons.store_outlined,          label: 'Marché'),
    (icon: Icons.auto_awesome,            label: 'Portail'),
    (icon: Icons.extension_outlined,      label: 'Jeux'),
    (icon: Icons.account_circle_outlined, label: 'Profil'),
  ];

  const DockBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    // viewPadding.bottom = hauteur barre de navigation Android (stable, indépendant du clavier)
    final navBarHeight = MediaQuery.viewPaddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68 + navBarHeight,
          color: AppColors.backgroundDarkPanel.withValues(alpha: 0.92),
          child: Padding(
            padding: EdgeInsets.only(bottom: navBarHeight),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                return Expanded(
                  child: _DockItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: i == currentIndex,
                    badgeCount: badges[i] ?? 0,
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
  final int badgeCount;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryVioletLight.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? AppColors.primaryVioletLight
                        : AppColors.textMuted,
                    size: 20,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.coralRare,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive
                    ? AppColors.primaryVioletLight
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
