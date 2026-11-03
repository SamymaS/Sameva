import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/models/quest_model.dart';
import '../../presentation/view_models/auth_view_model.dart';
import '../../presentation/view_models/quest_view_model.dart';
import '../../ui/pages/auth/login_page.dart';
import '../../ui/pages/auth/register_page.dart';
import '../../ui/pages/avatar/avatar_page.dart';
import '../../ui/pages/cat/cat_page.dart';
import '../../ui/pages/home/sanctuary_page.dart';
import '../../ui/pages/market/market_page.dart';
import '../../ui/pages/onboarding/onboarding_page.dart';
import '../../ui/pages/profile/profile_page.dart';
import '../../ui/pages/quest/create_quest_choice_page.dart';
import '../../ui/pages/quest/create_quest_page.dart';
import '../../ui/pages/quest/quest_validation_page.dart';
import '../../ui/pages/quest/quests_list_page.dart';
import '../../ui/pages/rewards/rewards_page.dart';
import '../../ui/pages/settings/settings_page.dart';
import 'app_shell.dart';

/// Chemins de l'app (ADR 0007). Un seul endroit pour les écrire.
abstract final class Routes {
  static const connexion = '/connexion';
  static const inscription = '/inscription';
  static const bienvenue = '/bienvenue';
  static const accueil = '/accueil';
  static const quetes = '/quetes';
  static const portail = '/portail';
  static const chat = '/chat';
  static const profil = '/profil';
  static const nouvelleQuete = '/quetes/nouvelle';
  static const nouvelleQuetePerso = '/quetes/nouvelle/perso';
  static const parametres = '/parametres';
  static const recompenses = '/recompenses';
  static const avatar = '/avatar';

  /// Validation d'une quête. Lien profond : sameva://app/quete/<id>.
  static String validerQuete(String id) => '/quete/$id';

  /// Onglets du dock, dans l'ordre d'affichage.
  static const onglets = [accueil, quetes, portail, chat, profil];
}

/// Quitte l'écran courant. Ouvert par un lien profond, il n'a rien en dessous :
/// on retombe alors sur [repli] au lieu d'un écran noir (constat Q19).
void quitterEcran(BuildContext context, {String repli = Routes.quetes}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(repli);
  }
}

/// Le joueur a-t-il terminé l'accueil ? (clé Hive par utilisateur.)
///
/// Les anciennes installations avaient une clé globale `has_onboarded` : elle
/// est transférée au premier utilisateur connecté puis supprimée, pour qu'un
/// autre compte sur le même téléphone n'en hérite pas.
bool aTermineAccueil(String userId) {
  final settings = Hive.box('settings');
  final cle = 'has_onboarded_$userId';
  if (settings.get('has_onboarded') == true && !settings.containsKey(cle)) {
    settings.put(cle, true);
    settings.delete('has_onboarded');
  }
  return settings.get(cle) == true;
}

/// Décision de redirection, isolée pour être testée sans widget.
///
/// - non connecté : seules la connexion et l'inscription sont accessibles ;
/// - connecté sans accueil terminé : l'accueil (onboarding) d'abord ;
/// - connecté : jamais renvoyé vers la connexion.
String? redirectionPour({
  required String chemin,
  required bool connecte,
  required bool accueilTermine,
}) {
  const publiques = {Routes.connexion, Routes.inscription};
  if (!connecte) return publiques.contains(chemin) ? null : Routes.connexion;
  if (!accueilTermine) {
    return chemin == Routes.bienvenue ? null : Routes.bienvenue;
  }
  if (publiques.contains(chemin) ||
      chemin == Routes.bienvenue ||
      chemin == '/') {
    return Routes.accueil;
  }
  return null;
}

GoRouter creerRouteur(AuthViewModel auth) {
  return GoRouter(
    initialLocation: Routes.accueil,
    refreshListenable: auth,
    redirect: (context, state) {
      final uid = auth.userId;
      return redirectionPour(
        chemin: state.matchedLocation,
        connecte: auth.isAuthenticated && uid != null,
        accueilTermine: uid != null && aTermineAccueil(uid),
      );
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => Routes.accueil),
      GoRoute(path: Routes.connexion, builder: (_, __) => const LoginPage()),
      GoRoute(
          path: Routes.inscription, builder: (_, __) => const RegisterPage()),
      GoRoute(
          path: Routes.bienvenue, builder: (_, __) => const OnboardingPage()),
      // Dock : une pile par onglet, état conservé en changeant d'onglet.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.accueil,
                builder: (_, __) => const SanctuaryPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.quetes,
                builder: (_, __) => const QuestsListPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.portail, builder: (_, __) => const PortailPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.chat, builder: (_, __) => const CatPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.profil, builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
      // Écrans plein écran, au-dessus du dock.
      GoRoute(
          path: Routes.nouvelleQuete,
          builder: (_, __) => const CreateQuestChoicePage()),
      GoRoute(
          path: Routes.nouvelleQuetePerso,
          builder: (_, __) => const CreateQuestPage()),
      GoRoute(
          path: Routes.parametres, builder: (_, __) => const SettingsPage()),
      GoRoute(path: Routes.avatar, builder: (_, __) => const AvatarPage()),
      GoRoute(
        path: Routes.recompenses,
        builder: (_, state) => RewardsPage(args: state.extra as RewardsArgs?),
      ),
      GoRoute(
        path: '/quete/:id',
        builder: (_, state) {
          final quete = state.extra;
          return quete is Quest
              ? QuestValidationPage(quest: quete)
              : QueteParIdentifiant(id: state.pathParameters['id']!);
        },
      ),
    ],
  );
}

/// Ouvre une quête depuis son identifiant (lien profond, notification) :
/// attend que les quêtes soient chargées puis affiche sa validation.
class QueteParIdentifiant extends StatefulWidget {
  const QueteParIdentifiant({super.key, required this.id});
  final String id;

  @override
  State<QueteParIdentifiant> createState() => _QueteParIdentifiantState();
}

class _QueteParIdentifiantState extends State<QueteParIdentifiant> {
  /// Une seule relecture serveur : la quête peut avoir été créée ailleurs
  /// (autre appareil, notification) depuis le dernier chargement (constat Q21).
  bool _relue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<QuestViewModel>();
      final uid = context.read<AuthViewModel>().userId;
      final connue = vm.quests.any((q) => q.id == widget.id);
      if (!connue && uid != null) await vm.loadQuests(uid);
      if (mounted) setState(() => _relue = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuestViewModel>();
    final quete = vm.quests.where((q) => q.id == widget.id).firstOrNull;
    if (quete != null) return QuestValidationPage(quest: quete);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => quitterEcran(context))),
      body: Center(
        child: !_relue || vm.isLoading
            ? const CircularProgressIndicator()
            : const Text('Cette quête est introuvable ou déjà terminée.'),
      ),
    );
  }
}
