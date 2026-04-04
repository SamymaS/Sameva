import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/domain/services/quest_rewards_calculator.dart';

import '../helpers/quest_test_factory.dart';

void main() {
  group('QuestRewardsCalculator', () {
    group('calculateBaseRewards', () {
      test('devrait calculer XP et or proportionnels à la difficulté', () {
        final r = QuestRewardsCalculator.calculateBaseRewards(2);
        expect(r.experience, 20);
        expect(r.gold, 50);
        expect(r.crystals, 0);
      });

      test('devrait accorder 1 cristal si difficulté > 3', () {
        final r = QuestRewardsCalculator.calculateBaseRewards(4);
        expect(r.crystals, 1);
      });

      test('ne devrait pas accorder de cristal pour difficulté 3', () {
        final r = QuestRewardsCalculator.calculateBaseRewards(3);
        expect(r.crystals, 0);
      });
    });

    group('calculateRewardsWithTiming', () {
      final base = DateTime.utc(2024, 6, 1, 12, 0);
      final quest = buildTestQuest(createdAt: base, estimatedDurationMinutes: 60);

      test('devrait appliquer le bonus "early" si fini avant 80% du temps estimé',
          () {
        final completed = base.add(const Duration(minutes: 30));
        final r = QuestRewardsCalculator.calculateRewardsWithTiming(
          quest,
          completed,
        );
        expect(r.bonusType, 'early');
        expect(r.multiplier, 1.25);
        expect(r.experience, greaterThan(0));
        expect(r.gold, greaterThan(0));
      });

      test('devrait appliquer le bonus "on_time" si dans les temps', () {
        final completed = base.add(const Duration(minutes: 55));
        final r = QuestRewardsCalculator.calculateRewardsWithTiming(
          quest,
          completed,
        );
        expect(r.bonusType, 'on_time');
        expect(r.multiplier, 1.1);
      });

      test('devrait appliquer le malus "late" après l\'échéance estimée', () {
        final completed = base.add(const Duration(minutes: 61));
        final r = QuestRewardsCalculator.calculateRewardsWithTiming(
          quest,
          completed,
        );
        expect(r.bonusType, 'late');
        expect(r.multiplier, 0.8);
      });

      test('devrait utiliser la deadline explicite plutôt que durée estimée',
          () {
        final deadline = base.add(const Duration(minutes: 30));
        final q = buildTestQuest(
          createdAt: base,
          estimatedDurationMinutes: 120,
          deadline: deadline,
        );
        final completed = base.add(const Duration(minutes: 25));
        final r = QuestRewardsCalculator.calculateRewardsWithTiming(q, completed);
        expect(r.bonusType, 'early');
      });

      test('devrait ajouter le bonus de série au multiplicateur', () {
        final completed = base.add(const Duration(minutes: 30));
        final r = QuestRewardsCalculator.calculateRewardsWithTiming(
          quest,
          completed,
          hasStreakBonus: true,
        );
        expect(r.multiplier, closeTo(1.35, 0.001));
      });

      test('devrait appliquer les pourcentages bonus XP et or', () {
        final completed = base.add(const Duration(minutes: 30));
        final sansBonus = QuestRewardsCalculator.calculateRewardsWithTiming(
          quest,
          completed,
        );
        final avecBonus = QuestRewardsCalculator.calculateRewardsWithTiming(
          quest,
          completed,
          xpBonusPercent: 50,
          goldBonusPercent: 20,
        );
        expect(avecBonus.experience, greaterThan(sansBonus.experience));
        expect(avecBonus.gold, greaterThan(sansBonus.gold));
      });
    });

    group('calculateFailurePenalty', () {
      test('devrait retirer 10% de l\'XP actuelle et marquer failed', () {
        final quest = buildTestQuest();
        final r = QuestRewardsCalculator.calculateFailurePenalty(quest, 200);
        expect(r.experience, -20);
        expect(r.gold, 0);
        expect(r.bonusType, 'failed');
        expect(r.moralPenalty, -0.5);
      });
    });

    group('QuestRewards', () {
      test('isPositive reflète XP et or non négatifs', () {
        expect(
          QuestRewards(experience: 1, gold: 1).isPositive,
          isTrue,
        );
        expect(
          QuestRewards(experience: -1, gold: 0).isPositive,
          isFalse,
        );
      });
    });
  });
}
