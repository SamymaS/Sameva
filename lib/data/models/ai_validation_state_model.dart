/// Modèle représentant l'état du portefeuille de crédits IA d'un utilisateur.
///
/// Stocké en JSON dans la boîte Hive 'aiValidation', avec la clé
/// 'ai_validation_<userId>' (même pattern que la boîte 'cats').
///
/// Ce modèle est immuable. Toute mutation passe par [copyWith] et
/// est persistée par [AiValidationCreditsService].
class AiValidationState {
  /// Nombre de crédits IA disponibles (portefeuille freemium).
  final int balance;

  /// Date du dernier octroi quotidien (null = jamais accordé).
  final DateTime? lastDailyGrant;

  /// Indique si le bonus d'onboarding a déjà été accordé.
  final bool onboardingGranted;

  /// Dernier palier de série récompensé (en jours).
  /// Ex. : 14 signifie que les paliers 7 et 14 ont été récompensés.
  /// Valeur par défaut : 0.
  final int lastRewardedStreakMilestone;

  /// Indique si l'utilisateur est en mode premium (accès illimité).
  final bool isPremium;

  /// Date d'expiration du premium (null = pas de premium actif).
  final DateTime? premiumUntil;

  /// Horodatage de la dernière mutation (UTC).
  final DateTime updatedAt;

  const AiValidationState({
    this.balance = 0,
    this.lastDailyGrant,
    this.onboardingGranted = false,
    this.lastRewardedStreakMilestone = 0,
    this.isPremium = false,
    this.premiumUntil,
    required this.updatedAt,
  });

  /// Constructeur par défaut pour un nouvel utilisateur.
  factory AiValidationState.empty() => AiValidationState(
        updatedAt: DateTime.now().toUtc(),
      );

  // ---- Sérialisation JSON (pour Hive) ----

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'lastDailyGrant': lastDailyGrant?.toIso8601String(),
        'onboardingGranted': onboardingGranted,
        'lastRewardedStreakMilestone': lastRewardedStreakMilestone,
        'isPremium': isPremium,
        'premiumUntil': premiumUntil?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiValidationState.fromJson(Map<String, dynamic> json) =>
      AiValidationState(
        balance: json['balance'] as int? ?? 0,
        lastDailyGrant: json['lastDailyGrant'] != null
            ? DateTime.parse(json['lastDailyGrant'] as String)
            : null,
        onboardingGranted: json['onboardingGranted'] as bool? ?? false,
        lastRewardedStreakMilestone:
            json['lastRewardedStreakMilestone'] as int? ?? 0,
        isPremium: json['isPremium'] as bool? ?? false,
        premiumUntil: json['premiumUntil'] != null
            ? DateTime.parse(json['premiumUntil'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now().toUtc(),
      );

  // ---- copyWith ----

  AiValidationState copyWith({
    int? balance,
    Object? lastDailyGrant = _sentinel,
    bool? onboardingGranted,
    int? lastRewardedStreakMilestone,
    bool? isPremium,
    Object? premiumUntil = _sentinel,
    DateTime? updatedAt,
  }) =>
      AiValidationState(
        balance: balance ?? this.balance,
        lastDailyGrant: lastDailyGrant == _sentinel
            ? this.lastDailyGrant
            : lastDailyGrant as DateTime?,
        onboardingGranted: onboardingGranted ?? this.onboardingGranted,
        lastRewardedStreakMilestone:
            lastRewardedStreakMilestone ?? this.lastRewardedStreakMilestone,
        isPremium: isPremium ?? this.isPremium,
        premiumUntil: premiumUntil == _sentinel
            ? this.premiumUntil
            : premiumUntil as DateTime?,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Sentinelle pour distinguer null explicite de "non fourni" dans copyWith.
const _sentinel = Object();
