import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockUserResponse extends Mock implements UserResponse {}

class _FakeUserAttributes extends Fake implements UserAttributes {}

// Valeurs fictives utilisées uniquement dans les mocks — aucun appel réseau réel.
const _fakeEmail = 'test@example.com';
const _fakePassword = 'fake-password-tests-only';

void main() {
  late _MockSupabaseClient supabase;
  late _MockGoTrueClient goTrue;
  late AuthRepository repo;

  setUpAll(() {
    registerFallbackValue(_FakeUserAttributes());
  });

  setUp(() {
    supabase = _MockSupabaseClient();
    goTrue = _MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);
    repo = AuthRepository(supabase);
  });

  group('AuthRepository', () {
    group('propriétés', () {
      test('isAuthenticated retourne false si currentUser est null', () {
        when(() => goTrue.currentUser).thenReturn(null);

        expect(repo.isAuthenticated, isFalse);
      });

      test('isAuthenticated retourne true si currentUser est présent', () {
        final user = _MockUser();
        when(() => goTrue.currentUser).thenReturn(user);

        expect(repo.isAuthenticated, isTrue);
      });

      test('userId retourne null si currentUser est null', () {
        when(() => goTrue.currentUser).thenReturn(null);

        expect(repo.userId, isNull);
      });

      test('userId retourne l\'id de l\'utilisateur', () {
        final user = _MockUser();
        when(() => user.id).thenReturn('uid-42');
        when(() => goTrue.currentUser).thenReturn(user);

        expect(repo.userId, 'uid-42');
      });

      test('authStateChanges délègue au stream GoTrue', () {
        const stream = Stream<AuthState>.empty();
        when(() => goTrue.onAuthStateChange).thenAnswer((_) => stream);

        expect(repo.authStateChanges, stream);
      });
    });

    group('signInWithEmailAndPassword', () {
      test('délègue à GoTrue avec l\'email trimmé', () async {
        final user = _MockUser();
        when(() => user.id).thenReturn('u1');
        final response = AuthResponse(user: user);
        when(() => goTrue.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => response);

        await repo.signInWithEmailAndPassword('  $_fakeEmail  ', _fakePassword);

        // Vérifie l'appel avec les valeurs exactes (email trimmé)
        verify(() => goTrue.signInWithPassword(
              email: _fakeEmail,
              password: _fakePassword,
            )).called(1);
      });

      test('retourne l\'utilisateur si connexion réussie', () async {
        final user = _MockUser();
        when(() => user.id).thenReturn('u2');
        when(() => goTrue.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => AuthResponse(user: user));

        final result =
            await repo.signInWithEmailAndPassword(_fakeEmail, _fakePassword);

        expect(result, user);
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('délègue à GoTrue signUp', () async {
        final user = _MockUser();
        when(() => user.id).thenReturn('new-u');
        when(() => goTrue.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => AuthResponse(user: user));

        final result =
            await repo.createUserWithEmailAndPassword(_fakeEmail, _fakePassword);

        expect(result, user);
        verify(() => goTrue.signUp(
              email: _fakeEmail,
              password: _fakePassword,
            )).called(1);
      });
    });

    group('signOut', () {
      test('appelle GoTrue signOut', () async {
        when(() => goTrue.signOut()).thenAnswer((_) async {});

        await repo.signOut();

        verify(() => goTrue.signOut()).called(1);
      });
    });

    group('signInAnonymously', () {
      test('délègue à GoTrue signInAnonymously et retourne l\'utilisateur', () async {
        final user = _MockUser();
        when(() => user.id).thenReturn('anon-uid');
        when(() => goTrue.signInAnonymously())
            .thenAnswer((_) async => AuthResponse(user: user));

        final result = await repo.signInAnonymously();

        expect(result, user);
        verify(() => goTrue.signInAnonymously()).called(1);
      });

      test('propage l\'exception AuthException si GoTrue échoue', () async {
        when(() => goTrue.signInAnonymously())
            .thenThrow(const AuthException('Connexion anonyme désactivée'));

        await expectLater(
          () => repo.signInAnonymously(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('upgradeAnonymousToEmail', () {
      test('appelle GoTrue updateUser avec email trimmé et mot de passe', () async {
        final user = _MockUser();
        when(() => user.id).thenReturn('anon-uid');

        final userResponse = _MockUserResponse();
        when(() => userResponse.user).thenReturn(user);
        when(() => goTrue.updateUser(any()))
            .thenAnswer((_) async => userResponse);

        final result = await repo.upgradeAnonymousToEmail(
          email: '  $_fakeEmail  ',
          password: _fakePassword,
        );

        expect(result, user);
        final captured =
            verify(() => goTrue.updateUser(captureAny())).captured.single
                as UserAttributes;
        expect(captured.email, _fakeEmail);
        expect(captured.password, _fakePassword);
      });

      test('propage l\'exception AuthException si la mise à niveau échoue', () async {
        when(() => goTrue.updateUser(any()))
            .thenThrow(const AuthException('Email déjà utilisé'));

        await expectLater(
          () => repo.upgradeAnonymousToEmail(
            email: _fakeEmail,
            password: _fakePassword,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
