import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../theme/app_colors.dart';

/// Connexion — UX : Fitts (boutons 48dp+), Hick (2 actions : Connexion, Créer un compte), Jakob (formulaire familier).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Sameva',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous pour gérer vos quêtes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'vous@exemple.fr',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Indiquez votre email';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Indiquez votre mot de passe';
                    return null;
                  },
                ),
                if (context.watch<AuthProvider>().errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.watch<AuthProvider>().errorMessage!,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return FilledButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => _submit(auth),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connexion'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/register'),
                  child: const Text('Créer un compte'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => _signInAnonymously(context),
                  child: Text(
                    'Continuer sans compte',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      // Auth state change will rebuild and show home
    } catch (_) {}
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await context.read<AuthProvider>().signInAnonymously();
    } catch (_) {}
  }
}
