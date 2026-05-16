import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/cat_model.dart';
import 'package:sameva/data/repositories/cat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _FakeCatStats extends Fake implements CatStats {}

/// Fake pour les appels chaînés de lecture (select → eq → réponse liste).
// ignore: must_be_immutable
class _FakeSelectFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<Map<String, dynamic>> _rows;
  _FakeSelectFilter(this._rows);

  @override
  _FakeSelectFilter eq(String column, Object value) => this;

  @override
  Future<R> then<R>(FutureOr<R> Function(PostgrestList) onValue,
      {Function? onError}) {
    return Future<PostgrestList>.value(_rows).then(onValue, onError: onError);
  }

  @override
  Future<PostgrestList> catchError(Function onError,
          {bool Function(Object)? test}) =>
      Future.value(_rows).catchError(onError, test: test);

  @override
  Future<PostgrestList> whenComplete(FutureOr<void> Function() action) =>
      Future.value(_rows).whenComplete(action);

  @override
  Stream<PostgrestList> asStream() => Future.value(_rows).asStream();

  @override
  Future<PostgrestList> timeout(Duration timeLimit,
          {FutureOr<PostgrestList> Function()? onTimeout}) =>
      Future.value(_rows).timeout(timeLimit, onTimeout: onTimeout);
}

/// Fake pour les appels d'upsert (retourne void via Future<PostgrestList>).
// ignore: must_be_immutable
class _FakeUpsertFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  @override
  Future<R> then<R>(FutureOr<R> Function(PostgrestList) onValue,
      {Function? onError}) {
    return Future<PostgrestList>.value([]).then(onValue, onError: onError);
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

CatStats _makeCat({String id = 'cat-1', bool isMain = false}) => CatStats(
      id: id,
      name: 'Michi',
      race: 'michi',
      rarity: 'common',
      isMain: isMain,
      obtainedAt: DateTime.utc(2025, 1, 1),
    );

final _supabaseRow = {
  'id': 'cat-1',
  'user_id': 'user-1',
  'name': 'Michi',
  'race': 'michi',
  'rarity': 'common',
  'is_main': false,
  'equipped_hat': null,
  'equipped_outfit_cosmetic': null,
  'equipped_pants': null,
  'equipped_shoes': null,
  'equipped_aura': null,
  'equipped_accessory': null,
  'equipped_title': null,
  'created_at': '2025-01-01T00:00:00.000Z',
};

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCatStats());
  });

  late _MockSupabaseClient supabase;
  late _MockQueryBuilder queryBuilder;
  late CatRepository repo;

  setUp(() {
    supabase = _MockSupabaseClient();
    queryBuilder = _MockQueryBuilder();
    repo = CatRepository(supabase);
  });

  group('CatRepository', () {
    group('fetchRemoteCompanions', () {
      test('retourne la liste parsée si Supabase répond', () async {
        when(() => supabase.from('companions'))
            .thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.select())
            .thenAnswer((_) => _FakeSelectFilter([_supabaseRow]));

        final result = await repo.fetchRemoteCompanions('user-1');

        expect(result, hasLength(1));
        expect(result.first.id, 'cat-1');
        expect(result.first.race, 'michi');
      });

      test('retourne liste vide si Supabase retourne aucune ligne', () async {
        when(() => supabase.from('companions'))
            .thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.select())
            .thenAnswer((_) => _FakeSelectFilter([]));

        final result = await repo.fetchRemoteCompanions('user-1');

        expect(result, isEmpty);
      });

      test('retourne liste vide et ne propage pas l\'exception sur erreur réseau',
          () async {
        when(() => supabase.from('companions'))
            .thenThrow(Exception('offline'));

        await expectLater(
          () async => repo.fetchRemoteCompanions('user-1'),
          returnsNormally,
        );

        final result = await repo.fetchRemoteCompanions('user-1');
        expect(result, isEmpty);
      });
    });

    group('upsertCompanion', () {
      test('appelle upsert avec onConflict id et user_id dans le payload',
          () async {
        when(() => supabase.from('companions'))
            .thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.upsert(any(), onConflict: any(named: 'onConflict')))
            .thenAnswer((_) => _FakeUpsertFilter());

        final cat = _makeCat();
        await repo.upsertCompanion('user-1', cat);

        final captured = verify(() => queryBuilder.upsert(
              captureAny(),
              onConflict: captureAny(named: 'onConflict'),
            )).captured;

        final payload = captured[0] as Map<String, dynamic>;
        final conflict = captured[1] as String;

        expect(payload['user_id'], 'user-1');
        expect(payload['id'], 'cat-1');
        expect(conflict, 'id');
      });

      test('avale les exceptions sans propager', () async {
        when(() => supabase.from('companions'))
            .thenThrow(Exception('réseau indisponible'));

        await expectLater(
          () async => repo.upsertCompanion('user-1', _makeCat()),
          returnsNormally,
        );
      });

      test('ne propage pas si upsert lève une exception Supabase', () async {
        when(() => supabase.from('companions'))
            .thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.upsert(any(), onConflict: any(named: 'onConflict')))
            .thenThrow(Exception('conflit DB'));

        await expectLater(
          () async => repo.upsertCompanion('user-1', _makeCat()),
          returnsNormally,
        );
      });
    });
  });
}
