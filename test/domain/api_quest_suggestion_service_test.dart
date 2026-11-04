import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/domain/services/api_quest_suggestion_service.dart';
import 'package:sameva/domain/services/quest_suggestion_service.dart';

void main() {
  const req = QuestSuggestionRequest(
    playerLevel: 99, streak: 99, totalQuestsCompleted: 999, favoriteCategory: 'Sport');

  test('le profil n\'est jamais envoyé : seul le serveur le connaît', () async {
    Map<String, dynamic>? envoye;
    final service = ApiQuestSuggestionService(invoker: (body) async {
      envoye = body;
      return (200, {'quests': <dynamic>[]});
    });
    await service.suggestQuests(userId: 'u', request: req);
    expect(envoye, {'favorite_category': 'Sport'});
  });

  test('les quêtes renvoyées sont converties', () async {
    final service = ApiQuestSuggestionService(invoker: (_) async => (200, {
          'quests': [
            {'title': 'Courir 10 min', 'category': 'Sport', 'difficulty': 2,
             'estimated_duration_minutes': 10, 'frequency': 'one_off'},
          ]
        }));
    final quetes = await service.suggestQuests(userId: 'u', request: req);
    expect(quetes.single.title, 'Courir 10 min');
    expect(quetes.single.difficulty, 2);
  });

  test('quota atteint : message clair', () async {
    final service = ApiQuestSuggestionService(
        invoker: (_) async => (429, {'code': 'plafond_atteint'}));
    expect(
      () => service.suggestQuests(userId: 'u', request: req),
      throwsA(isA<QuestSuggestionException>()
          .having((e) => e.code, 'code', 'plafond_atteint')
          .having((e) => e.userMessage, 'message', contains('demain'))),
    );
  });

  test('IA indisponible : message générique, pas de détail technique', () async {
    final service = ApiQuestSuggestionService(
        invoker: (_) async => (502, {'code': 'UPSTREAM_ERROR', 'error': 'stack...'}));
    expect(
      () => service.suggestQuests(userId: 'u', request: req),
      throwsA(isA<QuestSuggestionException>()
          .having((e) => e.userMessage, 'message', contains('indisponible'))),
    );
  });
}
