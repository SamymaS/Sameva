import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/ui/pages/invocation/invocation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockBox extends Mock implements Box<dynamic> {}

class _MockUser extends Mock implements User {}

Widget _buildInvocationTab() {
  final authRepo = _MockAuthRepository();
  final mockUser = _MockUser();
  when(() => mockUser.id).thenReturn('u1');
  when(() => mockUser.email).thenReturn('test@sameva.app');
  when(() => authRepo.currentUser).thenReturn(mockUser);
  when(() => authRepo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  final authVm = AuthViewModel(authRepo);

  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats(crystals: 200));
  when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});
  final playerVm = PlayerViewModel(playerRepo);

  final invBox = _MockBox();
  when(() => invBox.get(any())).thenReturn(null);
  when(() => invBox.put(any(), any())).thenAnswer((_) async {});
  final invVm = InventoryViewModel(invBox);

  final catBox = _MockBox();
  when(() => catBox.get(any())).thenReturn(null);
  when(() => catBox.put(any(), any())).thenAnswer((_) async {});
  final catVm = CatViewModel(catBox);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ChangeNotifierProvider<PlayerViewModel>.value(value: playerVm),
      ChangeNotifierProvider<InventoryViewModel>.value(value: invVm),
      ChangeNotifierProvider<CatViewModel>.value(value: catVm),
    ],
    child: const MaterialApp(home: Scaffold(body: InvocationTab())),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    final dir =
        await Directory.systemTemp.createTemp('hive_invocation_countdown_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  // ── Note d'architecture de test ────────────────────────────────────────
  // testWidgets s'exécute dans une zone FakeAsync : l'horloge (et donc les
  // Timer) y est virtuelle, pilotée par tester.pump(Duration). En revanche,
  // Hive.box(...).put()/delete() déclenche une vraie écriture disque dont le
  // callback de complétion tourne sur la boucle d'événements RÉELLE, que
  // FakeAsync ne fait jamais avancer → un `await` sur une écriture Hive
  // deadlocke dans la zone fake. On enveloppe donc TOUTE écriture Hive dans
  // tester.runAsync() (zone réelle). Les lectures Hive (.get) sont synchrones
  // et se font sans souci pendant le build.
  //
  // Le Timer.periodic du compte à rebours, lui, RESTE dans la zone fake : il
  // ne bloque pas pump() (il est simplement piloté par l'horloge virtuelle) ;
  // il suffit de ne jamais appeler pumpAndSettle() et de disposer le widget en
  // fin de test pour l'annuler (sinon « Timer still pending »).

  group('InvocationTab — compte à rebours tirage gratuit', () {
    // Test 1 : sans tirage récent → bouton "Gratuit" visible, aucun timer
    // démarré (_canUseFree == true → return early dans _startCountdownIfNeeded).
    testWidgets('affiche "Gratuit" quand aucun tirage n\'a été effectué',
        (tester) async {
      await tester.runAsync(() => Hive.box('settings').delete('lastFreePullAt'));

      await tester.pumpWidget(_buildInvocationTab());
      await tester.pump();

      expect(find.text('Gratuit'), findsOneWidget);
    });

    // Test 2 : un tirage gratuit récent → le bouton affiche le compte à
    // rebours (et non "Gratuit").
    testWidgets(
        'affiche le compte à rebours quand un tirage gratuit a déjà été utilisé',
        (tester) async {
      final lastPull =
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      await tester
          .runAsync(() => Hive.box('settings').put('lastFreePullAt', lastPull));

      await tester.pumpWidget(_buildInvocationTab());
      await tester.pump();

      // Le bouton affiche le temps restant, pas "Gratuit".
      expect(find.text('Gratuit'), findsNothing);
      // ~23h restants → format "23h 0min" (contient 'h').
      expect(find.textContaining('h'), findsWidgets);

      // Dispose → annule le Timer.periodic (évite le « Timer still pending »).
      await tester.pumpWidget(const SizedBox());
    });

    // Test 3 : le Timer.periodic tourne réellement puis est annulé au dispose.
    //
    // Preuve du "ça décrémente tout seul" (et non plus au-tap) : on avance
    // l'horloge FakeAsync de plusieurs secondes ; à chaque tic le callback
    // s'exécute et appelle setState() sur le widget monté, sans exception.
    // Preuve du "pas de fuite" : on remplace l'arbre → dispose() →
    // _countdownTimer.cancel(). Si le cancel() manquait, le framework de test
    // ferait échouer le test avec un « Timer still pending » en fin de run.
    //
    // Note : le format d'affichage est grossier (h/min) et _freeTimeRemaining
    // lit le vrai DateTime.now() (non simulé par FakeAsync), donc la valeur
    // texte ne change pas à la seconde près dans un test widget. Ce test
    // prouve donc le MÉCANISME (tic périodique + rebuild + annulation), qui
    // est précisément ce qui manquait et gelait l'affichage.
    testWidgets('le Timer.periodic tourne puis est annulé au dispose (pas de fuite)',
        (tester) async {
      final lastPull =
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      await tester
          .runAsync(() => Hive.box('settings').put('lastFreePullAt', lastPull));

      await tester.pumpWidget(_buildInvocationTab());
      await tester.pump();

      // Laisse le Timer.periodic (1 s) se déclencher plusieurs fois.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      // Toujours en mode compte à rebours.
      expect(find.text('Gratuit'), findsNothing);

      // Dispose → doit annuler le timer.
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });
}
