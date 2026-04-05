import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/claude_quest_generator_service.dart';

String _claudeResponseBody(String textWithArray) => jsonEncode({
      'content': [
        {'type': 'text', 'text': textWithArray},
      ],
    });

void main() {
  group('ClaudeQuestGeneratorService', () {
    test('generateQuests parse le tableau JSON dans la réponse', () async {
      const inner =
          '[{"title":"Quête A","description":"Desc","category":"Sport","difficulty":2,"estimated_duration_minutes":15,"frequency":"daily"}]';
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['x-api-key'], 'test-key');
        return http.Response(_claudeResponseBody(inner), 200);
      });

      final svc = ClaudeQuestGeneratorService(apiKey: 'test-key', httpClient: client);
      final list = await svc.generateQuests(
        userId: 'user-1',
        playerLevel: 5,
        streak: 2,
        totalQuestsCompleted: 10,
      );

      expect(list, hasLength(1));
      expect(list.first.userId, 'user-1');
      expect(list.first.title, 'Quête A');
      expect(list.first.description, 'Desc');
      expect(list.first.category, 'Sport');
      expect(list.first.difficulty, 2);
      expect(list.first.estimatedDurationMinutes, 15);
      expect(list.first.frequency, QuestFrequency.daily);
      expect(list.first.status, QuestStatus.active);
    });

    test('lève si status HTTP != 200', () async {
      final client = MockClient((_) async => http.Response('erreur', 502));
      final svc = ClaudeQuestGeneratorService(apiKey: 'k', httpClient: client);

      expect(
        () => svc.generateQuests(
          userId: 'u',
          playerLevel: 1,
          streak: 0,
          totalQuestsCompleted: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('lève si aucun tableau JSON dans le texte', () async {
      final client = MockClient(
        (_) async => http.Response(_claudeResponseBody('Pas de JSON ici'), 200),
      );
      final svc = ClaudeQuestGeneratorService(apiKey: 'k', httpClient: client);

      expect(
        () => svc.generateQuests(
          userId: 'u',
          playerLevel: 1,
          streak: 0,
          totalQuestsCompleted: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
