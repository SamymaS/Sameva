import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../theme/app_colors.dart';

/// Formulaire de mise à niveau d'un compte invité vers un compte email.
/// Accessible uniquement si [AuthViewModel.isGuest] est vrai.
/// Le user_id est préservé — toutes les données restent intactes.
class SaveGuestAccountPage extends StatefulWidget {
  const SaveGuestAccountPage({super.key});

  @override
  State<SaveGuestAccountPage> createState() => _SaveGuestAccountPageState();
}

class _SaveGuestAccountPageState extends State<SaveGuestAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Sauvegarder ma progression',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTurquoise.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryTurquoise.withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppColors.primaryTurquoise, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Votre progression est préservée',
                            style: TextStyle(
                              color: AppColors.primaryTurquoise,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Associer un email à votre compte invité ne '
                        'supprime aucune donnée. Vos quêtes, XP et items '
                        'restent intacts.\n\n'
                        'Une confirmation par email peut être requise selon '
                        'la configuration du projet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  key: const Key('field_email_invite'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'vous@exemple.fr',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Indiquez votre email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('field_password_invite'),
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: '6 caractères minimum',
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('field_confirm_invite'),
                  controller: _confirmController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                if (context.watch<AuthViewModel>().errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.watch<AuthViewModel>().errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 32),
                Consumer<AuthViewModel>(
                  builder: (context, auth, _) {
                    return FilledButton(
                      key: const Key('btn_sauvegarder_invite'),
                      onPressed: auth.isLoading ? null : () => _submit(auth),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTurquoise,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Sauvegarder ma progression',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.3))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Associez votre compte Google : votre progression '
                  '(quêtes, XP, items) est conservée à l\'identique.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Consumer<AuthViewModel>(
                  builder: (context, auth, _) {
                    return OutlinedButton(
                      key: const Key('btn_continuer_google_invite'),
                      onPressed: auth.isLoading ? null : () => _continuerAvecGoogle(auth),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continuer avec Google'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continuerAvecGoogle(AuthViewModel auth) async {
    try {
      await auth.signInWithGoogle();
      if (!mounted) return;
      if (!auth.isGuest && auth.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte Google associé ! Votre progression est conservée.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Message déjà dans AuthViewModel.errorMessage (ou annulation silencieuse)
    }
  }

  Future<void> _submit(AuthViewModel auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await auth.saveGuestAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Affiche un message de succès puis revient à la page précédente.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte sauvegardé ! Vérifiez votre email si une confirmation est requise.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      // Message déjà dans AuthViewModel.errorMessage
    }
  }
}
