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
  });
}
