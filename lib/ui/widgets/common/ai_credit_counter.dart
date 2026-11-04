import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/ai_credits_labels.dart';
import '../../../presentation/view_models/ai_validation_credits_service.dart';
import '../pixel/pixel_ui.dart';

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
    return Selector<AiValidationCreditsService,
        ({int balance, bool isPremium})>(
      selector: (_, svc) => (balance: svc.balance, isPremium: svc.isPremium),
      builder: (context, data, _) {
        final isPremium = data.isPremium;
        final balance = data.balance;

        return Semantics(
          label: isPremium
              ? "$kAiCreditName illimitée"
              : "$balance ${balance > 1 ? kAiCreditLabelPlural : kAiCreditLabel} de l'Oracle",
          excludeSemantics: true,
          // Pastille pixel : bord carré turquoise Oracle, chiffre en police pixel.
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: PixelCouleurs.panneau,
              border: Border.all(color: PixelCouleurs.oracle, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: PixelCouleurs.oracle, size: 16),
                const SizedBox(width: 3),
                Text(isPremium ? '∞' : '$balance', style: PixelTextes.chiffres(9, PixelCouleurs.oracle)),
                if (isPremium) ...[
                  const SizedBox(width: 4),
                  Text('Premium', style: PixelTextes.corps(13, couleur: PixelCouleurs.oracle, poids: FontWeight.w700)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
