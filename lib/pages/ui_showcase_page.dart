import 'package:flutter/material.dart';
import '../widgets/ui/fantasy_button.dart';
import '../widgets/ui/fantasy_banner.dart';
import '../widgets/ui/fantasy_title.dart';
import '../widgets/figma/fantasy_card.dart';
import '../theme/app_colors.dart';

/// Page de démonstration de l'interface UI avec boutons, titres et bannières
class UIShowcasePage extends StatelessWidget {
  const UIShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('UI Showcase'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre principal avec icône asset
            FantasyTitle(
              text: 'Interface UI',
              assetIcon: 'assets/icons/app_icon.png',
              iconSize: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Démonstration des composants UI avec assets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Section Boutons
            const SectionTitle(
              text: 'Boutons',
              subtitle: 'Différents styles de boutons avec assets',
            ),
            const SizedBox(height: 16),

            // Bouton principal avec icône asset
            FantasyButton(
              label: 'Bouton avec Épée',
              assetIcon: 'assets/icons/items/woodSword.png',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bouton avec épée cliqué !')),
                );
              },
            ),
            const SizedBox(height: 12),

            // Bouton avec icône Material
            FantasyButton(
              label: 'Bouton avec Icône',
              icon: Icons.star,
              backgroundColor: AppColors.success,
              onPressed: () {},
            ),
            const SizedBox(height: 12),

            // Bouton outlined
            FantasyButton(
              label: 'Bouton Outlined',
              icon: Icons.favorite,
              backgroundColor: AppColors.error,
              isOutlined: true,
              onPressed: () {},
            ),
            const SizedBox(height: 12),

            // Bouton avec asset (bouclier)
            FantasyButton(
              label: 'Défendre',
              assetIcon: 'assets/icons/items/shield.png',
              backgroundColor: AppColors.info,
              width: double.infinity,
              onPressed: () {},
            ),
            const SizedBox(height: 12),

            // Bouton avec potion
            FantasyButton(
              label: 'Utiliser Potion',
              assetIcon: 'assets/icons/items/potionRed.png',
              backgroundColor: AppColors.error,
              width: double.infinity,
              onPressed: () {},
            ),
            const SizedBox(height: 32),

            // Section Bannières
            const SectionTitle(
              text: 'Bannières',
              subtitle: 'Bannières d\'information avec assets',
            ),
            const SizedBox(height: 16),

            // Bannière avec asset
            FantasyBanner(
              title: 'Nouvelle quête disponible !',
              subtitle: 'Complétez cette quête pour gagner 100 XP',
              assetIcon: 'assets/icons/items/scroll.png',
              action: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 12),

            // Bannière de succès
            const SuccessBanner(
              message: 'Quête complétée avec succès !',
            ),
            const SizedBox(height: 12),

            // Bannière d'avertissement
            const WarningBanner(
              message: 'Attention : Votre énergie est faible',
            ),
            const SizedBox(height: 12),

            // Bannière d'information
            const InfoBanner(
              message: 'Astuce : Complétez les quêtes quotidiennes',
            ),
            const SizedBox(height: 12),

            // Bannière avec carte
            FantasyBanner(
              title: 'Nouvelle zone découverte',
              subtitle: 'Explorez cette nouvelle zone pour des récompenses',
              assetIcon: 'assets/icons/items/map.png',
              backgroundColor: AppColors.epic.withOpacity(0.1),
              borderColor: AppColors.epic,
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // Section Items avec assets
            const SectionTitle(
              text: 'Items avec Assets',
              subtitle: 'Affichage des items du jeu',
            ),
            const SizedBox(height: 16),

            // Grille d'items
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final items = [
                  {'icon': 'assets/icons/items/woodSword.png', 'name': 'Épée', 'color': AppColors.rare},
                  {'icon': 'assets/icons/items/shield.png', 'name': 'Bouclier', 'color': AppColors.common},
                  {'icon': 'assets/icons/items/helmet.png', 'name': 'Casque', 'color': AppColors.uncommon},
                  {'icon': 'assets/icons/items/armor.png', 'name': 'Armure', 'color': AppColors.rare},
                  {'icon': 'assets/icons/items/potionRed.png', 'name': 'Potion', 'color': AppColors.success},
                  {'icon': 'assets/icons/items/gemBlue.png', 'name': 'Gemme', 'color': AppColors.epic},
                  {'icon': 'assets/icons/items/bow.png', 'name': 'Arc', 'color': AppColors.legendary},
                  {'icon': 'assets/icons/items/wand.png', 'name': 'Baguette', 'color': AppColors.mythic},
                  {'icon': 'assets/icons/items/coin.png', 'name': 'Pièce', 'color': AppColors.warning},
                ];

                final item = items[index % items.length];
                final color = item['color'] as Color;

                return FantasyCard(
                  backgroundColor: AppColors.card,
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        item['icon'] as String,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.inventory_2,
                          size: 40,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Section Actions rapides
            const SectionTitle(
              text: 'Actions Rapides',
              subtitle: 'Boutons d\'action avec assets',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FantasyButton(
                    label: 'Attaquer',
                    assetIcon: 'assets/icons/items/axe.png',
                    backgroundColor: AppColors.error,
                    height: 60,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FantasyButton(
                    label: 'Défendre',
                    assetIcon: 'assets/icons/items/shield.png',
                    backgroundColor: AppColors.info,
                    height: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FantasyButton(
                    label: 'Soigner',
                    assetIcon: 'assets/icons/items/potionGreen.png',
                    backgroundColor: AppColors.success,
                    height: 60,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FantasyButton(
                    label: 'Magie',
                    assetIcon: 'assets/icons/items/wand.png',
                    backgroundColor: AppColors.epic,
                    height: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

