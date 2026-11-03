import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_validation_state_model.dart';

/// Lecture de l'énergie de l'Oracle (table `ai_validation_credits`).
///
/// Sprint 1 : lecture seule. L'énergie est accordée par `claim_daily` et
/// consommée par l'Edge Function Oracle ; le client ne l'écrit plus jamais.
///
/// MAPPING CRITIQUE — colonnes réelles de la table `ai_validation_credits` :
///   user_id (uuid PK), balance (int), last_daily_grant (timestamptz nullable),
///   onboarding_granted (bool), last_rewarded_streak_milestone (int), updated_at (timestamptz).
///
/// Les champs [isPremium] et [premiumUntil] de [AiValidationState] sont
/// locaux uniquement (Phase 2). Ils ne sont JAMAIS lus ni écrits vers Supabase.
class AiCreditsRepository {
  final SupabaseClient _supabase;

  AiCreditsRepository(this._supabase);

  // ---- Lecture Supabase ----

  /// Construit un [AiValidationState] depuis une ligne Supabase.
  ///
  /// Les champs [isPremium] et [premiumUntil] n'existent pas en base :
  /// ils sont toujours ramenés à leurs valeurs par défaut (false / null).
  static AiValidationState fromSupabaseMap(Map<String, dynamic> map) {
    return AiValidationState(
      balance: map['balance'] as int? ?? 0,
      lastDailyGrant: map['last_daily_grant'] != null
          ? DateTime.parse(map['last_daily_grant'] as String)
          : null,
      onboardingGranted: map['onboarding_granted'] as bool? ?? false,
      lastRewardedStreakMilestone:
          map['last_rewarded_streak_milestone'] as int? ?? 0,
      // isPremium et premiumUntil : valeurs par défaut, non stockées côté serveur.
      isPremium: false,
      premiumUntil: null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now().toUtc(),
    );
  }

  // ---- Lecture ----

  /// Récupère l'état des crédits IA depuis Supabase pour l'utilisateur [userId].
  ///
  /// Comportements :
  /// - Ligne trouvée → retourne l'[AiValidationState] désérialisé.
  /// - Aucune ligne (vrai nouveau utilisateur) → retourne null EXPLICITEMENT.
  /// - Erreur réseau / exception Supabase → PROPAGE l'exception.
  ///   L'appelant doit encadrer dans un try/catch pour distinguer l'absence
  ///   de données d'une erreur réseau (même pattern que [PlayerRepository.fetchRemoteStats]).
  Future<AiValidationState?> fetchForUser(String userId) async {
    // Pas de try/catch ici : on laisse remonter toute exception réseau.
    final response = await _supabase
        .from('ai_validation_credits')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // null = requête réussie mais aucune ligne → nouvel utilisateur.
    if (response == null) return null;
    return fromSupabaseMap(Map<String, dynamic>.from(response as Map));
  }
}
