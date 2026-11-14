import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/providers.dart';
import 'package:sameva/data/models/character_model.dart';
import 'package:sameva/ui/widgets/avatar/avatar_joueur.dart';
import 'package:sameva/ui/widgets/character/character_painter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/equipment_view_model.dart';
import 'package:sameva/ui/pages/avatar/avatar_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockUser extends Mock implements User {}

class _MockBox extends Mock implements Box<dynamic> {}

EquipmentViewModel _makeEquipmentVm() {
  final box = _MockBox();
  when(() => box.get(any())).thenReturn(null);
  when(() => box.put(any(), any())).thenAnswer((_) async {});
  return EquipmentViewModel(box);
}

Widget _buildAvatar({
  AuthViewModel? authVm,
  PlayerViewModel? playerVm,
  EquipmentViewModel? equipVm,
}) {
  return ProviderScope(
    overrides: [currentUserIdProvider.overrideWith((ref) => Stream.value('uid-1'))],
    child: MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(
          value: authVm ?? _makeAuthVm()),
      ChangeNotifierProvider<PlayerViewModel>.value(
          value: playerVm ?? _makePlayerVm()),
      ChangeNotifierProvider<EquipmentViewModel>.value(
          value: equipVm ?? _makeEquipmentVm()),
    ],
    child: const MaterialApp(home: AvatarPage()),
  ),
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

    testWidgets('affiche l\'avatar du joueur à la place de l\'initiale', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.bySemanticsLabel('Ton personnage'), findsOneWidget);
      expect(find.text('?'), findsNothing);
    });

    testWidgets('affiche l\'e-mail si utilisateur connecté', (tester) async {
      final user = _MockUser();
      when(() => user.email).thenReturn('test@example.com');
      when(() => user.id).thenReturn('uid-1');

      await tester.pumpWidget(_buildAvatar(authVm: _makeAuthVm(user: user)));
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('apparence : un choix modifie aussitôt l\'avatar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      CharacterPainter peintre() => tester
          .widget<CustomPaint>(
              find.descendant(of: find.byType(AvatarJoueur), matching: find.byType(CustomPaint)).first)
          .painter! as CharacterPainter;
      expect(peintre().appearance.hairStyle, HairStyle.medium);

      await tester.tap(find.byKey(const Key('avatar_coiffure_bun')));
      await tester.tap(find.byKey(const Key('avatar_teint_dark')));
      await tester.tap(find.byKey(const Key('avatar_silhouette_female')));
      await tester.pump();

      expect(peintre().appearance.hairStyle, HairStyle.bun);
      expect(peintre().appearance.skinTone, SkinTone.dark);
      expect(peintre().appearance.gender, CharacterGender.female);
      expect(find.bySemanticsLabel('Teint brune'), findsOneWidget);
    });

    testWidgets('affiche Niv. 1 par défaut sans stats', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.text('Niv. 1'), findsOneWidget);
    });
  });
}
