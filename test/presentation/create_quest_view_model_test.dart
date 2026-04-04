import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/create_quest_view_model.dart';

class _MockQuestRepository extends Mock implements QuestRepository {}

class _MockAuthViewModel extends Mock implements AuthViewModel {}

void main() {
  late _MockQuestRepository questRepo;
  late _MockAuthViewModel auth;
  late CreateQuestViewModel vm;

  setUpAll(() {
    registerFallbackValue(
      Quest(
        userId: 'fallback-user',
        title: 't',
        estimatedDurationMinutes: 1,
        frequency: QuestFrequency.oneOff,
        difficulty: 1,
        category: 'Autre',
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      ),
    );
  });

  setUp(() {
    questRepo = _MockQuestRepository();
    auth = _MockAuthViewModel();
    vm = CreateQuestViewModel(questRepo, auth);
  });

  group('CreateQuestViewModel', () {
    test('devrait échouer sans utilisateur connecté', () async {
      when(() => auth.userId).thenReturn(null);

      final ok = await vm.createQuest(
        title: 'Ma quête',
        category: 'Sport',
        validationType: ValidationType.manual,
      );

      expect(ok, isFalse);
      expect(vm.errorMessage, 'Non connecté');
      verifyNever(() => questRepo.addQuest(any()));
    });

    test('devrait appeler addQuest et retourner true si succès', () async {
      when(() => auth.userId).thenReturn('user-abc');
      when(() => questRepo.addQuest(any())).thenAnswer((inv) async {
        final q = inv.positionalArguments.first as Quest;
        return q.copyWith(id: 'new-id');
      });

      final ok = await vm.createQuest(
        title: '  Ranger la table  ',
        category: 'Maison',
        validationType: ValidationType.photo,
        description: '  ',
      );

      expect(ok, isTrue);
      expect(vm.errorMessage, isNull);
      final captured = verify(() => questRepo.addQuest(captureAny())).captured.single
          as Quest;
      expect(captured.userId, 'user-abc');
      expect(captured.title, 'Ranger la table');
      expect(captured.description, isNull);
    });

    test('devrait capturer l\'erreur du repository', () async {
      when(() => auth.userId).thenReturn('user-abc');
      when(() => questRepo.addQuest(any())).thenThrow(Exception('réseau'));

      final ok = await vm.createQuest(
        title: 'T',
        category: 'Autre',
        validationType: ValidationType.manual,
      );

      expect(ok, isFalse);
      expect(vm.errorMessage, contains('réseau'));
    });
  });
}
