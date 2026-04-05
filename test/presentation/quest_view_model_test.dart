import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/domain/services/quest_rewards_calculator.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';

import '../helpers/quest_test_factory.dart';

class _MockQuestRepo extends Mock implements QuestRepository {}

void main() {
  late _MockQuestRepo repo;
  late QuestViewModel vm;

  setUpAll(() {
    registerFallbackValue(
      Quest(
        userId: 'fb',
        title: 'fb',
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
    repo = _MockQuestRepo();
    vm = QuestViewModel(repo);
  });

  Quest makeQuest({
    String? id,
    QuestStatus status = QuestStatus.active,
    DateTime? completedAt,
    DateTime? deadline,
    QuestFrequency frequency = QuestFrequency.oneOff,
    DateTime? createdAt,
  }) {
    return Quest(
      id: id,
      userId: 'u',
      title: 'T',
      estimatedDurationMinutes: 60,
      frequency: frequency,
      difficulty: 2,
      category: 'Autre',
      rarity: QuestRarity.common,
      status: status,
      createdAt: createdAt ?? DateTime(2024, 1, 1, 12, 0),
      completedAt: completedAt,
      deadline: deadline,
    );
  }

  group('QuestViewModel', () {
    test('loadQuests avec userId vide ne charge rien', () async {
      await vm.loadQuests('');

      expect(vm.quests, isEmpty);
      expect(vm.isLoading, isFalse);
      verifyNever(() => repo.loadQuests(any()));
    });

    test('loadQuests remplit la liste et lève isLoading', () async {
      final list = [makeQuest(id: 'a')];
      when(() => repo.loadQuests('u1')).thenAnswer((_) async => list);

      await vm.loadQuests('u1');

      expect(vm.quests, list);
      expect(vm.error, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.activeQuests, hasLength(1));
    });

    test('loadQuests en erreur expose un message et vide la liste', () async {
      when(() => repo.loadQuests('u1')).thenThrow(Exception('offline'));

      await vm.loadQuests('u1');

      expect(vm.quests, isEmpty);
      expect(vm.error, isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('loadQuests laisse isLoading à true jusqu\'à la fin du repository', () async {
      final completer = Completer<List<Quest>>();
      when(() => repo.loadQuests('u1')).thenAnswer((_) => completer.future);

      final future = vm.loadQuests('u1');
      expect(vm.isLoading, isTrue);
      expect(vm.error, isNull);

      completer.complete([makeQuest(id: 'x')]);
      await future;

      expect(vm.isLoading, isFalse);
      expect(vm.quests, hasLength(1));
    });

    test('clearError efface l\'erreur', () async {
      when(() => repo.loadQuests('u1')).thenThrow(Exception('x'));
      await vm.loadQuests('u1');
      vm.clearError();
      expect(vm.error, isNull);
    });

    test('addQuest insère en tête', () async {
      final created = makeQuest(id: 'new');
      when(() => repo.addQuest(any())).thenAnswer((_) async => created);

      await vm.addQuest(makeQuest());

      expect(vm.quests.first.id, 'new');
    });

    test('updateQuest met à jour l\'entrée locale', () async {
      final old = makeQuest(id: 'x', status: QuestStatus.active);
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [old]);
      await vm.loadQuests('u');

      final updated = old.copyWith(status: QuestStatus.completed);
      when(() => repo.updateQuest(updated)).thenAnswer((_) async => updated);

      await vm.updateQuest(updated);

      expect(vm.quests.first.status, QuestStatus.completed);
    });

    test('updateQuest pour une quête absente de la liste ne modifie pas l\'état local',
        () async {
      final inList = makeQuest(id: 'a');
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [inList]);
      await vm.loadQuests('u');

      final ghost = makeQuest(id: 'b', status: QuestStatus.completed);
      when(() => repo.updateQuest(ghost)).thenAnswer((_) async => ghost);

      await vm.updateQuest(ghost);

      expect(vm.quests, hasLength(1));
      expect(vm.quests.first.id, 'a');
      expect(vm.quests.first.status, QuestStatus.active);
    });

    test('deleteQuest retire la quête', () async {
      final q = makeQuest(id: 'del');
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [q]);
      await vm.loadQuests('u');
      when(() => repo.deleteQuest('del')).thenAnswer((_) async {});

      await vm.deleteQuest('del');

      expect(vm.quests, isEmpty);
    });

    test('completeQuest met à jour le statut via le repository', () async {
      final q = makeQuest(id: 'c');
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [q]);
      await vm.loadQuests('u');
      final done = q.copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime(2024, 6, 1),
      );
      when(() => repo.completeQuest(q)).thenAnswer((_) async => done);

      await vm.completeQuest('c');

      expect(vm.quests.first.status, QuestStatus.completed);
    });

    test('completeQuest avec id inconnu propage une erreur', () async {
      final q = makeQuest(id: 'only');
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [q]);
      await vm.loadQuests('u');

      await expectLater(
        vm.completeQuest('inexistant'),
        throwsStateError,
      );
    });

    test('deleteQuest propage si le repository échoue', () async {
      final q = makeQuest(id: 'd');
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [q]);
      await vm.loadQuests('u');
      when(() => repo.deleteQuest('d')).thenThrow(Exception('réseau'));

      await expectLater(
        vm.deleteQuest('d'),
        throwsException,
      );
    });

    test('calculateRewards délègue au calculateur métier', () {
      final quest = buildTestQuest(difficulty: 2);
      final at = DateTime.utc(2024, 6, 1, 13, 0);
      final fromVm = vm.calculateRewards(quest, at);
      final direct = QuestRewardsCalculator.calculateRewardsWithTiming(quest, at);
      expect(fromVm.experience, direct.experience);
      expect(fromVm.gold, direct.gold);
      expect(fromVm.bonusType, direct.bonusType);
    });

    test('getMissedQuests inclut les quêtes actives après deadline', () async {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final missed = makeQuest(id: 'm', deadline: past);
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [missed]);

      await vm.loadQuests('u');

      expect(vm.getMissedQuests(), hasLength(1));
    });

    test('getCompletedQuestsToday inclut une quête complétée aujourd\'hui', () async {
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12);
      final q = makeQuest(
        id: 'today',
        status: QuestStatus.completed,
        completedAt: noon,
      );
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [q]);
      await vm.loadQuests('u');

      expect(vm.getCompletedQuestsToday(), hasLength(1));
    });

    test('getActiveQuestsToday inclut une quête one_off active créée aujourd\'hui', () async {
      final now = DateTime.now();
      final created = DateTime(now.year, now.month, now.day, 8);
      final q = makeQuest(
        id: 'act',
        status: QuestStatus.active,
        frequency: QuestFrequency.oneOff,
        createdAt: created,
      );
      when(() => repo.loadQuests('u')).thenAnswer((_) async => [q]);
      await vm.loadQuests('u');

      expect(vm.getActiveQuestsToday(), contains(q));
    });
  });
}
