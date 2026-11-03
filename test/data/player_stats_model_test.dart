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

  group('PlayerStats Supabase', () {
    test('fromSupabaseMap lit snake_case et défauts', () {
      final s = PlayerStats.fromSupabaseMap({
        'level': 3,
        'experience': 50,
        'gold': 200,
        'crystals': 5,
        'health_points': 90,
        'max_health_points': 120,
        'credibility_score': 0.8,
        'moral': 0.5,
        'streak': 7,
        'max_streak': 14,
        'last_active_date': '2024-06-01T12:00:00.000Z',
        'achievements': {'quest_10': 1},
        'total_quests_completed': 99,
      });

      expect(s.level, 3);
      expect(s.experience, 50);
      expect(s.gold, 200);
      expect(s.crystals, 5);
      expect(s.healthPoints, 90);
      expect(s.maxHealthPoints, 120);
      expect(s.credibilityScore, 0.8);
      expect(s.moral, 0.5);
      expect(s.streak, 7);
      expect(s.maxStreak, 14);
      expect(s.lastActiveDate, DateTime.parse('2024-06-01T12:00:00.000Z'));
      expect(s.achievements, {'quest_10': 1});
      expect(s.totalQuestsCompleted, 99);
    });

    test('fromSupabaseMap lit les champs serveur du Sprint 1', () {
      final s = PlayerStats.fromSupabaseMap({
        'level': 3,
        'experience': 20,
        'gold': 120,
        'crystals': 4,
        'seals': 7,
        'stardust': 2,
        'total_experience': 470,
        'is_exhausted': true,
        'moral': 0.9,
        'credibility_score': 0.8,
      });
      expect(s.seals, 7);
      expect(s.stardust, 2);
      expect(s.totalExperience, 470);
      expect(s.isExhausted, isTrue);
      expect(s.moral, closeTo(0.9, 1e-9));
    });

    test('toJson / fromJson conserve les champs serveur (cache Hive)', () {
      final s = PlayerStats(seals: 3, totalExperience: 99, isExhausted: true, stardust: 1);
      final back = PlayerStats.fromJson(s.toJson());
      expect(back.seals, 3);
      expect(back.totalExperience, 99);
      expect(back.isExhausted, isTrue);
      expect(back.stardust, 1);
    });
  });
}

