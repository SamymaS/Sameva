import 'package:supabase_flutter/supabase_flutter.dart';

/// Résultat d'un fetch de l'entitlement premium depuis Supabase.
///
/// [isPremium] est TOUJOURS piloté par la colonne `is_premium` de la table
/// `premium_subscriptions`, indépendamment de [premiumUntil].
/// Un [premiumUntil] null ne force jamais [isPremium] à false — le webhook Stripe
/// peut poser `is_premium=true` avant que `premium_until` ne soit mis à jour.
class PremiumEntitlement {
  /// Statut premium lu depuis la colonne `is_premium` (lecture directe, sans déduction).
  final bool isPremium;

  /// Date d'expiration de l'abonnement (null si non fournie ou pas de premium).
  final DateTime? premiumUntil;

  const PremiumEntitlement({
    required this.isPremium,
    this.premiumUntil,
  });

  /// Entitlement par défaut : pas de premium (aucune ligne en base ou hors-ligne).
  const PremiumEntitlement.libre()
      : isPremium = false,
        premiumUntil = null;
}

/// Accès à la table `premium_subscriptions` dans Supabase (lecture seule).
///
/// La table a une RLS "lecture seule pour authenticated" :
///   user_id PK, is_premium, premium_until, stripe_customer_id,
///   stripe_subscription_id, updated_at.
///
/// Pattern identique à [AiCreditsRepository] : best-effort, pas de crash réseau.
class PremiumSubscriptionRepository {
  final SupabaseClient _supabase;

  PremiumSubscriptionRepository(this._supabase);

  /// Récupère l'entitlement premium de l'utilisateur [userId] depuis Supabase.
  ///
  /// Comportements :
  /// - Ligne trouvée → retourne [PremiumEntitlement] avec [isPremium] = `is_premium`
  ///   (colonne directe) et [premiumUntil] = `premium_until` (peut être null).
  /// - Aucune ligne (nouvel abonnement non encore créé) → [PremiumEntitlement.libre()].
  /// - Erreur réseau / exception Supabase → PROPAGE l'exception.
  ///   L'appelant doit encadrer dans un try/catch (offline-first : on conserve l'état courant).
  ///
  /// RÈGLE CRITIQUE : [isPremium] = `row.is_premium` DIRECTEMENT.
  /// On ne déduit JAMAIS [isPremium] depuis [premiumUntil] — le webhook Stripe pose
  /// `is_premium=true` dès le checkout, `premium_until` peut arriver 1-2 s plus tard.
  Future<PremiumEntitlement> fetchForUser(String userId) async {
    // Pas de try/catch ici : on laisse remonter les exceptions réseau.
    // L'appelant (AiValidationCreditsService) les traite en best-effort.
    final response = await _supabase
        .from('premium_subscriptions')
        .select('is_premium, premium_until')
        .eq('user_id', userId)
        .maybeSingle();

    // null = requête réussie mais aucune ligne → pas d'abonnement.
    if (response == null) return const PremiumEntitlement.libre();

    final row = Map<String, dynamic>.from(response as Map);

    // is_premium est lu DIRECTEMENT depuis la colonne — pas de déduction.
    final isPremium = row['is_premium'] as bool? ?? false;

    // premium_until peut être null même quand is_premium=true (délai webhook).
    final premiumUntilRaw = row['premium_until'] as String?;
    final premiumUntil =
        premiumUntilRaw != null ? DateTime.parse(premiumUntilRaw) : null;

    return PremiumEntitlement(
      isPremium: isPremium,
      premiumUntil: premiumUntil,
    );
  }
}
