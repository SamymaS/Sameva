import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/ai_credits_labels.dart';
import '../../../presentation/view_models/ai_validation_credits_service.dart';
import '../../theme/app_colors.dart';

/// Compteur de jetons MougiBot, compact et réactif.
///
/// Utilise [Selector] pour ne reconstruire que quand le solde ou le statut
/// premium change. Affiche « ∞ » si l'utilisateur est premium, sinon le
/// solde numérique.
///
/// Usage :
/// ```dart
/// const AiCreditCounter()
/// ```
class AiCreditCounter extends StatelessWidget {
  const AiCreditCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AiValidationCreditsService, ({int balance, bool isPremium})>(
      selector: (_, svc) => (balance: svc.balance, isPremium: svc.isPremium),
      builder: (context, data, _) {
        final isPremium = data.isPremium;
        final balance = data.balance;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryTurquoise.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primaryTurquoise,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                isPremium ? '∞' : '$balance',
                style: const TextStyle(
                  color: AppColors.primaryTurquoise,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isPremium ? 'Premium' : kAiCreditLabel,
                style: const TextStyle(
                  color: AppColors.primaryTurquoise,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
