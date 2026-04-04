import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late Directory hiveDir;
  late _MockPlayerRepository repo;
  late PlayerViewModel vm;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(PlayerStats());
    hiveDir = await Directory.systemTemp.createTemp('sameva_player_vm_test_');
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
    repo = _MockPlayerRepository();
    vm = PlayerViewModel(repo);
  });

  tearDown(() async {
    final box = Hive.box('settings');
    await box.clear();
  });

  group('PlayerViewModel', () {
    test('experienceForLevel suit la formule du jeu', () {
      expect(vm.experienceForLevel(1), 150);
      expect(vm.experienceForLevel(2), 300);
    });

    test('hasStreakBonus est vrai à partir de 7 jours de série', () async {
      when(() => repo.loadLocalStats()).thenReturn(
        PlayerStats(streak: 7, level: 1, experience: 0),
      );
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});

      await vm.loadPlayerStats('user-1');

      expect(vm.hasStreakBonus, isTrue);
    });

    test('loadPlayerStats charge le local puis notifie', () async {
      final local = PlayerStats(
        level: 2,
        experience: 10,
        gold: 50,
        healthPoints: 100,
        maxHealthPoints: 100,
      );
      when(() => repo.loadLocalStats()).thenReturn(local);
      when(() => repo.fetchRemoteStats('u')).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});

      await vm.loadPlayerStats('u');

      expect(vm.stats?.level, 2);
      expect(vm.stats?.gold, 50);
      expect(vm.isInitialized, isTrue);
    });

    test('addGold augmente l\'or et persiste', () async {
      when(() => repo.loadLocalStats()).thenReturn(PlayerStats(gold: 10));
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      await vm.loadPlayerStats('u');
      await vm.addGold('u', 5);

      expect(vm.stats?.gold, 15);
      verify(() => repo.saveLocalStats(any())).called(1);
    });

    test('addExperience peut faire monter de niveau', () async {
      when(() => repo.loadLocalStats()).thenReturn(
        PlayerStats(level: 1, experience: 140),
      );
      when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      await vm.loadPlayerStats('u');
      await vm.addExperience('u', 20);

      expect(vm.stats?.level, greaterThan(1));
      expect(vm.stats!.experience, lessThan(vm.experienceForLevel(1)));
    });
  });
}
