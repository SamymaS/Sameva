import 'package:flutter/material.dart';
import '../../widgets/animations/market_item_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// MARCHÉ — grille avec animations programmatiques
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final card = _MarketItemCard(
          name: item['name'] as String,
          rarity: item['rarity'] as String,
          price: item['price'] as String,
        );
        
        return AnimatedMarketItem(
          rarity: item['rarity'] as String,
          onTap: () {
            // TODO: Navigation vers détails de l'item
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item['name']} - ${item['price']} pièces')),
            );
          },
          child: card,
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (index * 50).ms);
      },
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  final String name;
  final String rarity;
  final String price;

  const _MarketItemCard({
    required this.name,
    required this.rarity,
    required this.price,
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
    final isRare = ['epic', 'legendary', 'mythic'].contains(rarity.toLowerCase());

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _rarityColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Particules pour les items rares
          if (isRare)
            Positioned.fill(
              child: RarityParticles(
                rarity: rarity,
                size: 200,
              ),
            ),
          // Contenu
          Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icône de l'item
                    Image.asset(
                      'assets/icons/app_icon.png',
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.inventory_2,
                        size: 64,
                        color: _rarityColor.withOpacity(0.7),
                      ),
                    ),
                    // Badge de rareté
                    Positioned(
                      top: 0,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _rarityColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rarity.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
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
              ),
              const SizedBox(height: 4),
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}

