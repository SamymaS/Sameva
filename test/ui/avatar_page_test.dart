import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/ui/pages/avatar/avatar_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockUser extends Mock implements User {}

Widget _buildAvatar({
  AuthViewModel? authVm,
  PlayerViewModel? playerVm,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(
          value: authVm ?? _makeAuthVm()),
      ChangeNotifierProvider<PlayerViewModel>.value(
          value: playerVm ?? _makePlayerVm()),
    ],
    child: const MaterialApp(home: AvatarPage()),
  );
}

AuthViewModel _makeAuthVm({User? user}) {
  final repo = _MockAuthRepository();
  when(() => repo.currentUser).thenReturn(user);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

PlayerViewModel _makePlayerVm() {
  final repo = _MockPlayerRepository();
  when(() => repo.loadLocalStats()).thenReturn(PlayerStats());
  return PlayerViewModel(repo);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AvatarPage', () {
    testWidgets('affiche le titre Personnage', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      expect(find.text('Personnage'), findsOneWidget);
    });

    testWidgets('affiche les barres XP, HP, Morale', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.text('Expérience'), findsOneWidget);
      expect(find.text('Points de vie'), findsOneWidget);
      expect(find.text('Morale'), findsOneWidget);
    });

    testWidgets('affiche les tuiles de stats (Série, Or, Cristaux, Quêtes)',
        (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.text('Série'), findsOneWidget);
      expect(find.text('Or'), findsOneWidget);
      expect(find.text('Cristaux'), findsOneWidget);
      expect(find.text('Quêtes'), findsOneWidget);
    });

    testWidgets('affiche ? comme initiale si pas d\'email', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('affiche l\'initiale de l\'email si utilisateur connecté',
        (tester) async {
      final user = _MockUser();
      when(() => user.email).thenReturn('test@example.com');
      when(() => user.id).thenReturn('uid-1');

      await tester.pumpWidget(_buildAvatar(authVm: _makeAuthVm(user: user)));
      await tester.pump();

      expect(find.text('T'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('affiche Niv. 1 par défaut sans stats', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.text('Niv. 1'), findsOneWidget);
    });
  });
}
