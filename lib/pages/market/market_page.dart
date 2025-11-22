import 'package:flutter/material.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../../widgets/figma/fantasy_badge.dart';
import '../../theme/app_colors.dart';

/// MARCHÉ — Page du marché
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  // Données d'exemple pour les items
  static const List<Map<String, dynamic>> _items = [
    {'name': 'Heaume du Zénith', 'rarity': 'epic', 'price': '500'},
    {'name': 'Épée Légendaire', 'rarity': 'legendary', 'price': '1000'},
    {'name': 'Bouclier Commun', 'rarity': 'common', 'price': '50'},
    {'name': 'Armure Rare', 'rarity': 'rare', 'price': '200'},
    {'name': 'Amulette Mythique', 'rarity': 'mythic', 'price': '2000'},
    {'name': 'Potion Inhabituelle', 'rarity': 'uncommon', 'price': '100'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec titre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Marché',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  FantasyBadge(
                    label: '${_items.length} items',
                    variant: BadgeVariant.secondary,
                  ),
                ],
              ),
            ),
            // Grille d'items
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // Ajusté pour mieux afficher les items
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _MarketItemCard(
                    name: item['name'] as String,
                    rarity: item['rarity'] as String,
                    price: item['price'] as String,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item['name']} - ${item['price']} pièces'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  final String name;
  final String rarity;
  final String price;
  final VoidCallback onTap;

  const _MarketItemCard({
    required this.name,
    required this.rarity,
    required this.price,
    required this.onTap,
  });

  Color get _rarityColor {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF9CA3AF);
      case 'uncommon':
        return const Color(0xFF22C55E);
      case 'rare':
        return const Color(0xFF60A5FA);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'legendary':
        return const Color(0xFFF59E0B);
      case 'mythic':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FantasyCard(
      backgroundColor: AppColors.card,
      border: Border.all(
        color: _rarityColor.withOpacity(0.5),
        width: 2,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zone image avec badge
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image de l'item
                    Image.asset(
                      'assets/images/items/${name.toLowerCase().replaceAll(' ', '_')}.png',
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.inventory_2,
                        size: 48,
                        color: _rarityColor.withOpacity(0.7),
                      ),
                    ),
                    // Badge de rareté
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FantasyBadge(
                        label: rarity.toUpperCase(),
                        variant: BadgeVariant.default_,
                        backgroundColor: _rarityColor,
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Nom
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: _rarityColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Prix
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
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
