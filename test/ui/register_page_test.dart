import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/ui/pages/auth/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUser extends Mock implements User {}

Widget _buildRegister(AuthViewModel vm) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: vm,
    child: MaterialApp(
      home: const RegisterPage(),
      onGenerateRoute: (s) => MaterialPageRoute(
        builder: (_) => Scaffold(body: Text(s.name ?? '')),
      ),
    ),
  );
}

AuthViewModel _makeVm(_MockAuthRepository repo) {
  when(() => repo.currentUser).thenReturn(null);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RegisterPage', () {
    testWidgets('affiche le titre et les trois champs du formulaire',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildRegister(vm));

      expect(find.text('Créer un compte'), findsWidgets); // AppBar + bouton
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Déjà un compte ? Se connecter'), findsOneWidget);
    });

    testWidgets('affiche une erreur si email vide à la soumission',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildRegister(vm));

      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      expect(find.text('Indiquez votre email'), findsOneWidget);
    });

    testWidgets('affiche une erreur si email sans @', (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildRegister(vm));

      await tester.enterText(
          find.byType(TextFormField).at(0), 'emailsansarobase');
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('affiche une erreur si mot de passe trop court',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildRegister(vm));

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      expect(find.text('Minimum 6 caractères'), findsOneWidget);
    });

    testWidgets('affiche une erreur si mots de passe différents',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildRegister(vm));

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.enterText(find.byType(TextFormField).at(2), 'password2');
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      expect(find.text('Les mots de passe ne correspondent pas'),
          findsOneWidget);
    });

    testWidgets('affiche le message d\'erreur du ViewModel', (tester) async {
      final repo = _MockAuthRepository();
      final vm = _makeVm(repo);
      when(() => repo.createUserWithEmailAndPassword(any(), any()))
          .thenThrow(Exception('Cet email est déjà utilisé'));
      await tester.pumpWidget(_buildRegister(vm));

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.enterText(find.byType(TextFormField).at(2), 'password1');
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();
      await tester.pump();

      expect(vm.errorMessage, isNotNull);
    });

    testWidgets('le bouton est désactivé pendant le chargement',
        (tester) async {
      final repo = _MockAuthRepository();
      final completer = Completer<User?>();
      when(() => repo.createUserWithEmailAndPassword(any(), any()))
          .thenAnswer((_) => completer.future);
      final vm = _makeVm(repo);
      await tester.pumpWidget(_buildRegister(vm));

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.enterText(find.byType(TextFormField).at(2), 'password1');
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      completer.complete(null);
      await tester.pump();
    });
  });
}
