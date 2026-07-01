import 'package:flutter/material.dart';

import '../../../presentation/view_models/profile_view_model.dart';
import '../../theme/app_colors.dart';

/// Dialog de confirmation irréversible à double palier pour la suppression
/// de compte (RGPD).
///
/// Le bouton de suppression reste inactif tant que l'utilisateur n'a pas
/// coché la case de confirmation. Pendant l'appel réseau, le bouton est
/// désactivé pour empêcher tout double-appel. En cas d'échec partiel, un
/// message d'erreur est affiché sans déconnecter l'utilisateur.
///
/// Ce widget est public pour être testable de façon isolée.
/// L'entrée dans l'UI passe par [_DeleteAccountButton] (profile_page.dart).
class DeleteAccountConfirmDialog extends StatefulWidget {
  final ProfileViewModel vm;

  const DeleteAccountConfirmDialog({super.key, required this.vm});

  @override
  State<DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<DeleteAccountConfirmDialog> {
  bool _confirmed = false;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundDarkPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Supprimer mon compte',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avertissement destructif
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'Cette action est DÉFINITIVE et IRRÉVERSIBLE.',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Les données suivantes seront supprimées définitivement, '
                'sans possibilité de récupération :',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ...[
                '• Toute ta progression (niveaux, XP, or, cristaux)',
                '• Toutes tes quêtes (historique inclus)',
                '• Ton inventaire et équipement',
                '• Tes achats premium et abonnements',
                '• Ton chat compagnon',
              ].map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    t,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Case à cocher — double palier de confirmation
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _isLoading
                    ? null
                    : () =>
                        setState(() => _confirmed = !_confirmed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      key: const Key('chk_confirm_delete'),
                      value: _confirmed,
                      onChanged: _isLoading
                          ? null
                          : (v) =>
                              setState(() => _confirmed = v ?? false),
                      activeColor: AppColors.error,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 11),
                        child: Text(
                          'Je comprends que cette suppression est définitive '
                          'et irréversible, et que mes données ne pourront '
                          'jamais être récupérées.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Zone d'erreur (affichée uniquement sur échec)
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child:
              const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
        ),
        FilledButton(
          key: const Key('btn_confirm_delete'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          // Bouton actif uniquement si la case est cochée ET que l'appel n'est pas en cours.
          onPressed: (_confirmed && !_isLoading)
              ? () => _onConfirmDelete(context)
              : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Supprimer définitivement'),
        ),
      ],
    );
  }

  Future<void> _onConfirmDelete(BuildContext context) async {
    // Capturer les références AVANT tout await (règle use_build_context_synchronously).
    final profileVm = widget.vm;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Appel Edge Function + purge Hive + signOut (via ProfileViewModel).
      // signOut() propage onSignedOut → QuestViewModel (et tous les VMs abonnés)
      // se vident automatiquement via leurs StreamSubscriptions.
      await profileVm.deleteAccount();

      // _AuthGate détecte l'absence de session et redirige vers LoginPage.
      // On ferme le dialog si le widget est encore monté (cas des tests).
      if (context.mounted) Navigator.pop(context);
    } on Exception catch (e) {
      // Échec partiel ou réseau : NE PAS déconnecter.
      // Afficher le message pour que l'utilisateur puisse réessayer ou contacter le support.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }
}
