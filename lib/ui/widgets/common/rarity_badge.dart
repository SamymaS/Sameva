import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

/// Badge affichant la rareté d'un item ou d'un chat.
/// Paramètre [rarity] : 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary' | 'mythic'
class RarityBadge extends StatelessWidget {
  final String rarity;
  final bool compact;

  const RarityBadge({super.key, required this.rarity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRarityColor(rarity);
    final label = _label(rarity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: color,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static String _label(String rarity) => switch (rarity.toLowerCase()) {
        'common'    => 'Commun',
        'uncommon'  => 'Peu commun',
        'rare'      => 'Rare',
        'epic'      => 'Épique',
        'legendary' => 'Légendaire',
        'mythic'    => 'Mythique',
        _           => rarity,
      };
}
