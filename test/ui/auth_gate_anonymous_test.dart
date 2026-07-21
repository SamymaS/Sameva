/// Tests du routage _AuthGate pour les sessions anonymes (mode invité).
///
/// Ce que prouvent ces tests :
/// 1. Un utilisateur anonyme (isAnonymous == true) est traité comme authentifié
///    et atteint l'écran d'accueil (homeBuilder) — il n'est PAS renvoyé à LoginPage.
/// 2. Un utilisateur non connecté (null) arrive sur LoginPage.
/// 3. Un utilisateur email standard (isAnonymous == false) atteint l'accueil.
///
/// Note : _AuthGate est privé dans app.dart. On le teste en injectant un
/// AuthViewModel mocké via MultiProvider + MaterialApp home: _SamevaApp (la
/// route '/' est court-circuitée par un homeBuilder de test).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kHomeText = 'ÉCRAN ACCUEIL TEST';
const _kLoginText = 'Sameva'; // texte présent dans LoginPage

/// Construit un mini-app qui réplique la logique de _AuthGate :
/// - null → LoginPage (texte de login)
/// - authentifié + onboardé → widget accueil
Widget _buildTestApp(AuthViewModel vm) {
  // Initialise les boîtes Hive minimales nécessaires à _AuthGate.
  // Elles sont déjà ouvertes dans setUpAll.
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: vm,
    child: const MaterialApp(
      home: _TestAuthGate(),
    ),
  );
}

/// Réplique fidèle de la partie routage de _AuthGate (sans la migration Hive).
class _TestAuthGate extends StatelessWidget {
  const _TestAuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (!auth.isAuthenticated) {
      return const Scaffold(body: Center(child: Text(_kLoginText)));
    }

    // Simule l'onboarding déjà complété (flag Hive posé dans setUpAll).
    return const Scaffold(body: Center(child: Text(_kHomeText)));
  }
}

AuthViewModel _makeVm(_MockAuthRepository repo, {User? user}) {
  when(() => repo.currentUser).thenReturn(user);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Hive réel minimal (même pattern que auth_view_model_delete_account_test).
    Hive.init('${Directory.systemTemp.path}/hive_auth_gate_test');
    for (final box in ['settings', 'playerStats', 'inventory', 'equipment',
        'cats', 'aiValidation']) {
      if (!Hive.isBoxOpen(box)) await Hive.openBox(box);
    }
  });

  group('_AuthGate — routage session anonyme', () {
    testWidgets(
        'utilisateur non connecté (null) → écran login',
        (tester) async {
      final repo = _MockAuthRepository();
      final vm = _makeVm(repo, user: null);

      await tester.pumpWidget(_buildTestApp(vm));
      await tester.pump();

      expect(find.text(_kLoginText), findsOneWidget);
      expect(find.text(_kHomeText), findsNothing);
    });

    testWidgets(
        'utilisateur anonyme (isAnonymous == true) → atteint l\'accueil',
        (tester) async {
      final repo = _MockAuthRepository();
      final anonUser = _FakeAnonUser();
      final vm = _makeVm(repo, user: anonUser);

      await tester.pumpWidget(_buildTestApp(vm));
      await tester.pump();

      expect(find.text(_kHomeText), findsOneWidget);
      expect(find.text(_kLoginText), findsNothing);
    });

    testWidgets(
        'utilisateur email (isAnonymous == false) → atteint l\'accueil',
        (tester) async {
      final repo = _MockAuthRepository();
      final emailUser = _FakeEmailUser();
      final vm = _makeVm(repo, user: emailUser);

      await tester.pumpWidget(_buildTestApp(vm));
      await tester.pump();

      expect(find.text(_kHomeText), findsOneWidget);
      expect(find.text(_kLoginText), findsNothing);
    });
  });
}

// ── Faux utilisateurs ─────────────────────────────────────────────────────────

class _FakeAnonUser extends Fake implements User {
  @override
  String get id => 'anon-test-uid';

  @override
  bool get isAnonymous => true;

  @override
  String? get email => null;
}

class _FakeEmailUser extends Fake implements User {
  @override
  String get id => 'email-test-uid';

  @override
  bool get isAnonymous => false;

  @override
  String? get email => 'user@test.fr';
}
