import 'package:sameva/data/models/quest_model.dart';

/// Quête minimale avec [createdAt] fixe pour des tests de timing déterministes.
Quest buildTestQuest({
  DateTime? createdAt,
  int estimatedDurationMinutes = 60,
  int difficulty = 2,
  DateTime? deadline,
  String userId = 'user-test',
}) {
  final t0 = createdAt ?? DateTime.utc(2024, 6, 1, 12, 0);
  return Quest(
    userId: userId,
    title: 'Quête test',
    estimatedDurationMinutes: estimatedDurationMinutes,
    frequency: QuestFrequency.oneOff,
    difficulty: difficulty,
    category: 'Autre',
    rarity: QuestRarity.common,
    status: QuestStatus.active,
    createdAt: t0,
    deadline: deadline,
  );
}
