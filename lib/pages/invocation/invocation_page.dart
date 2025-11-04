import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/animations/invocation_animation.dart';

/// INVOCATION — Lottie (démo)
class InvocationPage extends StatelessWidget {
  const InvocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              barrierColor: Colors.black87,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animation d'invocation
                      InvocationAnimation(
                        rarity: 'legendary',
                        onComplete: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invocation légendaire obtenue !'),
                              backgroundColor: Color(0xFFF59E0B),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Invoquer (Légendaire)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildRarityButton(context, 'common'),
              _buildRarityButton(context, 'rare'),
              _buildRarityButton(context, 'epic'),
              _buildRarityButton(context, 'legendary'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRarityButton(BuildContext context, String rarity) {
    return ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 400,
            height: 400,
            child: InvocationAnimation(
              rarity: rarity,
              onComplete: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getRarityColor(rarity),
      ),
      child: Text(rarity.toUpperCase()),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9CA3AF);
      case 'rare':
        return const Color(0xFF60A5FA);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'legendary':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }
}

