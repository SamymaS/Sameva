import 'package:flutter/material.dart';

/// MARCHÉ — grille simple (placeholder)
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

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
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Image.asset(
                'assets/icons/app_icon.png',
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.inventory_2,
                  size: 64,
                  color: Colors.white38,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Épique – Heaume du Zénith',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

