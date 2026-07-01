/// Tests de lifecycle auth pour PlayerViewModel — Phase P1.
///
/// Ce que prouvent ces tests :
/// 1. onSignedOut → reset() : les stats sont nulles automatiquement.
/// 2. onSignedIn  → loadPlayerStats(uid) : les stats sont rechargées automatiquement.
/// 3. Garde idempotente : si les stats sont déjà chargées, onSignedIn ne recharge pas.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';

class _MockPlayerRepo extends Mock implements PlayerRepository {}

const _testUserId = 'uid-lifecycle-player-1';

void main() {
  late _MockPlayerRepo repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(PlayerStats());
  });

  setUp(() {
    repo = _MockPlayerRepo();
    // Stub défensif pour syncToSupabase (cas 2 : pas de remote).
    when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});
    when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedOut → reset()
  // ────────────────────────────────────────────────────────────────────────────

  group('PlayerViewModel.onSignedOut → reset()', () {
    test('vide les stats en mémoire à la réception du signal', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);

      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(level: 5, gold: 100));
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);

      final vm = PlayerViewModel(
        repo,
        onSignedOut: signedOutCtrl.stream,
        testUserId: _testUserId,
      );

      // Charger des stats pour avoir un état non null.
      await vm.loadPlayerStats(_testUserId);
      expect(vm.stats, isNotNull, reason: 'Précondition : stats chargées');
      expect(vm.isInitialized, isTrue);

      // Émettre onSignedOut → reset() synchrone.
      signedOutCtrl.add(null);

      expect(vm.stats, isNull,
          reason: 'onSignedOut doit remettre _stats à null');
      expect(vm.isInitialized, isFalse);

      await signedOutCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedIn → loadPlayerStats(uid)
  // ────────────────────────────────────────────────────────────────────────────

  group('PlayerViewModel.onSignedIn → loadPlayerStats(uid)', () {
    test('charge les stats après réception du signal', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      when(() => repo.loadLocalStats())
          .thenReturn(PlayerStats(level: 3, gold: 50));
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);

      final vm = PlayerViewModel(
        repo,
        onSignedIn: signedInCtrl.stream,
        testUserId: _testUserId,
      );

      // Précondition : stats non chargées.
      expect(vm.stats, isNull);

      signedInCtrl.add(null);
      // loadPlayerStats est async → laisser les microtasks s'exécuter.
      await Future<void>.delayed(Duration.zero);

      expect(vm.stats, isNotNull,
          reason: 'onSignedIn doit déclencher loadPlayerStats');
      expect(vm.stats?.level, 3);

      await signedInCtrl.close();
      vm.dispose();
    });

    test('garde idempotente : ne recharge pas si les stats sont déjà chargées',
        () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(level: 7));
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);

      final vm = PlayerViewModel(
        repo,
        onSignedIn: signedInCtrl.stream,
        testUserId: _testUserId,
      );

      // Chargement manuel préalable (simule boot avec session persistée).
      await vm.loadPlayerStats(_testUserId);
      expect(vm.stats, isNotNull, reason: 'Précondition : stats déjà chargées');

      // Réinitialiser le compteur d'appels.
      clearInteractions(repo);

      // onSignedIn doit être bloqué par la garde _stats != null.
      signedInCtrl.add(null);
      await Future<void>.delayed(Duration.zero);

      // loadLocalStats et fetchRemoteStats NE doivent PAS avoir été rappelés.
      verifyNever(() => repo.loadLocalStats());
      verifyNever(() => repo.fetchRemoteStats(any()));

      await signedInCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Cycle complet : onSignedOut puis onSignedIn
  // ────────────────────────────────────────────────────────────────────────────

  group('PlayerViewModel — cycle signOut puis signIn', () {
    test('vide puis recharge correctement', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(level: 4));
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);

      final vm = PlayerViewModel(
        repo,
        onSignedOut: signedOutCtrl.stream,
        onSignedIn: signedInCtrl.stream,
        testUserId: _testUserId,
      );

      await vm.loadPlayerStats(_testUserId);
      expect(vm.stats, isNotNull, reason: 'Chargement initial');

      // Logout.
      signedOutCtrl.add(null);
      expect(vm.stats, isNull, reason: 'Stats nulles après onSignedOut');

      // Reconnexion.
      signedInCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(vm.stats, isNotNull,
          reason: 'Stats rechargées après onSignedIn');

      await signedOutCtrl.close();
      await signedInCtrl.close();
      vm.dispose();
    });
  });
}
