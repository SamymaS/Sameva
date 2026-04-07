import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/data/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Fake filtre Supabase pour les opérations d'écriture (update/delete).
/// La valeur retournée est ignorée par le repo ; on simule une réponse vide.
// ignore: must_be_immutable
class _FakeWriteFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  bool eqCalled = false;
  String? eqColumn;
  Object? eqValue;

  @override
  _FakeWriteFilter eq(String column, Object value) {
    eqCalled = true;
    eqColumn = column;
    eqValue = value;
    return this;
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(PostgrestList) onValue,
      {Function? onError}) {
    return Future<PostgrestList>.value(<PostgrestMap>[])
        .then(onValue, onError: onError);
  }

  @override
  Future<PostgrestList> catchError(Function onError,
          {bool Function(Object)? test}) =>
      Future.value(<PostgrestMap>[]).catchError(onError, test: test);

  @override
  Future<PostgrestList> whenComplete(FutureOr<void> Function() action) =>
      Future.value(<PostgrestMap>[]).whenComplete(action);

  @override
  Stream<PostgrestList> asStream() =>
      Future.value(<PostgrestMap>[]).asStream();

  @override
  Future<PostgrestList> timeout(Duration timeLimit,
          {FutureOr<PostgrestList> Function()? onTimeout}) =>
      Future.value(<PostgrestMap>[]).timeout(timeLimit, onTimeout: onTimeout);
}

Quest _makeQuest({
  String? id,
  QuestStatus status = QuestStatus.active,
  QuestFrequency frequency = QuestFrequency.oneOff,
  DateTime? completedAt,
}) =>
    Quest(
      id: id,
      userId: 'u1',
      title: 'Quête test',
      estimatedDurationMinutes: 30,
      frequency: frequency,
      difficulty: 2,
      category: 'Autre',
      rarity: QuestRarity.common,
      status: status,
      createdAt: DateTime(2024, 1, 1, 12),
      completedAt: completedAt,
    );

void main() {
  late _MockSupabaseClient supabase;
  late _MockUserRepository userRepo;
  late _MockQueryBuilder queryBuilder;
  late QuestRepository repo;

  setUp(() {
    supabase = _MockSupabaseClient();
    userRepo = _MockUserRepository();
    queryBuilder = _MockQueryBuilder();
    repo = QuestRepository(supabase, userRepo);
  });

  group('QuestRepository', () {
    group('updateQuest', () {
      test('lève une exception si quest.id est null', () async {
        final quest = _makeQuest(); // pas d'id

        await expectLater(
          () async => repo.updateQuest(quest),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => supabase.from(any()));
      });

      test('retourne la quête mise à jour après appel Supabase', () async {
        final filter = _FakeWriteFilter();
        when(() => supabase.from('quests')).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.update(any())).thenAnswer((_) => filter);
        final quest = _makeQuest(id: 'q-1');

        final result = await repo.updateQuest(quest);

        expect(result, quest);
        expect(filter.eqCalled, isTrue);
        expect(filter.eqColumn, 'id');
        expect(filter.eqValue, 'q-1');
      });
    });

    group('deleteQuest', () {
      test('appelle la suppression Supabase pour l\'id donné', () async {
        final filter = _FakeWriteFilter();
        when(() => supabase.from('quests')).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.delete()).thenAnswer((_) => filter);

        await repo.deleteQuest('q-del');

        verify(() => supabase.from('quests')).called(1);
        verify(() => queryBuilder.delete()).called(1);
        expect(filter.eqColumn, 'id');
        expect(filter.eqValue, 'q-del');
      });
    });

    group('completeQuest', () {
      test('met le statut à completed et renseigne completedAt', () async {
        final filter = _FakeWriteFilter();
        when(() => supabase.from('quests')).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.update(any())).thenAnswer((_) => filter);
        final quest = _makeQuest(id: 'q-c');

        final result = await repo.completeQuest(quest);

        expect(result.status, QuestStatus.completed);
        expect(result.completedAt, isNotNull);
      });

      test('délègue à updateQuest (appel Supabase unique)', () async {
        final filter = _FakeWriteFilter();
        when(() => supabase.from('quests')).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.update(any())).thenAnswer((_) => filter);

        await repo.completeQuest(_makeQuest(id: 'q-c2'));

        verify(() => queryBuilder.update(any())).called(1);
      });
    });
  });
}
