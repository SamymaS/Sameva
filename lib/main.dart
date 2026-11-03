import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/supabase_config.dart';
import 'core/auth/secure_session_storage.dart';
import 'data/repositories/ai_credits_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cat_repository.dart';
import 'data/repositories/game_api.dart';
import 'data/repositories/premium_subscription_repository.dart';
import 'data/repositories/quest_repository.dart';
import 'data/repositories/player_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/leaderboard_repository.dart';
import 'domain/services/notification_service.dart';
import 'presentation/view_models/quest_view_model.dart';
import 'presentation/view_models/player_view_model.dart';
import 'presentation/view_models/inventory_view_model.dart';
import 'presentation/view_models/equipment_view_model.dart';
import 'presentation/view_models/ai_validation_credits_service.dart';
import 'presentation/view_models/cat_view_model.dart';
import 'presentation/view_models/notification_view_model.dart';
import 'presentation/view_models/theme_view_model.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'app.dart';

/// Journalise les clés de configuration absentes (dart-define).
///
/// Ne lance jamais et ne bloque jamais le démarrage : une clé manquante doit
/// rester identifiable dans `adb logcat` plutôt que de se manifester plus tard
/// sous une forme trompeuse. Sans GOOGLE_WEB_CLIENT_ID, l'échec de connexion
/// Google est en effet indiscernable d'une annulation utilisateur.
void _journaliserConfigurationManquante() {
  final absentes = SupabaseConfig.missingKeys;
  if (absentes.isEmpty) return;

  debugPrint('==============================================================');
  debugPrint(
      'SAMEVA CONFIG (${SupabaseConfig.environment}): cles absentes -> ${absentes.join(', ')}');
  debugPrint(
      'SAMEVA CONFIG: lancer avec --dart-define-from-file=config/<env>.json');
  if (absentes.contains('GOOGLE_WEB_CLIENT_ID')) {
    debugPrint(
      'SAMEVA CONFIG: sans GOOGLE_WEB_CLIENT_ID, la connexion Google echouera '
      'et l\'echec ressemblera a une annulation utilisateur. '
      'Build CI : verifier le secret GitHub.',
    );
  }
  debugPrint('==============================================================');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  _journaliserConfigurationManquante();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    // Mobile : session chiffrée (Keystore / Keychain). Web : stockage par défaut.
    authOptions: FlutterAuthClientOptions(
      localStorage: kIsWeb
          ? null
          : SecureSessionStorage(
              persistSessionKey:
                  SecureSessionStorage.cleParDefaut(SupabaseConfig.supabaseUrl),
            ),
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox('quests');
  final statsBox = await Hive.openBox('playerStats');
  final settingsBox = await Hive.openBox('settings');
  await Hive.openBox('inventory');
  await Hive.openBox('equipment');
  await Hive.openBox('cats');
  await Hive.openBox('aiValidation');

  await NotificationService.init();

  // Repositories
  final supabase = Supabase.instance.client;
  final authRepo = AuthRepository(supabase);
  final userRepo = UserRepository(supabase);
  final questRepo = QuestRepository(supabase, userRepo);
  // API d'intentions du jeu : le serveur est l'unique autorité (Sprint 1).
  final gameApi = GameApi(supabase);
  final playerRepo = PlayerRepository(statsBox, gameApi);
  final leaderboardRepo = LeaderboardRepository(supabase);
  final catRepo = CatRepository(supabase);
  final aiCreditsRepo = AiCreditsRepository(supabase);
  final premiumSubsRepo = PremiumSubscriptionRepository(supabase);

  // AuthViewModel instancié en premier pour exposer onSignedOut aux VMs métier.
  final authViewModel = AuthViewModel(authRepo);
  final signedOutStream = authViewModel.onSignedOut;
  final signedInStream = authViewModel.onSignedIn;

  final inventoryBox = Hive.box('inventory');
  final equipmentBox = Hive.box('equipment');
  final catsBox = Hive.box('cats');
  final aiValidationBox = Hive.box('aiValidation');
  // P1 lifecycle auth : tous les VMs per-user reçoivent maintenant onSignedIn.
  // onSignedOut → reset() (déjà présent), onSignedIn → rechargement automatique.
  // La garde idempotente de chaque VM protège du double-load avec SanctuaryPage._load().
  final questViewModel = QuestViewModel(questRepo,
      onSignedOut: signedOutStream, onSignedIn: signedInStream);
  final playerViewModel = PlayerViewModel(playerRepo,
      onSignedOut: signedOutStream, onSignedIn: signedInStream);
  final inventoryViewModel = InventoryViewModel(inventoryBox,
      onSignedOut: signedOutStream, onSignedIn: signedInStream)
    ..loadInventory();
  final equipmentViewModel = EquipmentViewModel(equipmentBox,
      onSignedOut: signedOutStream, onSignedIn: signedInStream)
    ..loadEquipment();
  // loadCats() au boot lit la box Hive avec la clé per-user
  // si un user est déjà connecté (session persistée). Le
  // stream onSignedIn déclenchera un second loadCats() au
  // prochain signIn — la garde idempotente de loadCats()
  // protège du double-load. Race condition non observable
  // tant que main() reste sync.
  final catViewModel = CatViewModel(
    catsBox,
    catRepository: catRepo,
    onSignedOut: signedOutStream,
    onSignedIn: signedInStream,
  )..loadCats();

  // AiValidationCreditsService : lecture seule de l'énergie de l'Oracle (Sprint 1).
  // onSignedIn → load() (lecture serveur) ; l'énergie est accordée par claim_daily.
  // onSignedOut → reset() (vide mémoire, préserve Hive).
  final aiCreditsService = AiValidationCreditsService(
    aiValidationBox,
    repository: aiCreditsRepo,
    premiumRepository: premiumSubsRepo,
    onSignedOut: signedOutStream,
    onSignedIn: signedInStream,
  );

  // Session déjà ouverte au démarrage (y compris par un lien profond qui
  // n'affiche pas le Sanctuaire) : les soldes sont lus tout de suite, sinon
  // l'énergie s'affichait à 0 et bloquait la validation (constat Q22).
  final sessionUid = supabase.auth.currentUser?.id;
  if (sessionUid != null) {
    unawaited(playerViewModel.loadPlayerStats(sessionUid));
    unawaited(aiCreditsService.load(sessionUid));
  }

  runApp(
    // Riverpod (ADR 0007) cohabite avec Provider le temps de la migration.
    ProviderScope(
      child: MultiProvider(
        providers: [
          // ViewModels globaux
          ChangeNotifierProvider(create: (_) => ThemeViewModel(settingsBox)),
          ChangeNotifierProvider.value(value: authViewModel),

          // Repositories exposés pour injection dans les ViewModels de pages.
          // QuestRepository n'est plus exposé : depuis la refonte source de vérité
          // unique, les VMs Quest passent par le QuestViewModel global (qui détient
          // le repo), plus aucune page ne lit QuestRepository directement.
          Provider<PlayerRepository>.value(value: playerRepo),
          Provider<GameApi>.value(value: gameApi),
          Provider<LeaderboardRepository>.value(value: leaderboardRepo),

          ChangeNotifierProvider(
              create: (_) => NotificationViewModel(settingsBox)),
          ChangeNotifierProvider.value(value: questViewModel),
          ChangeNotifierProvider.value(value: playerViewModel),
          ChangeNotifierProvider.value(value: inventoryViewModel),
          ChangeNotifierProvider.value(value: equipmentViewModel),
          ChangeNotifierProvider.value(value: catViewModel),
          ChangeNotifierProvider.value(value: aiCreditsService),
        ],
        child: const SamevaApp(),
      ),
    ),
  );
}
