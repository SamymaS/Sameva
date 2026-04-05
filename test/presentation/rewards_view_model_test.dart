import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/rewards_view_model.dart';

class _MockPlayerRepo extends Mock implements PlayerRepository {}

void main() {
  late Directory hiveDir;
  late _MockPlayerRepo repo;
  late PlayerViewModel playerVm;
  late RewardsViewModel rewardsVm;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(PlayerStats());
    hiveDir = await Directory.systemTemp.createTemp('sameva_rewards_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('settings')) {
      await Hive.box('settings').close();
    }
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    repo = _MockPlayerRepo();
    playerVm = PlayerViewModel(repo);
    rewardsVm = RewardsViewModel(playerVm);
  });

  tearDown(() async {
    rewardsVm.dispose();
    await Hive.box('settings').clear();
  });

  group('RewardsViewModel', () {
    test('expose des valeurs par défaut si le joueur n\'est pas chargé', () {
      expect(rewardsVm.stats, isNull);
      expect(rewardsVm.level, 1);
      expect(rewardsVm.experience, 0);
      expect(rewardsVm.gold, 0);
      expect(rewardsVm.streak, 0);
      expect(rewardsVm.healthPoints, 0);
    });

    test('reflète les stats du PlayerViewModel après chargement', () async {
      when(() => repo.loadLocalStats()).thenReturn(
        PlayerStats(level: 3, experience: 50, gold: 200, streak: 5),
      );
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});

      await playerVm.loadPlayerStats('u1');

      expect(rewardsVm.level, 3);
      expect(rewardsVm.gold, 200);
      expect(rewardsVm.streak, 5);
      expect(rewardsVm.experienceForNextLevel, playerVm.experienceForLevel(3));
    });

    test('xpProgress est borné entre 0 et 1', () async {
      when(() => repo.loadLocalStats()).thenReturn(
        PlayerStats(level: 1, experience: 1000),
      );
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});

      await playerVm.loadPlayerStats('u1');

      expect(rewardsVm.xpProgress, inInclusiveRange(0.0, 1.0));
    });

    test('se met à jour quand le PlayerViewModel notifie (or)', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(gold: 10));
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      await playerVm.loadPlayerStats('u1');
      expect(rewardsVm.gold, 10);

      await playerVm.addGold('u1', 40);

      expect(rewardsVm.gold, 50);
    });
  });
}
