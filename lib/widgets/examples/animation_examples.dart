import 'package:flutter/material.dart';
import '../animations/avatar_idle_animation.dart';
import '../animations/level_up_animation.dart';
import '../animations/invocation_animation.dart';
import '../animations/particles_halo.dart';
import '../animations/ui_animations.dart';
import '../logo/sameva_logo.dart';

/// Page d'exemples pour tester toutes les animations
class AnimationExamplesPage extends StatelessWidget {
  const AnimationExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemples d\'animations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Logo Sameva',
            const SamevaLogo(size: 150, animated: true),
          ),
          _buildSection(
            context,
            'Avatar Idle',
            const AvatarIdleAnimation(size: 200),
          ),
          _buildSection(
            context,
            'Halo de Particules',
            const ParticlesHalo(color: Color(0xFF1AA7EC), size: 200),
          ),
          _buildSection(
            context,
            'Level Up',
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: LevelUpAnimation(
                      onComplete: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
              child: const Text('Tester Level Up'),
            ),
          ),
          _buildSection(
            context,
            'Invocation',
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: InvocationAnimation(rarity: 'common'),
                      ),
                    ),
                  ),
                  child: const Text('Common'),
                ),
                ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: InvocationAnimation(rarity: 'legendary'),
                      ),
                    ),
                  ),
                  child: const Text('Legendary'),
                ),
              ],
            ),
          ),
          _buildSection(
            context,
            'Bouton Pulsant',
            PulseButton(
              onPressed: () {},
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Bouton Pulsant'),
              ),
            ),
          ),
          _buildSection(
            context,
            'Card Animée',
            AnimatedCard(
              glowColor: const Color(0xFF1AA7EC),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Card avec effet de glow'),
              ),
            ),
          ),
          _buildSection(
            context,
            'Shimmer Effect',
            ShimmerEffect(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2336),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Shimmer Loading'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Center(child: child),
        ],
      ),
    );
  }
}

