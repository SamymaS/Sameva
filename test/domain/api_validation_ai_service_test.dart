import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/api_validation_ai_service.dart';

Quest _quest() => Quest(
      userId: 'u',
      title: 'Ranger',
      estimatedDurationMinutes: 10,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: 'Maison',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
    );

void main() {
  final imageBytes = Uint8List.fromList([1, 2, 3]);

  group('ApiValidationAIService', () {
    test('analyzeProof parse score et explanation si 200', () async {
      var capturedBody = '';
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        capturedBody = request.body;
        return http.Response(
          jsonEncode({'score': 82, 'explanation': 'Preuve cohérente.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final svc = ApiValidationAIService(
        baseUrl: 'https://api.example.com/validate',
        httpClient: mockClient,
      );

      final r = await svc.analyzeProof(quest: _quest(), imageBytes: imageBytes);

      expect(r.score, 82);
      expect(r.explanation, 'Preuve cohérente.');
      expect(r.isValid, isTrue);
      final payload = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(payload['quest_title'], 'Ranger');
      expect(payload['quest_category'], 'Maison');
      expect(payload['image_base64'], isNotEmpty);
    });

    test('analyzeProof ajoute Authorization si token fourni', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer secret-token');
        return http.Response(jsonEncode({'score': 70, 'explanation': 'ok'}), 200);
      });

      final svc = ApiValidationAIService(
        baseUrl: 'https://api.example.com/v',
        authToken: 'secret-token',
        httpClient: mockClient,
      );

      await svc.analyzeProof(quest: _quest(), imageBytes: imageBytes);
    });

    test('isValid false si score sous le seuil 70', () async {
      final mockClient = MockClient(
        (_) async => http.Response(
          jsonEncode({'score': 45, 'explanation': 'Trop flou'}),
          200,
        ),
      );

      final svc = ApiValidationAIService(
        baseUrl: 'https://x.com',
        httpClient: mockClient,
      );

      final r = await svc.analyzeProof(quest: _quest(), imageBytes: imageBytes);

      expect(r.isValid, isFalse);
      expect(r.score, 45);
    });

    test('lève si status HTTP différent de 200', () async {
      final mockClient = MockClient(
        (_) async => http.Response('erreur', 503),
      );

      final svc = ApiValidationAIService(
        baseUrl: 'https://x.com',
        httpClient: mockClient,
      );

      expect(
        () => svc.analyzeProof(quest: _quest(), imageBytes: imageBytes),
        throwsException,
      );
    });

    test('analyzeVideoProof lève une Exception avec message utilisateur', () {
      final svc = ApiValidationAIService(
        baseUrl: 'https://x.com',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => svc.analyzeVideoProof(quest: _quest(), videoPath: '/v.mp4'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
