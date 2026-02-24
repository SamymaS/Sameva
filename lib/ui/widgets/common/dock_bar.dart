import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Barre de navigation flottante avec effet glassmorphism pour les 8 pages.
class DockBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.cottage_outlined,
    Icons.assignment_outlined,
    Icons.inventory_2_outlined,
    Icons.person_outline,
    Icons.store_outlined,
    Icons.auto_fix_high,
    Icons.extension_outlined,
    Icons.account_circle_outlined,
  ];

  const DockBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          color: AppColors.backgroundDarkPanel.withValues(alpha: 0.85),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (i) => _DockItem(
              icon: _icons[i],
              isActive: i == currentIndex,
              onTap: () => onTap(i),
            )),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.primaryTurquoise
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 6 : 0,
              height: isActive ? 6 : 0,
              decoration: BoxDecoration(
                color: AppColors.primaryTurquoise,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
