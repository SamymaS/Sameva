import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/domain/services/validation_ai_service.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/quest_validation_view_model.dart';

class _MockAuth extends Mock implements AuthViewModel {}

class _MockQuestRepo extends Mock implements QuestRepository {}

class _MockValidationAI extends Mock implements ValidationAIService {}

Quest _quest({String? id}) => Quest(
      id: id,
      userId: 'u1',
      title: 'Faire le lit',
      estimatedDurationMinutes: 30,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: 'Maison',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
    );

void main() {
  late _MockAuth auth;
  late _MockQuestRepo repo;
  late _MockValidationAI ai;
  late QuestValidationViewModel vm;

  setUpAll(() {
    registerFallbackValue(_quest());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    auth = _MockAuth();
    repo = _MockQuestRepo();
    ai = _MockValidationAI();
    vm = QuestValidationViewModel(auth, repo, validationService: ai);
    when(
      () => ai.analyzeVideoProof(
        quest: any(named: 'quest'),
        videoPath: any(named: 'videoPath'),
      ),
    ).thenThrow(UnimplementedError());
  });

  group('QuestValidationViewModel', () {
    test('état initial : pas de preuve, pas d\'analyse, pas de résultat', () {
      expect(vm.proofImage, isNull);
      expect(vm.isAnalyzing, isFalse);
      expect(vm.result, isNull);
    });

    test('analyzeProof passe en chargement puis enregistre le résultat si succès',
        () async {
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenAnswer((_) async => const ValidationResult(
                score: 85,
                explanation: 'OK',
                isValid: true,
              ));

      final q = _quest();
      final bytes = Uint8List.fromList([1, 2, 3]);
      final future = vm.analyzeProof(q, bytes);

      expect(vm.isAnalyzing, isTrue);
      await future;

      expect(vm.isAnalyzing, isFalse);
      expect(vm.result?.isValid, isTrue);
      expect(vm.result?.score, 85);
      verify(() => ai.analyzeProof(quest: q, imageBytes: bytes)).called(1);
    });

    test('analyzeProof restaure isAnalyzing si l\'IA lève une exception',
        () async {
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenThrow(Exception('réseau'));

      await expectLater(
        vm.analyzeProof(_quest(), Uint8List(1)),
        throwsException,
      );

      expect(vm.isAnalyzing, isFalse);
    });

    test('analyzeProof enregistre un échec si score sous le seuil (isValid false)',
        () async {
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenAnswer((_) async => const ValidationResult(
                score: 40,
                explanation: 'Trop faible',
                isValid: false,
              ));

      await vm.analyzeProof(_quest(), Uint8List(4));

      expect(vm.result?.isValid, isFalse);
      expect(vm.result?.score, 40);
      expect(vm.result?.explanation, contains('faible'));
    });

    test('preuve vide : l\'IA est quand même appelée (orchestration)', () async {
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenAnswer((_) async => const ValidationResult(
                score: 0,
                explanation: 'Rien à analyser',
                isValid: false,
              ));

      await vm.analyzeProof(_quest(), Uint8List(0));

      verify(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).called(1);
    });

    test('setProof efface le résultat précédent', () {
      vm.setProof(Uint8List.fromList([9]));
      expect(vm.proofImage, isNotNull);

      vm.setProof(null);

      expect(vm.proofImage, isNull);
      expect(vm.result, isNull);
    });

    test('completeQuest retourne false sans id de quête', () async {
      when(() => auth.userId).thenReturn('u1');
      final ok = await vm.completeQuest(_quest(id: null));
      expect(ok, isFalse);
      verifyNever(() => repo.completeQuest(any()));
    });

    test('completeQuest retourne false sans utilisateur', () async {
      when(() => auth.userId).thenReturn(null);
      final ok = await vm.completeQuest(_quest(id: 'q1'));
      expect(ok, isFalse);
      verifyNever(() => repo.completeQuest(any()));
    });

    test('completeQuest appelle le repository et retourne true', () async {
      when(() => auth.userId).thenReturn('u1');
      final q = _quest(id: 'q1');
      when(() => repo.completeQuest(q)).thenAnswer((_) async => q);

      final ok = await vm.completeQuest(q);

      expect(ok, isTrue);
      verify(() => repo.completeQuest(q)).called(1);
    });

    test('completeQuest retourne false si le repository échoue', () async {
      when(() => auth.userId).thenReturn('u1');
      final q = _quest(id: 'q1');
      when(() => repo.completeQuest(q)).thenThrow(Exception('db'));

      final ok = await vm.completeQuest(q);

      expect(ok, isFalse);
    });
  });
}
