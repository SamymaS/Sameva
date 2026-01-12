import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Header global affichant l'Or, les Cristaux et le bouton Paramètres
/// Selon pages.md : "Header (Haut) : Affiche toujours l'Argent (Or), les Cristaux (Gemmes) et le bouton Paramètres"
class GlobalHeader extends StatelessWidget {
  final VoidCallback? onSettingsPressed;

  const GlobalHeader({
    super.key,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final stats = playerProvider.stats;
        final gold = stats?.gold ?? 0;
        final crystals = stats?.crystals ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundNightBlue,
                AppColors.backgroundNightBlue.withOpacity(0.95),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.secondaryViolet.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Or
                _buildCurrencyItem(
                  icon: Icons.monetization_on,
                  value: gold,
                  color: AppColors.gold,
                  label: 'Or',
                ),
                const SizedBox(width: 12),
                // Cristaux
                _buildCurrencyItem(
                  icon: Icons.diamond,
                  value: crystals,
                  color: AppColors.primaryTurquoise,
                  label: 'Cristaux',
                ),
                const Spacer(),
                // Bouton Paramètres
                IconButton(
                  onPressed: onSettingsPressed ??
                      () {
                        Navigator.of(context).pushNamed('/settings');
                      },
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.textPrimary,
                  tooltip: 'Paramètres',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyItem({
    required IconData icon,
    required int value,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            _formatValue(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
