import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_validation_state_model.dart';

/// Accès aux crédits IA du joueur dans Supabase (table `ai_validation_credits`).
///
/// Ce repository ne touche PAS Hive : la persistance locale reste dans
/// [AiValidationCreditsService]. Toutes les opérations Supabase sont
/// best-effort (sauf [fetchForUser] qui propage les exceptions réseau pour
/// permettre à l'appelant de distinguer « pas de ligne » vs « hors-ligne »).
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

  // ---- Sérialisation Supabase ----

  /// Construit la map à envoyer à Supabase depuis un [AiValidationState].
  ///
  /// N'inclut que les colonnes existantes côté serveur.
  /// Les champs [isPremium] et [premiumUntil] sont intentionnellement absents.
  static Map<String, dynamic> toSupabaseMap(
    AiValidationState state,
    String userId,
  ) {
    return {
      'user_id': userId,
      'balance': state.balance,
      'last_daily_grant': state.lastDailyGrant?.toUtc().toIso8601String(),
      'onboarding_granted': state.onboardingGranted,
      'last_rewarded_streak_milestone': state.lastRewardedStreakMilestone,
      'updated_at': state.updatedAt.toUtc().toIso8601String(),
    };
  }

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

  // ---- Écriture ----

  /// Crée ou met à jour la ligne de crédits IA dans Supabase (best-effort).
  ///
  /// En cas d'erreur réseau : log via debugPrint, ne propage pas.
  /// L'appelant continue avec l'état local Hive comme source de vérité.
  Future<void> upsertForUser(String userId, AiValidationState state) async {
    try {
      await _supabase
          .from('ai_validation_credits')
          .upsert(
            toSupabaseMap(state, userId),
            onConflict: 'user_id',
          );
    } catch (e) {
      debugPrint('AiCreditsRepository: erreur upsertForUser $userId: $e');
    }
  }
}
