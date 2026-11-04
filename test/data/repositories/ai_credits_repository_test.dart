import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

void main() {
  test('le repository se construit (lecture seule depuis le Sprint 1)', () {
    expect(AiCreditsRepository(_MockSupabaseClient()), isNotNull);
  });

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
}
