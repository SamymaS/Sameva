import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'interactive_dock_item.dart';

/// Dock Flottant - Navigation moderne éthérée
/// Style "Moderne Éthérée" avec glassmorphism
class FloatingDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final Widget? centerFab;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.centerFab,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        // Dock principal
        Positioned(
          bottom: bottomPadding + 10, // Safe area + marge
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.backgroundNightBlue.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  // Dégradé subtil pour reflet de lumière
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryTurquoise.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                  // Ombre diffuse cyan pour lévitation
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTurquoise.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Accueil (Sanctuaire)
                    InteractiveDockItem(
                      icon: Icons.home_outlined,
                      isActive: currentIndex == 0,
                      onTap: () => onItemSelected(0),
                    ),
                    // Grimoire (Quêtes)
                    InteractiveDockItem(
                      icon: Icons.menu_book_outlined,
                      isActive: currentIndex == 1,
                      onTap: () => onItemSelected(1),
                    ),
                    // Inventaire (Sac)
                    InteractiveDockItem(
                      icon: Icons.inventory_2_outlined,
                      isActive: currentIndex == 2,
                      onTap: () => onItemSelected(2),
                    ),
                    // Espace pour le FAB central
                    const SizedBox(width: 56),
                    // Invocation (Gacha)
                    InteractiveDockItem(
                      icon: Icons.auto_awesome,
                      isActive: currentIndex == 5,
                      onTap: () => onItemSelected(5),
                    ),
                    // Marché
                    InteractiveDockItem(
                      icon: Icons.store_outlined,
                      isActive: currentIndex == 4,
                      onTap: () => onItemSelected(4),
                    ),
                    // Profil
                    InteractiveDockItem(
                      icon: Icons.person_outline,
                      isActive: currentIndex == 7,
                      onTap: () => onItemSelected(7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // FAB Central flottant (au-dessus du dock, pas de chevauchement)
        if (centerFab != null)
          Positioned(
            bottom: bottomPadding + 10 + 70 + 8, // 8px au-dessus du dock (70px de haut + 10px de marge)
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: centerFab!,
          ),
      ],
    );
  }
}


