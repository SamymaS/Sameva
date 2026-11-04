import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'presentation/view_models/ai_validation_credits_service.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/theme_view_model.dart';
import 'ui/theme/app_theme.dart';

/// Sameva : navigation go_router (ADR 0007), dock à une pile par onglet,
/// redirections d'authentification centralisées dans [creerRouteur].
class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = creerRouteur(context.read<AuthViewModel>());
    // Retour dans l'app après un paiement : vérifie l'abonnement.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  /// Le webhook Stripe est asynchrone : au retour dans l'app après un
  /// paiement, un court sondage de l'abonnement premium est lancé.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AiValidationCreditsService>().onAppResumedAfterCheckout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeViewModel>();
    return MaterialApp.router(
      title: 'Sameva',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
