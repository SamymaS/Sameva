import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockAuthRepository repo;

  AuthViewModel newVm() => AuthViewModel(repo);

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.authStateChanges).thenAnswer(
      (_) => const Stream<AuthState>.empty(),
    );
    when(() => repo.currentUser).thenReturn(null);
  });

  group('AuthViewModel', () {
    test('signInWithEmailAndPassword refuse un email vide', () async {
      final vm = newVm();
      await expectLater(
        () => vm.signInWithEmailAndPassword('', 'secret'),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => repo.signInWithEmailAndPassword(any(), any()));
    });

    test('signInWithEmailAndPassword refuse un mot de passe vide', () async {
      final vm = newVm();
      await expectLater(
        () => vm.signInWithEmailAndPassword('a@b.c', ''),
        throwsA(isA<Exception>()),
      );
    });

    test('createUserWithEmailAndPassword refuse un email sans @', () async {
      final vm = newVm();
      await expectLater(
        () => vm.createUserWithEmailAndPassword('invalid', '123456'),
        throwsA(isA<Exception>()),
      );
    });

    test('createUserWithEmailAndPassword refuse un mot de passe trop court',
        () async {
      final vm = newVm();
      await expectLater(
        () => vm.createUserWithEmailAndPassword('a@b.c', '12345'),
        throwsA(isA<Exception>()),
      );
    });

    test('signInWithEmailAndPassword appelle le repository si les champs sont valides',
        () async {
      final user = _MockUser();
      when(() => user.id).thenReturn('uid-1');
      when(() => repo.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => user);

      final vm = newVm();
      await vm.signInWithEmailAndPassword('hello@test.fr', 'password123');

      expect(vm.user, user);
      expect(vm.errorMessage, isNull);
      verify(() => repo.signInWithEmailAndPassword('hello@test.fr', 'password123'))
          .called(1);
    });

    test('signOut appelle le repository et vide l\'utilisateur', () async {
      final user = _MockUser();
      when(() => user.id).thenReturn('uid-1');
      when(() => repo.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => user);
      when(() => repo.signOut()).thenAnswer((_) async {});

      final vm = newVm();
      await vm.signInWithEmailAndPassword('a@b.c', '123456');
      expect(vm.isAuthenticated, isTrue);

      await vm.signOut();

      expect(vm.isAuthenticated, isFalse);
      verify(() => repo.signOut()).called(1);
    });

    test('clearError remet errorMessage à null', () {
      final vm = newVm();
      vm.clearError();
      expect(vm.errorMessage, isNull);
    });

    // ── continueAsGuest ────────────────────────────────────────────────────
    group('continueAsGuest', () {
      test('appelle repo.signInAnonymously et met à jour _user', () async {
        final anonUser = _MockUser();
        when(() => anonUser.id).thenReturn('anon-42');
        when(() => anonUser.isAnonymous).thenReturn(true);
        when(() => repo.signInAnonymously())
            .thenAnswer((_) async => anonUser);

        final vm = newVm();
        await vm.continueAsGuest();

        expect(vm.user, anonUser);
        expect(vm.isAuthenticated, isTrue);
        expect(vm.errorMessage, isNull);
        verify(() => repo.signInAnonymously()).called(1);
      });

      test('isGuest retourne true après connexion anonyme', () async {
        final anonUser = _MockUser();
        when(() => anonUser.id).thenReturn('anon-42');
        when(() => anonUser.isAnonymous).thenReturn(true);
        when(() => repo.signInAnonymously())
            .thenAnswer((_) async => anonUser);

        final vm = newVm();
        expect(vm.isGuest, isFalse);

        await vm.continueAsGuest();

        expect(vm.isGuest, isTrue);
      });

      test('isLoading passe à true pendant l\'appel puis revient à false', () async {
        final anonUser = _MockUser();
        when(() => anonUser.id).thenReturn('anon-1');
        when(() => anonUser.isAnonymous).thenReturn(true);

        var loadingSeenTrue = false;
        when(() => repo.signInAnonymously()).thenAnswer((_) async {
          // À ce stade, isLoading doit déjà être true
          return anonUser;
        });

        final vm = newVm();
        vm.addListener(() {
          if (vm.isLoading) loadingSeenTrue = true;
        });

        await vm.continueAsGuest();

        expect(loadingSeenTrue, isTrue);
        expect(vm.isLoading, isFalse);
      });

      test('propage l\'erreur et stocke errorMessage sur AuthException', () async {
        when(() => repo.signInAnonymously())
            .thenThrow(const AuthException('Connexion anonyme désactivée'));

        final vm = newVm();
        await expectLater(
          () => vm.continueAsGuest(),
          throwsA(isA<AuthException>()),
        );
        expect(vm.errorMessage, isNotNull);
        expect(vm.isLoading, isFalse);
      });
    });

    // ── saveGuestAccount ───────────────────────────────────────────────────
    group('saveGuestAccount', () {
      test('refuse un email vide', () async {
        final vm = newVm();
        await expectLater(
          () => vm.saveGuestAccount(email: '', password: 'secure123'),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => repo.upgradeAnonymousToEmail(
            email: any(named: 'email'), password: any(named: 'password')));
      });

      test('refuse un email sans @', () async {
        final vm = newVm();
        await expectLater(
          () => vm.saveGuestAccount(email: 'invalide', password: 'secure123'),
          throwsA(isA<Exception>()),
        );
      });

      test('refuse un mot de passe trop court (< 6 caractères)', () async {
        final vm = newVm();
        await expectLater(
          () => vm.saveGuestAccount(email: 'a@b.c', password: '12345'),
          throwsA(isA<Exception>()),
        );
      });

      test('appelle upgradeAnonymousToEmail si les champs sont valides', () async {
        final upgradedUser = _MockUser();
        when(() => upgradedUser.id).thenReturn('anon-42');
        when(() => upgradedUser.isAnonymous).thenReturn(false);
        when(() => repo.upgradeAnonymousToEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => upgradedUser);

        final vm = newVm();
        await vm.saveGuestAccount(email: 'hello@test.fr', password: 'secure123');

        expect(vm.user, upgradedUser);
        expect(vm.errorMessage, isNull);
        verify(() => repo.upgradeAnonymousToEmail(
              email: 'hello@test.fr',
              password: 'secure123',
            )).called(1);
      });

      test('propage l\'erreur et stocke errorMessage sur AuthException', () async {
        when(() => repo.upgradeAnonymousToEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthException('Email déjà utilisé'));

        final vm = newVm();
        await expectLater(
          () => vm.saveGuestAccount(email: 'taken@test.fr', password: 'secure123'),
          throwsA(isA<AuthException>()),
        );
        expect(vm.errorMessage, isNotNull);
        expect(vm.isLoading, isFalse);
      });
    });

    // ── isGuest ────────────────────────────────────────────────────────────
    group('isGuest', () {
      test('retourne false si aucun utilisateur connecté', () {
        final vm = newVm();
        expect(vm.isGuest, isFalse);
      });

      test('retourne false pour un utilisateur email (isAnonymous == false)', () async {
        final emailUser = _MockUser();
        when(() => emailUser.id).thenReturn('email-uid');
        when(() => emailUser.isAnonymous).thenReturn(false);
        when(() => repo.signInWithEmailAndPassword(any(), any()))
            .thenAnswer((_) async => emailUser);

        final vm = newVm();
        await vm.signInWithEmailAndPassword('a@b.c', 'password');

        expect(vm.isGuest, isFalse);
      });
    });
  });
}
