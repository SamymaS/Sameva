import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/quest_model.dart';

void main() {
  group('Quest toSupabaseMap / fromSupabaseMap', () {
    test('aller-retour préserve les champs principaux', () {
      final original = Quest(
        id: 'quest-uuid',
        userId: 'user-42',
        title: 'Courir 5 km',
        description: 'Footing matinal',
        estimatedDurationMinutes: 45,
        frequency: QuestFrequency.daily,
        difficulty: 3,
        category: 'Sport',
        rarity: QuestRarity.rare,
        subQuests: const ['chaussures', 'eau'],
        status: QuestStatus.active,
        createdAt: DateTime.utc(2024, 5, 10, 8, 30),
        deadline: DateTime.utc(2024, 5, 11, 20, 0),
        validationType: ValidationType.photo,
        xpReward: 100,
        goldReward: 50,
        proofData: 'uri:local',
      );

      final map = original.toSupabaseMap();
      final restored = Quest.fromSupabaseMap(map);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.estimatedDurationMinutes, original.estimatedDurationMinutes);
      expect(restored.frequency, original.frequency);
      expect(restored.difficulty, original.difficulty);
      expect(restored.category, original.category);
      expect(restored.rarity, original.rarity);
      expect(restored.subQuests, original.subQuests);
      expect(restored.status, original.status);
      expect(restored.validationType, original.validationType);
      expect(restored.xpReward, original.xpReward);
      expect(restored.goldReward, original.goldReward);
      expect(restored.proofData, original.proofData);
      expect(restored.deadline, original.deadline);
    });

    test('toSupabaseMap reflète is_completed selon le statut', () {
      final active = Quest(
        userId: 'u',
        title: 'A',
        estimatedDurationMinutes: 1,
        frequency: QuestFrequency.oneOff,
        difficulty: 1,
        category: 'Autre',
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      );
      final done = active.copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime.utc(2024, 1, 2),
      );

      expect(active.toSupabaseMap()['is_completed'], isFalse);
      expect(done.toSupabaseMap()['is_completed'], isTrue);
      expect(done.toSupabaseMap()['completed_at'], isNotNull);
    });
  });
}
