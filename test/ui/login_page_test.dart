import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/ui/pages/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

Widget _buildLogin(AuthViewModel vm) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: vm,
    child: const MaterialApp(
      home: LoginPage(),
      onGenerateRoute: _generateRoute,
    ),
  );
}

Route<dynamic>? _generateRoute(RouteSettings settings) {
  return MaterialPageRoute(
    builder: (_) => Scaffold(body: Text(settings.name ?? '')),
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
    // Désactive le téléchargement de polices Google en mode test
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LoginPage', () {
    testWidgets('affiche le titre Sameva et les champs du formulaire',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildLogin(vm));

      expect(find.text('Sameva'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets('affiche une erreur si email vide à la soumission',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildLogin(vm));

      // Soumet sans rien remplir
      await tester.tap(find.text('Connexion'));
      await tester.pump();

      expect(find.text('Indiquez votre email'), findsOneWidget);
    });

    testWidgets('affiche une erreur si email sans @', (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildLogin(vm));

      await tester.enterText(
          find.byType(TextFormField).first, 'emailsansarobase');
      await tester.tap(find.text('Connexion'));
      await tester.pump();

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('affiche une erreur si mot de passe vide', (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildLogin(vm));

      await tester.enterText(
          find.byType(TextFormField).first, 'valid@email.fr');
      await tester.tap(find.text('Connexion'));
      await tester.pump();

      expect(find.text('Indiquez votre mot de passe'), findsOneWidget);
    });

    testWidgets('affiche le message d\'erreur du ViewModel', (tester) async {
      final repo = _MockAuthRepository();
      final vm = _makeVm(repo);
      when(() => repo.signInWithEmailAndPassword(any(), any()))
          .thenThrow(Exception('Email ou mot de passe incorrect'));
      await tester.pumpWidget(_buildLogin(vm));

      await tester.enterText(
          find.byType(TextFormField).first, 'bad@email.fr');
      await tester.enterText(
          find.byType(TextFormField).last, 'wrongpassword');
      await tester.tap(find.text('Connexion'));
      await tester.pump();
      // Attend la fin de l'opération async
      await tester.pump();

      expect(vm.errorMessage, isNotNull);
    });

    testWidgets('le bouton Connexion est désactivé pendant le chargement',
        (tester) async {
      final repo = _MockAuthRepository();
      // Completer qui ne se résout pas immédiatement — simule un appel réseau
      final completer = Completer<User?>();
      when(() => repo.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) => completer.future);
      final vm = _makeVm(repo);
      await tester.pumpWidget(_buildLogin(vm));

      await tester.enterText(
          find.byType(TextFormField).first, 'ok@email.fr');
      await tester.enterText(
          find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('Connexion'));
      await tester.pump(); // lance l'opération async, isLoading = true

      // Le bouton doit être désactivé (onPressed == null)
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Résout le Completer pour éviter les timers en suspens
      completer.complete(null);
      await tester.pump();
    });

    // ── Bouton invité ──────────────────────────────────────────────────────

    testWidgets('affiche le bouton "Continuer en tant qu\'invité"',
        (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildLogin(vm));

      expect(
        find.byKey(const Key('btn_continuer_invite')),
        findsOneWidget,
      );
      expect(
        find.text('Continuer en tant qu\'invité'),
        findsOneWidget,
      );
    });

    testWidgets(
        'le bouton invité appelle continueAsGuest() sur AuthViewModel',
        (tester) async {
      final repo = _MockAuthRepository();
      final anonUser = _FakeUser();
      when(() => repo.signInAnonymously())
          .thenAnswer((_) async => anonUser);
      final vm = _makeVm(repo);
      await tester.pumpWidget(_buildLogin(vm));

      await tester.tap(find.byKey(const Key('btn_continuer_invite')));
      await tester.pump();
      await tester.pump();

      verify(() => repo.signInAnonymously()).called(1);
    });

    testWidgets(
        'le bouton invité est désactivé pendant le chargement',
        (tester) async {
      final repo = _MockAuthRepository();
      final completer = Completer<User?>();
      when(() => repo.signInAnonymously())
          .thenAnswer((_) => completer.future);
      final vm = _makeVm(repo);
      await tester.pumpWidget(_buildLogin(vm));

      await tester.tap(find.byKey(const Key('btn_continuer_invite')));
      await tester.pump();

      final btn = tester.widget<TextButton>(
        find.byKey(const Key('btn_continuer_invite')),
      );
      expect(btn.onPressed, isNull);

      completer.complete(null);
      await tester.pump();
    });
  });
}

/// Faux utilisateur anonyme pour les tests du bouton invité.
class _FakeUser extends Fake implements User {
  @override
  String get id => 'anon-fake';

  @override
  bool get isAnonymous => true;
}
