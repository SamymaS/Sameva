import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/providers/player_provider.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final gold = playerProvider.stats?.gold ?? 0;

    final rewards = _sampleRewards;

    return Scaffold(
      appBar: AppBar(title: const Text('Récompenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Or disponible', style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.legendary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.legendary),
                      const SizedBox(width: 8),
                      Text('$gold'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final item = rewards[index];
                return _RewardCard(title: item['title']!, price: item['price']!, color: item['color']!);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String title;
  final int price;
  final Color color;

  const _RewardCard({required this.title, required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Récompense "$title" sélectionnée (non implémenté)')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Icon(Icons.auto_awesome, color: color, size: 48),
                  ),
                ),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.legendary, size: 18),
                    const SizedBox(width: 4),
                    Text('$price', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _sampleRewards = [
  {'title': 'Pause café', 'price': 50, 'color': AppColors.secondary},
  {'title': 'Episode série', 'price': 120, 'color': AppColors.primary},
  {'title': 'Sortie', 'price': 300, 'color': AppColors.accent},
  {'title': 'Nouveau skin', 'price': 500, 'color': AppColors.info},
];
