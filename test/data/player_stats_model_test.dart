import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/player_stats_model.dart';

void main() {
  group('PlayerStats', () {
    test('devrait préserver les valeurs via toJson puis fromJson', () {
      final original = PlayerStats(
        level: 5,
        experience: 120,
        gold: 99,
        crystals: 2,
        healthPoints: 80,
        maxHealthPoints: 100,
        credibilityScore: 0.9,
        moral: 0.65,
        streak: 3,
        maxStreak: 10,
        lastActiveDate: DateTime.utc(2024, 1, 15),
        achievements: {'first_quest': 1},
        totalQuestsCompleted: 42,
        pityCount: 1,
      );

      final json = original.toJson();
      final restored = PlayerStats.fromJson(json);

      expect(restored.level, original.level);
      expect(restored.experience, original.experience);
      expect(restored.gold, original.gold);
      expect(restored.crystals, original.crystals);
      expect(restored.healthPoints, original.healthPoints);
      expect(restored.maxHealthPoints, original.maxHealthPoints);
      expect(restored.credibilityScore, original.credibilityScore);
      expect(restored.moral, original.moral);
      expect(restored.streak, original.streak);
      expect(restored.maxStreak, original.maxStreak);
      expect(restored.lastActiveDate, original.lastActiveDate);
      expect(restored.achievements, original.achievements);
      expect(restored.totalQuestsCompleted, original.totalQuestsCompleted);
      expect(restored.pityCount, original.pityCount);
    });

    test('devrait appliquer les défauts si champs absents du JSON', () {
      final s = PlayerStats.fromJson({});
      expect(s.level, 1);
      expect(s.experience, 0);
      expect(s.achievements, isEmpty);
    });
  });
}
