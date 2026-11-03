import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/ai_credits_labels.dart';
import '../../../presentation/view_models/ai_validation_credits_service.dart';
import '../../theme/app_colors.dart';

/// Affiche le sheet « plus de jetons » via [showModalBottomSheet].
///
/// À appeler quand l'énergie de l'Oracle est épuisée (solde = 0 et non
/// premium, ou refus serveur `energie_insuffisante`). Une quête à preuve ne
/// se valide que par l'Oracle (Sprint 1) : le sheet explique la recharge.
Future<void> showNoAiCreditsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundDarkPanel,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _NoAiCreditsSheetContent(),
  );
}

class _NoAiCreditsSheetContent extends StatelessWidget {
  const _NoAiCreditsSheetContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primaryTurquoise,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Plus de $kAiCreditLabelPlural',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Explication principale
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTurquoise.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryTurquoise.withValues(alpha: 0.25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'L\'Oracle se repose pour aujourd\'hui.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ton énergie est épuisée. Ta quête t\'attend : '
                  'tu pourras la faire valider par MougiBot dès la '
                  'prochaine recharge.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Comment regagner des jetons
          const Text(
            'Comment regagner des $kAiCreditLabelPlural ?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Recharge quotidienne (serveur : oracle.daily_energy)
          const _CreditSourceRow(
            icon: Icons.today_outlined,
            color: AppColors.mintMagic,
            title:
                'Recharge à ${AiValidationCreditsService.kDailyEnergyFloor} $kAiCreditLabelPlural chaque jour',
            subtitle: 'Ouvre l\'app chaque jour : ton énergie remonte '
                'automatiquement à ${AiValidationCreditsService.kDailyEnergyFloor}.',
          ),
          const SizedBox(height: 16),

          // CTA Premium — actif depuis la brique 8
          _PremiumCtaButton(
            key: const Key('cta_premium'),
            onPressed: () {
              final svc = context.read<AiValidationCreditsService>();
              // Garde défensive (couche UI) : ne relance pas le checkout si premium
              // est déjà actif (ex. webhook arrivé entre l'ouverture du sheet et le tap).
              // La protection principale est dans startPremiumCheckout() (couche service).
              if (svc.isPremium) {
                Navigator.of(context).pop();
                return;
              }
              // Ferme le sheet avant d'ouvrir le navigateur (UX propre).
              Navigator.of(context).pop();
              svc.startPremiumCheckout();
            },
          ),
          const SizedBox(height: 20),

          // Bouton « Plus tard »
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('continuer_en_manuel'),
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTurquoise,
                foregroundColor: AppColors.backgroundNightBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              child: const Text('Plus tard'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton CTA vers l'abonnement Premium.
///
/// Affiché dans le sheet « plus de jetons » pour rediriger vers le checkout Stripe.
class _PremiumCtaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PremiumCtaButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.diamond_outlined,
          color: AppColors.primaryVioletLight,
          size: 18,
        ),
        label: const Text('Passer à Premium — jetons illimités'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryVioletLight,
          side: const BorderSide(
            color: AppColors.primaryViolet,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Ligne de source de gain de jetons (icône + titre + sous-titre).
class _CreditSourceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _CreditSourceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
