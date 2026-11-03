import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ai_validation_state_model.dart';
import '../../data/repositories/ai_credits_repository.dart';
import '../../data/repositories/premium_subscription_repository.dart';

/// Portefeuille d'énergie de l'Oracle, en LECTURE SEULE (Sprint 1).
///
/// Le serveur est l'unique autorité : l'énergie est accordée par
/// `claim_daily` (recharge quotidienne, onboarding) et consommée ou rendue
/// par l'Edge Function `analyze-quest-proof`. Ce service se contente de lire
/// `ai_validation_credits` (cache Hive pour l'affichage hors-ligne) et le
/// statut premium. Il n'écrit plus jamais vers Supabase.
///
/// Stockage local : boîte Hive 'aiValidation', clé 'ai_validation_<userId>'.
/// Les libellés d'affichage sont définis par la couche UI, PAS ici.
class AiValidationCreditsService extends ChangeNotifier {
  // ---- Constantes métier (affichage ; les vraies valeurs sont serveur) ----

  /// Énergie rechargée chaque jour (plancher, `oracle.daily_energy`).
  static const int kDailyEnergyFloor = 3;

  /// Énergie offerte à la première connexion (`oracle.onboarding_energy`).
  static const int kOnboardingGrant = 5;

  // ---- État interne ----

  final Box _box;

  /// Repository Supabase des crédits IA (optionnel pour les tests sans réseau).
  final AiCreditsRepository? _repo;

  /// Repository Supabase de l'entitlement premium (optionnel pour les tests).
  ///
  /// Quand null, le fetch d'entitlement est ignoré (mode local-only).
  final PremiumSubscriptionRepository? _premiumRepo;

  /// Injecté en test pour contourner l'accès à Supabase.instance.
  /// En production, laissé null → userId résolu via Supabase.instance.client.
  final String? _overrideUserId;

  /// Vrai si un checkout Stripe a été initié (pour déclencher le refresh au resume).
  bool _checkoutInitiated = false;

  /// Vrai si un poll d'entitlement est actuellement en cours.
  /// Empêche les polls concurrents quand l'utilisateur alterne avant/arrière
  /// plusieurs fois pendant que le premier poll tourne encore.
  bool _pollInProgress = false;

  StreamSubscription<void>? _signedOutSub;
  StreamSubscription<void>? _signedInSub;

  /// Identifiant de l'utilisateur courant.
  /// Positionné par [load]. Au signIn, le uid est résolu via [_currentUserId]
  /// (le stream onSignedIn ne transporte pas d'identifiant).
  String? _userId;

  /// État courant du portefeuille.
  AiValidationState _state = AiValidationState.empty();

  AiValidationCreditsService(
    this._box, {
    AiCreditsRepository? repository,
    PremiumSubscriptionRepository? premiumRepository,
    Stream<void>? onSignedOut,
    Stream<void>? onSignedIn,
    String? testUserId,
  })  : _repo = repository,
        _premiumRepo = premiumRepository,
        _overrideUserId = testUserId {
    if (onSignedOut != null) {
      _signedOutSub = onSignedOut.listen((_) => reset());
    }
    if (onSignedIn != null) {
      // Relit le solde serveur après connexion.
      _signedInSub = onSignedIn.listen((_) => _onSignedIn());
    }
  }

  @override
  void dispose() {
    _signedOutSub?.cancel();
    _signedInSub?.cancel();
    super.dispose();
  }

  // ---- Getters publics ----

  /// Solde de crédits IA disponibles.
  int get balance => _state.balance;

  /// Indique si l'utilisateur est en mode premium.
  bool get isPremium => _state.isPremium;

  /// Date d'expiration du premium (null si pas de premium).
  DateTime? get premiumUntil => _state.premiumUntil;

  /// Indique si le bonus d'onboarding a déjà été accordé.
  bool get onboardingGranted => _state.onboardingGranted;

  /// Dernier palier de série récompensé.
  int get lastRewardedStreakMilestone => _state.lastRewardedStreakMilestone;

  /// Snapshot immutable de l'état complet (lecture externe).
  AiValidationState get state => _state;

  // ---- Identité ----

  /// Identifiant de l'utilisateur courant.
  /// En production : Supabase.instance.client.auth.currentUser?.id.
  /// En test : valeur injectée via testUserId (évite l'accès à Supabase.instance).
  /// Même pattern que [CatViewModel].
  String? get _currentUserId {
    if (_overrideUserId != null) return _overrideUserId;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase non initialisé (environnement de test sans testUserId).
      return null;
    }
  }

  // ---- Clé Hive ----

  /// Clé Hive isolée par userId. Retourne null si userId inconnu → no-op.
  String? get _hiveKey {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;
    return 'ai_validation_$uid';
  }

  // ---- Chargement ----

  /// Charge l'état pour [userId] : cache Hive immédiat, puis lecture serveur
  /// qui fait toujours autorité (plus de réconciliation last-write-wins :
  /// le client n'écrit plus). Hors-ligne, le cache reste affiché.
  Future<void> load(String userId) async {
    _userId = userId;
    final key = _hiveKey;
    if (key == null) return;

    try {
      final raw = _box.get(key);
      _state = raw != null
          ? AiValidationState.fromJson(Map<String, dynamic>.from(raw as Map))
          : AiValidationState.empty();
    } catch (e) {
      debugPrint('AiValidationCreditsService: erreur lecture Hive: $e');
      _state = AiValidationState.empty();
    }
    notifyListeners();

    final repo = _repo;
    if (repo != null) {
      try {
        final remote = await repo.fetchForUser(userId);
        if (remote != null) {
          _state = remote.copyWith(
            isPremium: _state.isPremium,
            premiumUntil: _state.premiumUntil,
          );
          await _persist();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('AiValidationCreditsService: lecture hors-ligne, cache conservé: $e');
      }
    }

    await _fetchAndApplyPremiumEntitlement(userId);
  }

  /// Relit le solde serveur (après une analyse Oracle ou `claim_daily`).
  Future<void> refresh() async {
    final uid = _userId ?? _currentUserId;
    if (uid == null || uid.isEmpty) return;
    await load(uid);
  }

  /// Vide le state en mémoire au logout (sans purger Hive).
  /// Les données restent en Hive isolées par userId.
  ///
  /// Invalide également les flags de poll ([_checkoutInitiated] et
  /// [_pollInProgress]) pour qu'un logout ou changement d'utilisateur
  /// n'empêche pas un nouveau checkout d'être suivi correctement.
  void reset() {
    _userId = null;
    _checkoutInitiated = false;
    _pollInProgress = false;
    _state = AiValidationState.empty();
    notifyListeners();
  }

  // ---- Lecture pour l'UI ----

  /// Indique si une analyse Oracle peut être lancée (indication d'interface :
  /// le serveur reste juge et peut refuser avec `energie_insuffisante`).
  bool canValidateWithAI() => _state.isPremium || _state.balance > 0;

  /// Re-lit l'entitlement premium depuis le serveur à la demande.
  ///
  /// Utilise [_userId] courant — no-op si pas de user ou pas de repo premium.
  /// À appeler au retour dans l'app après un checkout Stripe initié.
  Future<void> refreshEntitlement() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    await _fetchAndApplyPremiumEntitlement(uid);
  }

  /// Initie le checkout Stripe en invoquant l'Edge Function `create-checkout-session`.
  ///
  /// - Le JWT est passé automatiquement par le client Supabase authentifié.
  /// - L'URL de la session Stripe est ouverte dans le navigateur externe.
  /// - [checkoutUrl] peut être injecté en test pour court-circuiter l'invoke.
  ///
  /// Garde : no-op immédiat si l'utilisateur est déjà premium (protection financière).
  Future<void> startPremiumCheckout({
    SupabaseClient? supabaseClient,
    Future<String?> Function()? checkoutUrlProvider,
  }) async {
    // Garde financière : inutile d'ouvrir un nouveau checkout si premium actif.
    if (_state.isPremium) return;

    try {
      String? url;

      if (checkoutUrlProvider != null) {
        // Mode test : le provider externe fournit l'URL directement.
        url = await checkoutUrlProvider();
      } else {
        // Mode production : invoke l'Edge Function via Supabase (JWT auto-injecté).
        final client = supabaseClient ?? Supabase.instance.client;
        final response = await client.functions.invoke(
          'create-checkout-session',
          body: <String, dynamic>{},
        );
        final data = response.data;
        if (data is Map) {
          url = data['url'] as String?;
        }
      }

      if (url == null || url.isEmpty) {
        debugPrint(
          'AiValidationCreditsService.startPremiumCheckout: URL manquante dans la réponse.',
        );
        return;
      }

      final uri = Uri.parse(url);
      _checkoutInitiated = true;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AiValidationCreditsService.startPremiumCheckout: erreur: $e');
    }
  }

  /// Appelé au resume de l'app si un checkout a été initié.
  ///
  /// Effectue un poll avec backoff progressif (8 tentatives, ~30 s) pour couvrir
  /// la latence variable du webhook Stripe. Arrête dès que [isPremium] bascule true.
  ///
  /// Chaque tentative passe par [refreshEntitlement] → [_fetchAndApplyPremiumEntitlement]
  /// → [notifyListeners] : la propagation UI est automatique, sans redémarrage.
  ///
  /// Le flag [_checkoutInitiated] est réinitialisé à la FIN (succès ou épuisement),
  /// pas au début — des resumes successifs pendant l'attente ne lancent pas un second
  /// poll concurrent (protégé par [_pollInProgress]).
  ///
  /// [delayProvider] : injectable en test pour court-circuiter les vraies durées.
  /// En production, laissé null → délais backoff par défaut.
  Future<void> onAppResumedAfterCheckout({
    Duration Function(int attempt)? delayProvider,
  }) async {
    if (!_checkoutInitiated) return;
    // Un poll est déjà en cours : on laisse le cycle actuel se terminer.
    if (_pollInProgress) return;

    _pollInProgress = true;

    // Délais progressifs en secondes entre les tentatives.
    // 8 tentatives × ~30 s de couverture totale (2+3+4+5+5+5+5 = 29 s entre les polls).
    const delaisSecondes = [2, 3, 4, 5, 5, 5, 5];

    try {
      for (var i = 0; i <= delaisSecondes.length; i++) {
        await refreshEntitlement();
        if (_state.isPremium) {
          // Succès : entitlement confirmé, UI déjà notifiée par refreshEntitlement.
          _checkoutInitiated = false;
          return;
        }
        if (i < delaisSecondes.length) {
          final delay = delayProvider != null
              ? delayProvider(i)
              : Duration(seconds: delaisSecondes[i]);
          await Future<void>.delayed(delay);
        }
      }
      // Épuisement : le webhook Stripe était trop lent.
      // L'utilisateur obtiendra son statut au prochain load (redémarrage ou reconnexion).
      _checkoutInitiated = false;
    } on Exception catch (e) {
      // Defense in depth : refreshEntitlement() ne lève jamais en pratique
      // (son propre try/catch absorbe toutes les erreurs réseau/Hive).
      // Ce catch protège contre un futur refactoring qui retirerait ce garde-fou.
      // _checkoutInitiated reste true → le prochain resume retentera.
      debugPrint(
        'AiValidationCreditsService.onAppResumedAfterCheckout: erreur inattendue: $e',
      );
    } finally {
      _pollInProgress = false;
    }
  }

  /// Met à jour le statut premium.
  ///
  /// Sera piloté par le webhook Stripe/App Store plus tard.
  Future<void> setPremium(bool active, {DateTime? until}) async {
    _state = _state.copyWith(
      isPremium: active,
      premiumUntil: until,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist();
    notifyListeners();
  }

  // ---- Helpers privés ----

  /// Fetche l'entitlement premium depuis Supabase et l'applique à l'état local.
  ///
  /// Best-effort : en cas d'erreur réseau, on garde l'état courant sans crash.
  /// Le fetch est séparé de la réconciliation LWW des crédits pour ne pas
  /// perturber la logique last-write-wins (tables distinctes, workflows distincts).
  ///
  /// IMPORTANT : cet appel met à jour [isPremium] et [premiumUntil] via [_setPremiumFromEntitlement]
  /// qui appelle [_persist] + [notifyListeners] ; aucune écriture serveur n'a lieu, pour éviter
  /// de ré-envoyer les crédits vers Supabase à chaque refresh d'entitlement.
  Future<void> _fetchAndApplyPremiumEntitlement(String userId) async {
    final premiumRepo = _premiumRepo;
    if (premiumRepo == null) return; // pas de repo → mode local-only

    try {
      final entitlement = await premiumRepo.fetchForUser(userId);
      await _setPremiumFromEntitlement(
        entitlement.isPremium,
        until: entitlement.premiumUntil,
      );
    } catch (e) {
      // Erreur réseau : garde l'état courant, aucun crash (offline-first).
      debugPrint(
        'AiValidationCreditsService: fetch entitlement hors-ligne, état conservé: $e',
      );
    }
  }

  /// Met à jour [isPremium] et [premiumUntil] dans l'état local et Hive,
  /// SANS déclencher d'upsert vers la table `ai_validation_credits`.
  ///
  /// Comme [setPremium],
  /// cette méthode ne provoque PAS d'écriture réseau vers la table des crédits.
  /// L'entitlement est lecture-seule côté client (piloté par le webhook Stripe).
  Future<void> _setPremiumFromEntitlement(
    bool active, {
    DateTime? until,
  }) async {
    // Évite une mutation inutile si rien ne change.
    if (_state.isPremium == active && _state.premiumUntil == until) return;

    _state = _state.copyWith(
      isPremium: active,
      premiumUntil: until,
      // Ne met PAS à jour updatedAt : cet état vient du serveur, pas d'une
      // mutation locale. Mettre updatedAt à now() perturberait le LWW des crédits
      // lors d'un prochain load (l'état local deviendrait artificiellement plus récent).
    );
    // Persiste en Hive pour que le premium survive aux redémarrages sans réseau.
    await _persist();
    notifyListeners();
    // Pas d'upsert vers ai_validation_credits : isPremium n'y est pas stocké.
  }

  /// Persiste l'état courant dans Hive. No-op si userId inconnu.
  Future<void> _persist() async {
    final key = _hiveKey;
    if (key == null) return;
    await _box.put(key, _state.toJson());
  }

  /// Appelé lors d'un signIn : simple lecture (l'énergie quotidienne et
  /// l'onboarding sont accordés par `claim_daily` côté serveur).
  Future<void> _onSignedIn() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;
    await load(uid);
  }

  // ---- Helpers de test ----

  /// Marque le checkout comme initié, pour les tests du mécanisme de poll.
  ///
  /// En production, [_checkoutInitiated] est positionné uniquement par
  /// [startPremiumCheckout] après l'ouverture réussie du navigateur externe.
  /// Ce helper permet aux tests d'atteindre [onAppResumedAfterCheckout] sans
  /// appeler [launchUrl] (non disponible dans l'environnement de test).
  @visibleForTesting
  void markCheckoutInitiatedForTest() => _checkoutInitiated = true;

  /// Expose [_checkoutInitiated] en lecture pour les tests.
  @visibleForTesting
  bool get checkoutInitiatedForTest => _checkoutInitiated;

  /// Expose [_pollInProgress] en lecture pour les tests.
  @visibleForTesting
  bool get pollInProgressForTest => _pollInProgress;
}
