import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/ui/pages/auth/save_guest_account_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

Widget _buildSaveGuestAccount(AuthViewModel vm) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: vm,
    child: const MaterialApp(
      home: SaveGuestAccountPage(),
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
    // Désactive le téléchargement de polices Google en mode test
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SaveGuestAccountPage', () {
    // ── Bouton Google ──────────────────────────────────────────────────────

    testWidgets('affiche le bouton "Continuer avec Google"', (tester) async {
      final vm = _makeVm(_MockAuthRepository());
      await tester.pumpWidget(_buildSaveGuestAccount(vm));

      expect(
        find.byKey(const Key('btn_continuer_google_invite')),
        findsOneWidget,
      );
      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets(
        'le bouton Google appelle signInWithGoogle() sur AuthViewModel',
        (tester) async {
      final repo = _MockAuthRepository();
      final googleUser = _FakeUser();
      when(() => repo.signInWithGoogle())
          .thenAnswer((_) async => googleUser);
      final vm = _makeVm(repo);
      await tester.pumpWidget(_buildSaveGuestAccount(vm));

      await tester
          .ensureVisible(find.byKey(const Key('btn_continuer_google_invite')));
      await tester.tap(find.byKey(const Key('btn_continuer_google_invite')));
      await tester.pump();
      await tester.pump();

      verify(() => repo.signInWithGoogle()).called(1);
    });

    testWidgets(
        'le bouton Google est désactivé pendant le chargement',
        (tester) async {
      final repo = _MockAuthRepository();
      final completer = Completer<User?>();
      when(() => repo.signInWithGoogle())
          .thenAnswer((_) => completer.future);
      final vm = _makeVm(repo);
      await tester.pumpWidget(_buildSaveGuestAccount(vm));

      await tester
          .ensureVisible(find.byKey(const Key('btn_continuer_google_invite')));
      await tester.tap(find.byKey(const Key('btn_continuer_google_invite')));
      await tester.pump();

      final btn = tester.widget<OutlinedButton>(
        find.byKey(const Key('btn_continuer_google_invite')),
      );
      expect(btn.onPressed, isNull);

      completer.complete(null);
      await tester.pump();
    });
  });
}

/// Faux utilisateur Google pour les tests du bouton Google.
class _FakeUser extends Fake implements User {
  @override
  String get id => 'google-fake';

  @override
  bool get isAnonymous => false;
}
