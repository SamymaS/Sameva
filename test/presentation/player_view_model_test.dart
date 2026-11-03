import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/game_api.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockGameApi extends Mock implements GameApi {}

PlayerServerState _state(PlayerStats stats, {int energy = 3, bool premium = false}) =>
    PlayerServerState(
      stats: stats,
      xpForNextLevel: 150 * stats.level,
      energy: energy,
      premium: premium,
      gacha: const {'objets': GachaBannerState(sinceEpic: 4, sinceLegendary: 4, freeAvailable: false)},
    );

void main() {
  late Directory hiveDir;
  late _MockPlayerRepository repo;
  late _MockGameApi api;
  late PlayerViewModel vm;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(PlayerStats());
    hiveDir = await Directory.systemTemp.createTemp('sameva_player_vm_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
  });

  setUp(() {
    repo = _MockPlayerRepository();
    api = _MockGameApi();
    when(() => repo.api).thenReturn(api);
    when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
    vm = PlayerViewModel(repo);
  });

  group('PlayerViewModel (Sprint 1 : serveur autoritaire)', () {
    test('experienceForLevel suit la formule serveur (150 × niveau)', () {
      expect(vm.experienceForLevel(1), 150);
      expect(vm.experienceForLevel(2), 300);
    });

    test('loadPlayerStats affiche le cache puis adopte l\'état serveur', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(gold: 999999));
      when(() => repo.fetchServerState())
          .thenAnswer((_) async => _state(PlayerStats(gold: 40, seals: 2), energy: 5));

      await vm.loadPlayerStats('u');

      expect(vm.stats?.gold, 40, reason: 'le serveur écrase toute valeur locale');
      expect(vm.stats?.seals, 2);
      expect(vm.energy, 5);
      expect(vm.gacha['objets']?.freeAvailable, isFalse);
      verify(() => repo.saveLocalStats(any())).called(1);
    });

    test('hors-ligne : le cache reste affiché, rien n\'est écrit côté serveur', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(streak: 7, gold: 12));
      when(() => repo.fetchServerState()).thenAnswer((_) async => throw Exception('hors-ligne'));

      await vm.loadPlayerStats('u');

      expect(vm.stats?.gold, 12);
      expect(vm.hasStreakBonus, isTrue);
      verifyNever(() => repo.saveLocalStats(any()));
    });

    test('completeQuest passe par le serveur puis rafraîchit', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats());
      when(() => repo.fetchServerState())
          .thenAnswer((_) async => _state(PlayerStats(gold: 20, totalExperience: 15)));
      when(() => api.completeQuest('q1')).thenAnswer((_) async => QuestRewardResult.fromJson(
          const {'quest_id': 'q1', 'mode': 'declaratif', 'xp': 15, 'gold': 20, 'level_before': 1, 'level_after': 1}));

      final result = await vm.completeQuest('q1');

      expect(result.xp, 15);
      expect(vm.stats?.gold, 20);
      verify(() => api.completeQuest('q1')).called(1);
      verify(() => repo.fetchServerState()).called(1);
    });

    test('spend propage le refus serveur sans modifier l\'état local', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(gold: 5));
      when(() => repo.fetchServerState()).thenAnswer((_) async => throw Exception('hors-ligne'));
      await vm.loadPlayerStats('u');
      when(() => api.spend(
            resource: any(named: 'resource'),
            amount: any(named: 'amount'),
            reason: any(named: 'reason'),
            ref: any(named: 'ref'),
          )).thenThrow(const GameApiException('solde_insuffisant'));

      await expectLater(
        vm.spend(resource: 'gold', amount: 100, reason: 'marche_achat'),
        throwsA(isA<GameApiException>().having((e) => e.code, 'code', 'solde_insuffisant')),
      );
      expect(vm.stats?.gold, 5);
    });

    test('les succès locaux survivent au rafraîchissement serveur', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(totalQuestsCompleted: 1));
      when(() => repo.fetchServerState()).thenAnswer((_) async => throw Exception('hors-ligne'));
      await vm.loadPlayerStats('u');
      final unlocked = await vm.checkAndUnlockAchievements('u');
      expect(unlocked, contains('first_quest'));

      when(() => repo.fetchServerState())
          .thenAnswer((_) async => _state(PlayerStats(totalQuestsCompleted: 1)));
      await vm.refresh();

      expect(vm.stats?.achievements.containsKey('first_quest'), isTrue);
    });

    test('reset vide l\'état (changement de compte)', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(gold: 3));
      when(() => repo.fetchServerState()).thenAnswer((_) async => _state(PlayerStats(gold: 3)));
      await vm.loadPlayerStats('u');

      vm.reset();

      expect(vm.stats, isNull);
      expect(vm.energy, 0);
      expect(vm.gacha, isEmpty);
    });
  });
}
