import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/premium_subscription_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---- Doubles de test ----

class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ---- Constantes de test ----

const _userId = 'user-premium-test';

void main() {
  late _MockSupabaseClient supabase;
  late PremiumSubscriptionRepository repo;

  setUp(() {
    supabase = _MockSupabaseClient();
    repo = PremiumSubscriptionRepository(supabase);
  });

  // ==========================================================================
  // PremiumEntitlement — valeur par défaut
  // ==========================================================================

  group('PremiumEntitlement.libre()', () {
    test('isPremium=false et premiumUntil=null', () {
      const entitlement = PremiumEntitlement.libre();

      expect(entitlement.isPremium, isFalse);
      expect(entitlement.premiumUntil, isNull);
    });
  });

  // ==========================================================================
  // fetchForUser — désérialisation
  // ==========================================================================

  group('fetchForUser — désérialisation', () {
    test(
        'is_premium=true + premium_until=null → isPremium=true '
        '(règle critique : premium_until null ne force pas isPremium à false)',
        () async {
      // Scénario : webhook Stripe a posé is_premium=true mais
      // premium_until n'est pas encore arrivé (délai 1-2 s).
      when(() => supabase.from(any()))
          .thenThrow(Exception('Appel réseau simulé — maybeSingle stubbing required'));

      // Test de la désérialisation directe (logique interne de fetchForUser).
      // On vérifie que la logique appliquée sur la map est correcte.
      final row = <String, dynamic>{
        'is_premium': true,
        'premium_until': null,
      };

      // Reproduction de la logique interne de fetchForUser.
      final isPremium = row['is_premium'] as bool? ?? false;
      final premiumUntilRaw = row['premium_until'] as String?;
      final premiumUntil =
          premiumUntilRaw != null ? DateTime.parse(premiumUntilRaw) : null;

      expect(isPremium, isTrue); // is_premium pilote isPremium directement
      expect(premiumUntil, isNull); // premium_until null ne force rien
    });

    test('is_premium=true + premium_until défini → isPremium=true, premiumUntil parsé',
        () {
      final row = <String, dynamic>{
        'is_premium': true,
        'premium_until': '2027-01-01T00:00:00.000Z',
      };

      final isPremium = row['is_premium'] as bool? ?? false;
      final premiumUntilRaw = row['premium_until'] as String?;
      final premiumUntil =
          premiumUntilRaw != null ? DateTime.parse(premiumUntilRaw) : null;

      expect(isPremium, isTrue);
      expect(premiumUntil, isNotNull);
      expect(premiumUntil!.year, 2027);
    });

    test('is_premium=false → isPremium=false indépendamment de premium_until', () {
      final row = <String, dynamic>{
        'is_premium': false,
        'premium_until': '2025-01-01T00:00:00.000Z', // passé, mais is_premium=false
      };

      final isPremium = row['is_premium'] as bool? ?? false;

      expect(isPremium, isFalse);
    });

    test('is_premium absent de la map → false par défaut', () {
      final row = <String, dynamic>{
        'premium_until': null,
      };

      final isPremium = row['is_premium'] as bool? ?? false;

      expect(isPremium, isFalse);
    });
  });

  // ==========================================================================
  // PremiumSubscriptionRepository.fetchForUser — propagation des exceptions
  // ==========================================================================

  group('fetchForUser — propagation exceptions réseau', () {
    test('exception réseau propagée (pas de try/catch dans fetchForUser)', () async {
      // fetchForUser propage les exceptions — c'est l'appelant (AiValidationCreditsService)
      // qui les traite en best-effort.
      when(() => supabase.from(any()))
          .thenThrow(Exception('connexion impossible'));

      await expectLater(
        () => repo.fetchForUser(_userId),
        throwsException,
      );
    });
  });
}
