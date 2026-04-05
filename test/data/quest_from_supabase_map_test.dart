import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/cat_model.dart';
import 'package:sameva/data/models/quest_model.dart';

void main() {
  group('Quest.fromSupabaseMap', () {
    test('parse une ligne Supabase minimale complète', () {
      final q = Quest.fromSupabaseMap({
        'user_id': 'user-1',
        'title': 'Ma quête',
        'difficulty': 2,
        'category': 'Sport',
        'frequency': 'daily',
        'rarity': 'rare',
        'status': 'active',
        'estimated_duration_minutes': 45,
        'sub_quests': <String>[],
        'created_at': '2024-06-15T10:00:00.000Z',
      });

      expect(q.userId, 'user-1');
      expect(q.title, 'Ma quête');
      expect(q.difficulty, 2);
      expect(q.frequency, QuestFrequency.daily);
      expect(q.rarity, QuestRarity.rare);
      expect(q.status, QuestStatus.active);
      expect(q.estimatedDurationMinutes, 45);
      expect(q.validationType, ValidationType.manual);
    });

    test('applique les défauts si champs optionnels absents', () {
      final q = Quest.fromSupabaseMap({
        'user_id': 'u',
        'title': 'T',
        'difficulty': 1,
        'category': 'Autre',
        'frequency': 'one_off',
        'rarity': 'common',
        'status': 'completed',
      });

      expect(q.estimatedDurationMinutes, 0);
      expect(q.description, isNull);
      expect(q.completedAt, isNull);
    });

    test('parse les dates ISO8601', () {
      final q = Quest.fromSupabaseMap({
        'user_id': 'u',
        'title': 'T',
        'difficulty': 1,
        'category': 'Autre',
        'frequency': 'one_off',
        'rarity': 'common',
        'status': 'completed',
        'created_at': '2023-01-01T08:00:00.000Z',
        'completed_at': '2023-01-02T12:00:00.000Z',
        'deadline': '2023-01-03T18:00:00.000Z',
      });

      expect(q.createdAt.toUtc().year, 2023);
      expect(q.completedAt?.toUtc().day, 2);
      expect(q.deadline?.toUtc().day, 3);
    });
  });

  group('CatStats', () {
    test('toJson fromJson aller-retour', () {
      final c = CatStats(
        id: 'id1',
        name: 'Minou',
        race: 'michi',
        rarity: 'epic',
        isMain: true,
        obtainedAt: DateTime.utc(2025, 3, 1, 12),
      );

      final back = CatStats.fromJson(c.toJson());

      expect(back.id, c.id);
      expect(back.name, c.name);
      expect(back.race, c.race);
      expect(back.rarity, c.rarity);
      expect(back.isMain, c.isMain);
      expect(back.obtainedAt, c.obtainedAt);
    });
  });
}
