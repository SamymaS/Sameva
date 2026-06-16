import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../data/models/ai_validation_state_model.dart';

/// Service gérant le portefeuille de crédits IA (validation freemium).
///
/// Ce service est la SOURCE DE VÉRITÉ UNIQUE pour l'état du portefeuille.
/// Toute lecture et mutation passe par lui ; jamais directement depuis l'UI.
///
/// Stockage : boîte Hive 'aiValidation', clé 'ai_validation_<userId>'.
/// Pattern identique à la boîte 'cats' de [CatViewModel].
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

  /// Identifiant de l'utilisateur courant.
  /// Injecté au chargement via [load] ou en test via le constructeur.
  String? _userId;

  /// État courant du portefeuille.
  AiValidationState _state = AiValidationState.empty();

  AiValidationCreditsService(this._box);

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

  // ---- Clé Hive ----

  /// Clé Hive isolée par userId. Retourne null si userId inconnu → no-op.
  String? get _hiveKey {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;
    return 'ai_validation_$uid';
  }

  // ---- Chargement ----

  /// Charge l'état depuis Hive pour l'utilisateur [userId].
  /// Doit être appelé au démarrage de la session (login ou boot si session persistée).
  Future<void> load(String userId) async {
    _userId = userId;
    final key = _hiveKey;
    if (key == null) return;

    try {
      final raw = _box.get(key);
      if (raw != null) {
        _state = AiValidationState.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
      } else {
        _state = AiValidationState.empty();
      }
    } catch (e) {
      debugPrint('AiValidationCreditsService: erreur chargement: $e');
      _state = AiValidationState.empty();
    }
    notifyListeners();
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
    return true;
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
}
