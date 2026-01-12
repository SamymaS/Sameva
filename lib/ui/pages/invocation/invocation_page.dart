import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../widgets/animations/invocation_animation.dart';
import '../../widgets/minimalist/hud_header.dart';
import '../../widgets/magical/animated_background.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/services/item_factory.dart';

/// INVOCATION — Système d'invocation avec vraies récompenses
/// Selon pages.md : "Le Portail" avec animation de vortex magique
class InvocationPage extends StatefulWidget {
  const InvocationPage({super.key});

  @override
  State<InvocationPage> createState() => _InvocationPageState();
}

class _InvocationPageState extends State<InvocationPage> {
  bool _isInvoking = false;

  /// Calcule la rareté selon les probabilités
  ItemRarity _calculateRarity() {
    final random = math.Random().nextDouble();
    
    if (random < 0.01) return ItemRarity.mythic; // 1%
    if (random < 0.05) return ItemRarity.legendary; // 4%
    if (random < 0.15) return ItemRarity.epic; // 10%
    if (random < 0.35) return ItemRarity.veryRare; // 20%
    if (random < 0.65) return ItemRarity.rare; // 30%
    if (random < 0.85) return ItemRarity.uncommon; // 20%
    return ItemRarity.common; // 15%
  }

  /// Crée un item selon la rareté
  Item _createInvocationItem(ItemRarity rarity) {
    final allItems = ItemFactory.createDefaultItems();
    final itemsOfRarity = allItems.where((item) => item.rarity == rarity).toList();
    
    if (itemsOfRarity.isEmpty) {
      // Fallback : créer un item basique
      return ItemFactory.createWeapon(
        name: 'Item $rarity',
        rarity: rarity,
        attackBonus: rarity.index * 5,
        value: rarity.index * 100,
      );
    }
    
    return itemsOfRarity[math.Random().nextInt(itemsOfRarity.length)];
  }

  Future<void> _invoke(BuildContext context, InvocationType type) async {
    if (_isInvoking) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final stats = playerProvider.stats;

    if (stats == null) return;

    // Vérifier les coûts
    switch (type) {
      case InvocationType.free:
        // Gratuit, mais limité (ex: 1 par jour)
        break;
      case InvocationType.gold:
        if (stats.gold < 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Or insuffisant (100 or requis)'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        break;
      case InvocationType.premium:
        if (stats.crystals < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cristaux insuffisants (10 cristaux requis)'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        break;
    }

    setState(() => _isInvoking = true);

    // Calculer la rareté
    final rarity = _calculateRarity();
    final rarityString = rarity.toString().split('.').last;

    // Afficher l'animation
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 400,
          height: 400,
          child: InvocationAnimation(
            rarity: rarityString,
            onComplete: () async {
              Navigator.of(context).pop();
              
              // Déduire les coûts
              switch (type) {
                case InvocationType.free:
                  break;
                case InvocationType.gold:
                  await playerProvider.addGold('', -100);
                  break;
                case InvocationType.premium:
                  await playerProvider.spendCrystals('', 10);
                  break;
              }

              // Créer et ajouter l'item
              final item = _createInvocationItem(rarity);
              final success = await inventoryProvider.addItem('', item);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${item.name} obtenu ! (${rarityString.toUpperCase()})'
                          : 'Inventaire plein !',
                    ),
                    backgroundColor: success ? _getRarityColor(rarityString) : AppColors.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              setState(() => _isInvoking = false);
            },
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return AppColors.common;
      case 'uncommon':
        return AppColors.uncommon;
      case 'rare':
        return AppColors.rare;
      case 'veryrare':
        return AppColors.veryRare;
      case 'epic':
        return AppColors.epic;
      case 'legendary':
        return AppColors.legendary;
      case 'mythic':
        return AppColors.mythic;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMagicalBackground(
        child: Stack(
          children: [
            // Header HUD
            Consumer<PlayerProvider>(
              builder: (context, playerProvider, _) {
                final stats = playerProvider.stats;
                return HUDHeader(
                  level: stats?.level ?? 1,
                  experience: stats?.experience ?? 0,
                  maxExperience: playerProvider.experienceForLevel(stats?.level ?? 1),
                  healthPoints: stats?.healthPoints ?? 100,
                  maxHealthPoints: stats?.maxHealthPoints ?? 100,
                  gold: stats?.gold ?? 0,
                  crystals: stats?.crystals ?? 0,
                  onSettingsTap: () {
                    // Navigation vers settings
                  },
                );
              },
            ),
            // Contenu
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 100), // Padding en haut pour le header, en bas pour le dock
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Titre de page
                    Center(
                      child: Text(
                        'Le Portail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invoquez des items puissants !',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez votre type d\'invocation',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Types d'invocation
                    Consumer<PlayerProvider>(
                      builder: (context, playerProvider, _) {
                        final stats = playerProvider.stats;
                        return Column(
                          children: [
                            _buildInvocationCard(
                              context,
                              'Invocation Gratuite',
                              '1 invocation gratuite par jour',
                              Icons.card_giftcard,
                              AppColors.success,
                              () => _invoke(context, InvocationType.free),
                              _isInvoking,
                            ),
                            const SizedBox(height: 16),
                            _buildInvocationCard(
                              context,
                              'Invocation Standard',
                              '100 pièces d\'or',
                              Icons.monetization_on,
                              const Color(0xFFF59E0B),
                              () => _invoke(context, InvocationType.gold),
                              _isInvoking || (stats?.gold ?? 0) < 100,
                            ),
                            const SizedBox(height: 16),
                            _buildInvocationCard(
                              context,
                              'Invocation Premium',
                              '10 cristaux (meilleures chances)',
                              Icons.diamond,
                              Colors.cyan,
                              () => _invoke(context, InvocationType.premium),
                              _isInvoking || (stats?.crystals ?? 0) < 10,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Probabilités
                    _buildProbabilitiesCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvocationCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDisabled,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisabled ? AppColors.border : color,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDisabled ? AppColors.textMuted : color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilitiesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Probabilités',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildProbabilityRow('Mythique', '1%', AppColors.mythic),
          _buildProbabilityRow('Légendaire', '4%', AppColors.legendary),
          _buildProbabilityRow('Épique', '10%', AppColors.epic),
          _buildProbabilityRow('Très Rare', '20%', AppColors.veryRare),
          _buildProbabilityRow('Rare', '30%', AppColors.rare),
          _buildProbabilityRow('Peu Commun', '20%', AppColors.uncommon),
          _buildProbabilityRow('Commun', '15%', AppColors.common),
        ],
      ),
    );
  }

  Widget _buildProbabilityRow(String label, String probability, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            probability,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

enum InvocationType {
  free,
  gold,
  premium,
}
