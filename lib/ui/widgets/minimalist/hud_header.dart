import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Header HUD - Barre d'état minimaliste
/// Style "Moderne Éthérée" - Éléments flottants
class HUDHeader extends StatelessWidget {
  final int level;
  final int experience;
  final int maxExperience;
  final int healthPoints;
  final int maxHealthPoints;
  final int gold;
  final int crystals;
  final VoidCallback? onSettingsTap;

  const HUDHeader({
    super.key,
    required this.level,
    required this.experience,
    required this.maxExperience,
    required this.healthPoints,
    required this.maxHealthPoints,
    required this.gold,
    required this.crystals,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final xpProgress = maxExperience > 0 ? (experience / maxExperience).clamp(0.0, 1.0) : 0.0;
    final hpProgress = maxHealthPoints > 0 ? (healthPoints / maxHealthPoints).clamp(0.0, 1.0) : 0.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gauche : Santé et XP
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Barre de Santé (PV)
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: Colors.red.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: hpProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.red.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$healthPoints/$maxHealthPoints',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Barre d'XP
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.primaryTurquoise.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTurquoise.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: xpProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryTurquoise,
                                    AppColors.primaryTurquoise.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Niveau $level',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Cinzel',
                      ),
                    ),
                  ],
                ),
                  ],
                ),
              ),

              // Droite : Ressources (alignées à droite)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Or
                  _ResourceChip(
                    icon: Icons.monetization_on,
                    value: gold.toString(),
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  // Cristaux
                  _ResourceChip(
                    icon: Icons.diamond_outlined,
                    value: crystals.toString(),
                    color: AppColors.primaryTurquoise,
                  ),
                  const SizedBox(width: 8),
                  // Paramètres
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: onSettingsTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Chip de ressource (Or/Cristaux)
class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _ResourceChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

