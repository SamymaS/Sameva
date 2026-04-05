import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/claude_validation_ai_service.dart';

Quest _quest() => Quest(
      userId: 'u',
      title: 'Laver la vaisselle',
      estimatedDurationMinutes: 20,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: 'Maison',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
    );

String _claudeSuccessBody(String innerJson) => jsonEncode({
      'content': [
        {'text': innerJson},
      ],
    });

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  group('ClaudeValidationAIService', () {
    test('analyzeProof extrait score et explanation du JSON dans content', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['x-api-key'], 'test-key');
        expect(request.headers['anthropic-version'], '2023-06-01');
        return http.Response(
          _claudeSuccessBody('{"score": 88, "explanation": "Preuve claire."}'),
          200,
        );
      });

      final svc = ClaudeValidationAIService(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final r = await svc.analyzeProof(quest: _quest(), imageBytes: bytes);

      expect(r.score, 88);
      expect(r.explanation, 'Preuve claire.');
      expect(r.isValid, isTrue);
    });

    test('isValid false si score sous 70', () async {
      final mockClient = MockClient(
        (_) async => http.Response(
          _claudeSuccessBody('{"score": 55, "explanation": "Insuffisant"}'),
          200,
        ),
      );

      final svc = ClaudeValidationAIService(
        apiKey: 'k',
        httpClient: mockClient,
      );

      final r = await svc.analyzeProof(quest: _quest(), imageBytes: bytes);

      expect(r.isValid, isFalse);
      expect(r.score, 55);
    });

    test('réponse HTTP non 200 lève avec message structuré si possible', () async {
      final mockClient = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'clé invalide'},
          }),
          401,
        ),
      );

      final svc = ClaudeValidationAIService(
        apiKey: 'bad',
        httpClient: mockClient,
      );

      expect(
        () => svc.analyzeProof(quest: _quest(), imageBytes: bytes),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('401') && e.toString().contains('clé'),
          ),
        ),
      );
    });

    test('contenu illisible retourne un fallback score 50', () async {
      final mockClient = MockClient(
        (_) async => http.Response(
          _claudeSuccessBody('pas du json ici'),
          200,
        ),
      );

      final svc = ClaudeValidationAIService(
        apiKey: 'k',
        httpClient: mockClient,
      );

      final r = await svc.analyzeProof(quest: _quest(), imageBytes: bytes);

      expect(r.score, 50);
      expect(r.isValid, isFalse);
      expect(r.explanation, contains('Impossible de parser'));
    });

    test('analyzeVideoProof retourne un résultat estimé', () async {
      final svc = ClaudeValidationAIService(
        apiKey: 'k',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      final r = await svc.analyzeVideoProof(quest: _quest(), videoPath: '/x.mp4');

      expect(r.score, 75);
      expect(r.isValid, isTrue);
    });
  });
}
