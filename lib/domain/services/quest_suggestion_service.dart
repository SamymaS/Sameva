import '../../data/models/quest_model.dart';

/// Paramètres du joueur transmis à l'Edge Function suggest-quests.
class QuestSuggestionRequest {
  final int playerLevel;
  final int streak;
  final int totalQuestsCompleted;
  final String? favoriteCategory;

  const QuestSuggestionRequest({
    required this.playerLevel,
    required this.streak,
    required this.totalQuestsCompleted,
    this.favoriteCategory,
  });

  Map<String, dynamic> toJson() => {
        'player_level': playerLevel,
        'current_streak': streak,
        'total_quests_completed': totalQuestsCompleted,
        if (favoriteCategory != null) 'favorite_category': favoriteCategory,
      };
}

/// Service de suggestion de quêtes via IA.
/// Renvoie une liste de quêtes générées selon le profil du joueur.
abstract class QuestSuggestionService {
  Future<List<Quest>> suggestQuests({
    required String userId,
    required QuestSuggestionRequest request,
  });
}

/// Implémentation mock : retourne des quêtes plausibles sans appel réseau.
class MockQuestSuggestionService implements QuestSuggestionService {
  final Duration simulatedDelay;

  MockQuestSuggestionService({
    this.simulatedDelay = const Duration(seconds: 1),
  });

  @override
  Future<List<Quest>> suggestQuests({
    required String userId,
    required QuestSuggestionRequest request,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    return [
      Quest(
        userId: userId,
        title: 'Séance de sport matinale',
        description: 'Effectuez 30 minutes d\'activité physique avant 9h.',
        category: 'Sport',
        difficulty: (request.playerLevel ~/ 3).clamp(1, 4),
        estimatedDurationMinutes: 30,
        frequency: QuestFrequency.daily,
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      ),
      Quest(
        userId: userId,
        title: 'Lecture enrichissante',
        description: 'Lisez au moins 20 pages d\'un livre de votre choix.',
        category: 'Apprentissage',
        difficulty: 1,
        estimatedDurationMinutes: 25,
        frequency: QuestFrequency.daily,
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      ),
      Quest(
        userId: userId,
        title: 'Ranger et organiser',
        description: 'Organisez un espace de votre domicile ou de votre bureau.',
        category: 'Organisation',
        difficulty: 2,
        estimatedDurationMinutes: 45,
        frequency: QuestFrequency.weekly,
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      ),
    ];
  }
}
