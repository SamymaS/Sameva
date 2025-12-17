import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import 'asset_image_widget.dart';

/// Header Bar avec avatar, nom et stats - Inspiré du design Figma
class HeaderBar extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const HeaderBar({
    super.key,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final authProvider = context.watch<AuthProvider>();
    final stats = playerProvider.stats;
    
    final username = authProvider.user?.userMetadata?['display_name'] as String? ?? 
                     authProvider.user?.userMetadata?['name'] as String? ?? 
                     (authProvider.user?.email?.split('@').first ?? 'Voyageur');

    final level = stats?.level ?? 1;
    final xp = stats?.experience ?? 0;
    final maxXp = _getMaxXpForLevel(level);
    final gold = stats?.gold ?? 0;
    final crystals = stats?.crystals ?? 0;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Avatar avec cadre doré
          GestureDetector(
            onTap: onProfileTap ?? () => Navigator.of(context).pushNamed('/profile'),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gold,
                    AppColors.goldDark,
                    AppColors.gold,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondaryViolet,
                      AppColors.primaryTurquoise,
                    ],
                  ),
                ),
                child: Center(
                  child: AvatarImageWidget(
                    avatarId: 'hero_base',
                    size: 32,
                    showBorder: false,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Nom et XP Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // XP Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxXp > 0 ? (xp / maxXp).clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryTurquoise,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Niveau $level • $xp / $maxXp XP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Ressources
          Row(
            children: [
              _ResourceChip(
                icon: '🪙',
                value: gold.toString(),
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              _ResourceChip(
                icon: '💎',
                value: crystals.toString(),
                color: AppColors.primaryTurquoise,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getMaxXpForLevel(int level) {
    // Formule simple : 100 * level^1.5
    return (100 * (level * level * 0.5)).round();
  }
}

class _ResourceChip extends StatelessWidget {
  final String icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

