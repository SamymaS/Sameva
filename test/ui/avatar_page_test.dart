import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/providers.dart';
import 'package:sameva/data/models/character_model.dart';
import 'package:sameva/ui/widgets/avatar/avatar_joueur.dart';
import 'package:sameva/core/avatar/apparence_avatar.dart';
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

    testWidgets('cabine : onglets, vignettes et choix enregistrés', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      CharacterAppearance apparence() =>
          ProviderScope.containerOf(tester.element(find.byType(AvatarPage))).read(apparenceAvatarProvider);
      // Le grand personnage est le premier avatar de la page.
      AvatarJoueur grand() => tester.widget<AvatarJoueur>(find.byType(AvatarJoueur).first);
      expect(grand().apparence.hairStyle, HairStyle.medium);

      await tester.tap(find.byKey(const Key('avatar_silhouette_female')));
      await tester.tap(find.byKey(const Key('avatar_onglet_coiffure')));
      await tester.pump();
      expect(find.bySemanticsLabel('Chignon'), findsOneWidget);
      await tester.tap(find.byKey(const Key('avatar_coiffure_bun')));
      await tester.tap(find.byKey(const Key('avatar_onglet_teint')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('avatar_teint_dark')));
      await tester.pump();

      expect(apparence().gender, CharacterGender.female);
      expect(apparence().hairStyle, HairStyle.bun);
      expect(apparence().skinTone, SkinTone.dark);
      expect(grand().apparence.hairStyle, HairStyle.bun, reason: 'le grand personnage suit aussitôt');
    });

    testWidgets('cabine : flèches et planche des vues font tourner le personnage', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      int angle() => tester.widget<AvatarJoueur>(find.byType(AvatarJoueur).first).angle;
      expect(angle(), 0);
      await tester.tap(find.bySemanticsLabel('Tourner vers la droite'));
      await tester.pump();
      expect(angle(), 1);
      await tester.tap(find.bySemanticsLabel('Tourner vers la gauche'));
      await tester.tap(find.bySemanticsLabel('Tourner vers la gauche'));
      await tester.pump();
      expect(angle(), 7);
      await tester.tap(find.byKey(const Key('avatar_vue_4')));
      await tester.pump();
      expect(angle(), 4, reason: 'vue de dos');
    });

    testWidgets('affiche Niv. 1 par défaut sans stats', (tester) async {
      await tester.pumpWidget(_buildAvatar());
      await tester.pump();

      expect(find.text('Niv. 1'), findsOneWidget);
    });
  });
}
