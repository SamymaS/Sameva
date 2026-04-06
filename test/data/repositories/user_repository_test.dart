import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:sameva/data/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Fake qui simule la chaîne `.select('id').eq('id', userId).maybySingle()`.
class _FakeSelectFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final PostgrestMap? _maybySingleResult;

  _FakeSelectFilter(this._maybySingleResult);

  @override
  _FakeSelectFilter eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybySingle(_maybySingleResult);

  // Unused dans ces tests mais requis pour implémenter Future<PostgrestList>
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

/// Fake qui représente le résultat final de `maybySingle()`.
class _FakeMaybySingle extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  final PostgrestMap? _result;
  _FakeMaybySingle(this._result);

  @override
  Future<R> then<R>(FutureOr<R> Function(PostgrestMap?) onValue,
      {Function? onError}) {
    return Future<PostgrestMap?>.value(_result)
        .then(onValue, onError: onError);
  }

  @override
  Future<PostgrestMap?> catchError(Function onError,
          {bool Function(Object)? test}) =>
      Future<PostgrestMap?>.value(_result).catchError(onError, test: test);

  @override
  Future<PostgrestMap?> whenComplete(FutureOr<void> Function() action) =>
      Future<PostgrestMap?>.value(_result).whenComplete(action);

  @override
  Stream<PostgrestMap?> asStream() =>
      Future<PostgrestMap?>.value(_result).asStream();

  @override
  Future<PostgrestMap?> timeout(Duration timeLimit,
          {FutureOr<PostgrestMap?> Function()? onTimeout}) =>
      Future<PostgrestMap?>.value(_result)
          .timeout(timeLimit, onTimeout: onTimeout);
}

/// Fake qui simule un insert Supabase qui se termine sans erreur.
class _FakeInsertFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
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

void main() {
  late _MockSupabaseClient supabase;
  late _MockGoTrueClient goTrue;
  late _MockUser authUser;
  late UserRepository repo;

  setUp(() {
    supabase = _MockSupabaseClient();
    goTrue = _MockGoTrueClient();
    authUser = _MockUser();
    when(() => supabase.auth).thenReturn(goTrue);
    when(() => authUser.id).thenReturn('uid-1');
    when(() => authUser.email).thenReturn('test@example.com');
    when(() => authUser.userMetadata).thenReturn(null);
    repo = UserRepository(supabase);
  });

  group('UserRepository', () {
    group('ensureUserExists', () {
      test('retourne immédiatement si l\'utilisateur existe déjà', () async {
        final qb = _MockQueryBuilder();
        when(() => supabase.from('users')).thenAnswer((_) => qb);
        when(() => qb.select(any()))
            .thenAnswer((_) => _FakeSelectFilter({'id': 'uid-1'}));

        await repo.ensureUserExists('uid-1');

        // Aucun insert ne doit avoir été tenté
        verifyNever(() => goTrue.currentUser);
        verifyNever(() => qb.insert(any()));
      });

      test('lève une exception si authUser est null et l\'utilisateur est absent',
          () async {
        final qb = _MockQueryBuilder();
        when(() => supabase.from('users')).thenAnswer((_) => qb);
        when(() => qb.select(any()))
            .thenAnswer((_) => _FakeSelectFilter(null));
        when(() => goTrue.currentUser).thenReturn(null);

        Object? caught;
        try {
          await repo.ensureUserExists('uid-1');
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<Exception>());
      });

      test('insère l\'utilisateur si absent et auth valide', () async {
        final qb = _MockQueryBuilder();
        // Première appel from('users') → select → null (user absent)
        // Deuxième appel from('users') → insert
        var callCount = 0;
        when(() => supabase.from('users')).thenAnswer((_) {
          callCount++;
          return qb;
        });
        when(() => qb.select(any()))
            .thenAnswer((_) => _FakeSelectFilter(null));
        when(() => goTrue.currentUser).thenReturn(authUser);
        when(() => qb.insert(any())).thenAnswer((_) => _FakeInsertFilter());

        // L'insert de user_equipment peut échouer — best-effort
        final equipQb = _MockQueryBuilder();
        when(() => supabase.from('user_equipment')).thenAnswer((_) => equipQb);
        when(() => equipQb.insert(any()))
            .thenAnswer((_) => _FakeInsertFilter());

        await repo.ensureUserExists('uid-1');

        verify(() => qb.insert(any())).called(1);
      });
    });
  });
}
