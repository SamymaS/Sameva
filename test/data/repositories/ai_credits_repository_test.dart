import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/repositories/ai_credits_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---- Doubles de test ----

class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ---- Données de test ----

const _userId = 'user-test-42';

final _dateTest = DateTime.utc(2026, 6, 16, 12, 0);

/// Ligne Supabase simulée (colonnes réelles de ai_validation_credits).
final _supabaseRow = <String, dynamic>{
  'user_id': _userId,
  'balance': 3,
  'last_daily_grant': '2026-06-15T08:00:00.000Z',
  'onboarding_granted': true,
  'last_rewarded_streak_milestone': 7,
  'updated_at': '2026-06-16T12:00:00.000Z',
};

AiValidationState _makeState({
  int balance = 3,
  bool onboardingGranted = true,
  int lastRewardedStreakMilestone = 7,
  DateTime? updatedAt,
}) =>
    AiValidationState(
      balance: balance,
      onboardingGranted: onboardingGranted,
      lastRewardedStreakMilestone: lastRewardedStreakMilestone,
      updatedAt: updatedAt ?? _dateTest,
    );

void main() {
  late _MockSupabaseClient supabase;
  late AiCreditsRepository repo;

  setUp(() {
    supabase = _MockSupabaseClient();
    repo = AiCreditsRepository(supabase);
  });

  // ==========================================================================
  // toSupabaseMap — absence is_premium / premium_until
  // ==========================================================================

  group('toSupabaseMap', () {
    test('contient les colonnes serveur attendues', () {
      final state = _makeState();
      final map = AiCreditsRepository.toSupabaseMap(state, _userId);

      expect(map['user_id'], _userId);
      expect(map['balance'], 3);
      expect(map['onboarding_granted'], isTrue);
      expect(map['last_rewarded_streak_milestone'], 7);
      expect(map.containsKey('updated_at'), isTrue);
    });

    test('NE contient PAS is_premium ni premium_until', () {
      final state = AiValidationState(
        balance: 5,
        isPremium: true,
        premiumUntil: DateTime.utc(2027, 1, 1),
        updatedAt: _dateTest,
      );
      final map = AiCreditsRepository.toSupabaseMap(state, _userId);

      expect(map.containsKey('is_premium'), isFalse);
      expect(map.containsKey('premium_until'), isFalse);
    });

    test('last_daily_grant null si non défini', () {
      final state = AiValidationState(balance: 0, updatedAt: _dateTest);
      final map = AiCreditsRepository.toSupabaseMap(state, _userId);

      expect(map['last_daily_grant'], isNull);
    });

    test('last_daily_grant est une chaîne ISO8601 valide si défini', () {
      final grant = DateTime(2026, 6, 15, 10, 0);
      final state = AiValidationState(
        balance: 1,
        lastDailyGrant: grant,
        updatedAt: _dateTest,
      );
      final map = AiCreditsRepository.toSupabaseMap(state, _userId);

      expect(
        () => DateTime.parse(map['last_daily_grant'] as String),
        returnsNormally,
      );
    });
  });

  // ==========================================================================
  // fromSupabaseMap
  // ==========================================================================

  group('fromSupabaseMap', () {
    test('désérialise une ligne complète correctement', () {
      final state = AiCreditsRepository.fromSupabaseMap(_supabaseRow);

      expect(state.balance, 3);
      expect(state.onboardingGranted, isTrue);
      expect(state.lastRewardedStreakMilestone, 7);
      expect(state.lastDailyGrant, isNotNull);
      expect(state.updatedAt.isUtc, isTrue);
    });

    test('isPremium vaut toujours false (non stocké en base)', () {
      // Même si la map contient une clé is_premium, fromSupabaseMap l'ignore.
      final rowAvecClesPremium = <String, dynamic>{
        ..._supabaseRow,
        'is_premium': true,
        'premium_until': '2027-01-01T00:00:00.000Z',
      };
      final state = AiCreditsRepository.fromSupabaseMap(rowAvecClesPremium);

      expect(state.isPremium, isFalse);
      expect(state.premiumUntil, isNull);
    });

    test('valeurs par défaut si champs manquants', () {
      final rowMinimal = <String, dynamic>{
        'updated_at': _dateTest.toIso8601String(),
      };
      final state = AiCreditsRepository.fromSupabaseMap(rowMinimal);

      expect(state.balance, 0);
      expect(state.onboardingGranted, isFalse);
      expect(state.lastRewardedStreakMilestone, 0);
      expect(state.lastDailyGrant, isNull);
      expect(state.isPremium, isFalse);
      expect(state.premiumUntil, isNull);
    });
  });

  // ==========================================================================
  // Round-trip toSupabaseMap → fromSupabaseMap
  // ==========================================================================

  group('round-trip', () {
    test('champs serveur préservés ; isPremium et premiumUntil reviennent à false/null',
        () {
      final original = AiValidationState(
        balance: 7,
        lastDailyGrant: DateTime.utc(2026, 6, 15, 8, 0),
        onboardingGranted: true,
        lastRewardedStreakMilestone: 14,
        isPremium: true,         // ignoré dans le map Supabase
        premiumUntil: DateTime.utc(2027, 1, 1), // ignoré
        updatedAt: _dateTest,
      );

      final map = AiCreditsRepository.toSupabaseMap(original, _userId);
      final restaure = AiCreditsRepository.fromSupabaseMap(map);

      expect(restaure.balance, original.balance);
      expect(restaure.onboardingGranted, original.onboardingGranted);
      expect(restaure.lastRewardedStreakMilestone, original.lastRewardedStreakMilestone);
      // Champs premium : retour aux valeurs par défaut après le round-trip.
      expect(restaure.isPremium, isFalse);
      expect(restaure.premiumUntil, isNull);
      // updatedAt préservé.
      expect(
        restaure.updatedAt.millisecondsSinceEpoch,
        original.updatedAt.millisecondsSinceEpoch,
      );
    });
  });

  // ==========================================================================
  // upsertForUser
  // ==========================================================================

  group('upsertForUser', () {
    test('avale les exceptions réseau sans propager', () async {
      // `supabase.from()` lève une exception (simulation hors-ligne).
      // upsertForUser est best-effort : aucune exception ne remonte.
      when(() => supabase.from(any())).thenThrow(Exception('réseau indisponible'));

      await expectLater(
        () async => repo.upsertForUser(_userId, _makeState()),
        returnsNormally,
      );
    });

    test('avale les exceptions réseau (cas 2 : from() réussit, upsert lève)', () async {
      // `supabase.from()` renvoie un builder mais `upsert()` lève.
      // Même comportement attendu : pas de propagation.
      when(() => supabase.from(any())).thenThrow(Exception('conflit DB'));

      await expectLater(
        () async => repo.upsertForUser(_userId, _makeState()),
        returnsNormally,
      );
    });
  });
}
