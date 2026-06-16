import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ai_validation_state_model.dart';
import '../../data/repositories/ai_credits_repository.dart';
import '../../data/repositories/premium_subscription_repository.dart';

/// Service gérant le portefeuille de crédits IA (validation freemium).
///
/// Ce service est la SOURCE DE VÉRITÉ UNIQUE pour l'état du portefeuille.
/// Toute lecture et mutation passe par lui ; jamais directement depuis l'UI.
///
/// Stockage local : boîte Hive 'aiValidation', clé 'ai_validation_<userId>'.
/// Sync serveur : [AiCreditsRepository] (Supabase), best-effort, jamais bloquant.
/// Pattern identique à la boîte 'cats' de [CatViewModel].
///
/// Réconciliation last-write-wins (LWW) au [load] :
///   Si remote.updatedAt > local.updatedAt → adopte remote + écrit Hive.
///   Sinon → garde local + upsert Supabase best-effort.
///   Si pas de remote → upsert local (crée la ligne côté serveur).
///   Si fetch échoue (hors-ligne) → garde local, aucun crash.
///
/// Les libellés d'affichage (nom du jeton, etc.) sont définis par la couche UI,
/// PAS ici. Ce service ne contient aucun texte destiné à l'utilisateur.
class AiValidationCreditsService extends ChangeNotifier {
  // ---- Constantes métier ----

  /// Crédits accordés à l'onboarding (une seule fois par compte).
  static const int kOnboardingGrant = 5;

  /// Plafond du portefeuille freemium.
  /// Les sources gratuites (onboarding, daily, streak) ne dépassent jamais ce cap.
  static const int kFreeWalletCap = 10;

  /// Crédits accordés par octroi quotidien.
  static const int kDailyGrant = 1;

  /// Crédits accordés à chaque palier de série atteint.
  static const int kStreakMilestoneGrant = 2;

  /// Intervalle (en jours) entre deux paliers de série récompensés.
  static const int kStreakMilestoneInterval = 7;

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
      // Recharge les crédits après connexion, puis accorde les bonus de démarrage.
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

  // ---- Chargement et réconciliation ----

  /// Charge et réconcilie l'état pour l'utilisateur [userId].
  ///
  /// Ordre d'exécution :
  /// a. Hydrater depuis Hive (instantané) → notifyListeners.
  /// b. Fetch Supabase best-effort (peut échouer hors-ligne).
  /// c. Réconciliation LWW par [updatedAt] :
  ///    - remote.updatedAt > local.updatedAt → adopte remote + écrit Hive.
  ///    - sinon → garde local + upsert Supabase best-effort.
  ///    - pas de remote → upsert local (crée la ligne).
  ///    - fetch échoue → garde local, aucun crash.
  Future<void> load(String userId) async {
    _userId = userId;
    final key = _hiveKey;
    if (key == null) return;

    // Étape a : hydratation Hive immédiate.
    // hadLocal distingue « une vraie entrée Hive existe » d'un placeholder vide.
    // C'est crucial : AiValidationState.empty() porte updatedAt = now(), donc un
    // état vide (réinstallation) gagnerait à tort le LWW face à une ligne serveur
    // plus ancienne et écraserait les données distantes. Un local absent ne doit
    // jamais l'emporter.
    AiValidationState localState;
    bool hadLocal = false;
    try {
      final raw = _box.get(key);
      if (raw != null) {
        localState = AiValidationState.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        hadLocal = true;
      } else {
        localState = AiValidationState.empty();
      }
    } catch (e) {
      debugPrint('AiValidationCreditsService: erreur lecture Hive: $e');
      localState = AiValidationState.empty();
    }
    _state = localState;
    notifyListeners();

    // Étapes b + c : crédits (best-effort). Encapsulées dans un bloc pour que
    // leurs sorties anticipées (repo absent, fetch hors-ligne) ne sautent PAS
    // l'étape d : l'entitlement premium vit dans une table séparée et doit être
    // lu indépendamment du résultat du fetch crédits.
    final repo = _repo;
    if (repo != null) {
      AiValidationState? remoteState;
      bool fetchEchoue = false;

      try {
        remoteState = await repo.fetchForUser(userId);
      } catch (e) {
        // Erreur réseau : garde local, aucun crash.
        debugPrint('AiValidationCreditsService: fetch hors-ligne, fallback Hive: $e');
        fetchEchoue = true;
      }

      if (!fetchEchoue) {
        // Étape c : réconciliation LWW.
        if (remoteState != null) {
          // Adopter remote si aucun local réel (réinstallation) OU si remote est
          // plus récent. Sans le garde hadLocal, un état vide (updatedAt = now())
          // l'emporterait et écraserait la ligne serveur.
          if (!hadLocal || remoteState.updatedAt.isAfter(localState.updatedAt)) {
            // Remote fait autorité → adopter remote.
            _state = remoteState;
            try {
              await _box.put(key, remoteState.toJson());
            } catch (e) {
              debugPrint('AiValidationCreditsService: erreur écriture Hive après réconciliation: $e');
            }
            notifyListeners();
          } else {
            // Local plus récent (ou même timestamp) → upsert local vers Supabase.
            _upsertFireAndForget(userId, localState);
          }
        } else {
          // Aucune ligne en base → upsert local pour créer la ligne.
          _upsertFireAndForget(userId, localState);
        }
      }
    }

    // Étape d : fetch entitlement premium serveur-autoritaire (best-effort),
    // INDÉPENDANT du résultat du fetch crédits ci-dessus. L'entitlement premium
    // vit dans une table séparée (premium_subscriptions) pilotée par le webhook
    // Stripe — un échec du fetch crédits ne doit pas empêcher sa lecture.
    await _fetchAndApplyPremiumEntitlement(userId);
  }

  /// Vide le state en mémoire au logout (sans purger Hive).
  /// Les données restent en Hive isolées par userId.
  void reset() {
    _userId = null;
    _state = AiValidationState.empty();
    notifyListeners();
  }

  // ---- Mutations ----

  /// Accorde le bonus d'onboarding (5 crédits, une seule fois).
  ///
  /// No-op si [onboardingGranted] est déjà true.
  /// Plafond [kFreeWalletCap] respecté.
  Future<void> grantOnboarding() async {
    if (_state.onboardingGranted) return;

    final ajout = _creditsDisponibles(kOnboardingGrant);
    _state = _state.copyWith(
      balance: _state.balance + ajout,
      onboardingGranted: true,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist();
    notifyListeners();
    _upsertFireAndForgetCurrentState();
  }

  /// Accorde le crédit quotidien si dû à la date [now].
  ///
  /// Idempotent : sans effet si un octroi a déjà eu lieu aujourd'hui
  /// (comparaison sur la DATE LOCALE, pas l'heure).
  /// Sans effet si [balance] >= [kFreeWalletCap].
  Future<void> grantDailyIfDue(DateTime now) async {
    if (_state.balance >= kFreeWalletCap) return;

    final dernierOctroi = _state.lastDailyGrant;
    final dateNow = _dateLocale(now);

    // Si un octroi a déjà eu lieu aujourd'hui (ou dans le futur) → idempotent.
    if (dernierOctroi != null &&
        !_dateLocale(dernierOctroi).isBefore(dateNow)) {
      return;
    }

    final ajout = _creditsDisponibles(kDailyGrant);
    _state = _state.copyWith(
      balance: _state.balance + ajout,
      lastDailyGrant: now,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist();
    notifyListeners();
    _upsertFireAndForgetCurrentState();
  }

  /// Récompense un palier de série si [streakDays] est un multiple de
  /// [kStreakMilestoneInterval] non encore récompensé.
  ///
  /// Un palier donné n'est récompensé qu'une seule fois.
  /// Plafond [kFreeWalletCap] respecté.
  Future<void> earnFromStreak(int streakDays) async {
    if (streakDays <= 0) return;
    if (streakDays % kStreakMilestoneInterval != 0) return;
    if (streakDays <= _state.lastRewardedStreakMilestone) return;

    final ajout = _creditsDisponibles(kStreakMilestoneGrant);
    _state = _state.copyWith(
      balance: _state.balance + ajout,
      lastRewardedStreakMilestone: streakDays,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist();
    notifyListeners();
    _upsertFireAndForgetCurrentState();
  }

  /// Indique si l'utilisateur peut lancer une validation IA.
  ///
  /// Retourne true si premium (balance ignorée) OU si balance > 0.
  bool canValidateWithAI() => _state.isPremium || _state.balance > 0;

  /// Consomme un crédit pour une validation IA.
  ///
  /// - Si premium : retourne true SANS décrémenter le solde.
  /// - Si balance > 0 : décrémente de 1 et retourne true.
  /// - Si balance == 0 et non premium : retourne false.
  Future<bool> consumeForValidation() async {
    if (_state.isPremium) return true;

    if (_state.balance <= 0) return false;

    _state = _state.copyWith(
      balance: _state.balance - 1,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist();
    notifyListeners();
    _upsertFireAndForgetCurrentState();
    return true;
  }

  /// Rembourse un crédit consommé suite à une erreur TECHNIQUE de l'IA.
  ///
  /// À appeler UNIQUEMENT quand l'appel IA a échoué pour une raison technique
  /// (réseau, timeout, code HTTP 5xx, 529 Anthropic) — PAS quand le score est
  /// simplement inférieur au seuil (dans ce cas, le crédit est consommé car
  /// l'IA a bien travaillé).
  ///
  /// - Si premium : no-op (le premium ne consomme jamais de crédit).
  /// - Plafond [kFreeWalletCap] respecté (ne dépasse jamais le cap).
  Future<void> refundValidation() async {
    // Le premium ne consomme pas → pas de remboursement à effectuer.
    if (_state.isPremium) return;

    final ajout = _creditsDisponibles(1);
    if (ajout == 0) return; // déjà au cap ou au-delà.

    _state = _state.copyWith(
      balance: _state.balance + ajout,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persist();
    notifyListeners();
    _upsertFireAndForgetCurrentState();
  }

  /// Exécute un appel de validation IA [aiCall] sous gating de crédits.
  ///
  /// C'est le point d'entrée unique du gating, appelé par la page de
  /// validation pour TOUT type de preuve (photo, vidéo, texte).
  ///
  /// Décision AVANT l'appel :
  /// - 0 jeton et non premium → retourne null SANS appeler l'IA (route manuelle).
  /// - Premium → appelle l'IA sans rien consommer.
  /// - Non premium avec solde → consomme 1 crédit AVANT l'appel.
  ///
  /// Après l'appel :
  /// - Succès (même si le score est sous le seuil) → retourne le résultat ;
  ///   le crédit reste consommé (l'IA a travaillé, le jeton paie l'analyse).
  /// - Erreur TECHNIQUE (l'appel lève : réseau, timeout, 5xx, 529) → rembourse
  ///   le crédit (si non premium) et retourne null.
  ///
  /// Retour null = « IA non effectuée → basculer en validation manuelle ».
  /// L'utilisateur n'est jamais bloqué : la validation directe reste possible.
  Future<T?> runGatedValidation<T>(Future<T> Function() aiCall) async {
    if (!canValidateWithAI()) return null;

    final premium = isPremium;
    if (!premium) {
      await consumeForValidation();
    }
    try {
      return await aiCall();
    } catch (e) {
      debugPrint(
          'AiValidationCreditsService: erreur technique IA, remboursement: $e');
      if (!premium) {
        await refundValidation();
      }
      return null;
    }
  }

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
  Future<void> startPremiumCheckout({
    SupabaseClient? supabaseClient,
    Future<String?> Function()? checkoutUrlProvider,
  }) async {
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
  /// Effectue un poll court (3 tentatives espacées de 2 s) car le webhook Stripe
  /// est asynchrone — l'entitlement peut ne pas être encore à jour immédiatement.
  Future<void> onAppResumedAfterCheckout() async {
    if (!_checkoutInitiated) return;
    _checkoutInitiated = false;

    // Poll : jusqu'à 3 tentatives espacées de 2 secondes.
    const maxTentatives = 3;
    const delai = Duration(seconds: 2);

    for (var i = 0; i < maxTentatives; i++) {
      await refreshEntitlement();
      if (_state.isPremium) return; // succès : premium confirmé
      if (i < maxTentatives - 1) {
        await Future<void>.delayed(delai);
      }
    }
    // Dernier refresh même si toujours non premium (peut arriver si le webhook est lent).
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
    // Note : isPremium / premiumUntil ne sont PAS envoyés vers Supabase (Phase 2).
    // L'upsert ci-dessous synchronise uniquement les champs serveur (balance, etc.)
    // depuis l'état courant, via toSupabaseMap qui exclut ces champs.
    _upsertFireAndForgetCurrentState();
  }

  // ---- Helpers privés ----

  /// Fetche l'entitlement premium depuis Supabase et l'applique à l'état local.
  ///
  /// Best-effort : en cas d'erreur réseau, on garde l'état courant sans crash.
  /// Le fetch est séparé de la réconciliation LWW des crédits pour ne pas
  /// perturber la logique last-write-wins (tables distinctes, workflows distincts).
  ///
  /// IMPORTANT : cet appel met à jour [isPremium] et [premiumUntil] via [_setPremiumFromEntitlement]
  /// qui appelle [_persist] + [notifyListeners] mais PAS [_upsertFireAndForget] pour éviter
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
  /// Contrairement à [setPremium] (qui appelle [_upsertFireAndForgetCurrentState]),
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

  /// Calcule combien de crédits peuvent être ajoutés sans dépasser le cap.
  int _creditsDisponibles(int demande) {
    final place = kFreeWalletCap - _state.balance;
    if (place <= 0) return 0;
    return demande < place ? demande : place;
  }

  /// Réduit un DateTime à sa date locale (sans heure) pour les comparaisons.
  DateTime _dateLocale(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Persiste l'état courant dans Hive. No-op si userId inconnu.
  Future<void> _persist() async {
    final key = _hiveKey;
    if (key == null) return;
    await _box.put(key, _state.toJson());
  }

  /// Upsert fire-and-forget de l'état courant vers Supabase.
  /// N'attend pas le résultat, ne bloque pas l'UI.
  void _upsertFireAndForgetCurrentState() {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    _upsertFireAndForget(uid, _state);
  }

  /// Upsert fire-and-forget d'un état [state] vers Supabase.
  /// Encadré dans un try/catch : une erreur ne crashe jamais l'UI.
  void _upsertFireAndForget(String userId, AiValidationState state) {
    final repo = _repo;
    if (repo == null) return;
    // upsertForUser est déjà best-effort avec try/catch interne.
    unawaited(repo.upsertForUser(userId, state));
  }

  /// Appelé lors d'un signIn détecté via le stream [onSignedIn].
  /// L'ordre CRITIQUE est : load → grantOnboarding → grantDailyIfDue.
  /// Ce tri garantit qu'un [onboardingGranted=true] récupéré du serveur
  /// empêche le re-don des 5 jetons après réinstallation.
  ///
  /// Le uid est résolu via [_currentUserId] : le stream onSignedIn est un
  /// `Stream<void>` (pas de payload), et [_userId] n'est pas encore positionné
  /// au premier signIn (il l'est par [load], appelé juste après).
  Future<void> _onSignedIn() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;
    await load(uid);
    await grantOnboarding();
    await grantDailyIfDue(DateTime.now());
  }
}
