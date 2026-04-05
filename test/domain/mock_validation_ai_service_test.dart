import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/validation_ai_service.dart';

void main() {
  group('MockValidationAIService', () {
    Quest quest() => Quest(
          userId: 'u',
          title: 'Titre test',
          estimatedDurationMinutes: 10,
          frequency: QuestFrequency.oneOff,
          difficulty: 1,
          category: 'Cat',
          rarity: QuestRarity.common,
          status: QuestStatus.active,
        );

    test('analyzeProof : score = 65 + (longueur image % 31), délai nul', () async {
      final svc = MockValidationAIService(simulatedDelay: Duration.zero);
      final q = quest();
      final r = await svc.analyzeProof(
        quest: q,
        imageBytes: Uint8List.fromList(List.filled(10, 0)),
      );
      expect(r.score, 65 + (10 % 31));
      expect(r.isValid, r.score >= MockValidationAIService.validationThreshold);
      expect(r.explanation, contains(q.title));
    });

    test('analyzeVideoProof : score basé sur hashCode du chemin, délai nul', () async {
      final svc = MockValidationAIService(simulatedDelay: Duration.zero);
      const path = '/tmp/proof.mp4';
      final r = await svc.analyzeVideoProof(quest: quest(), videoPath: path);
      final expected = 70 + (path.hashCode % 25).clamp(0, 30);
      expect(r.score, expected);
      expect(r.isValid, isTrue);
    });
  });
}
