import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/player_stats_model.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/data/repositories/game_api.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockGameApi extends Mock implements GameApi {}

void main() {
  late _MockBox box;
  late _MockGameApi api;
  late PlayerRepository repo;

  setUp(() {
    box = _MockBox();
    api = _MockGameApi();
    repo = PlayerRepository(box, api);
  });

  group('PlayerRepository', () {
    group('loadLocalStats', () {
      test('retourne les stats par défaut si Hive est vide', () {
        when(() => box.get('stats')).thenReturn(null);

        final stats = repo.loadLocalStats();

        expect(stats.level, 1);
        expect(stats.experience, 0);
        expect(stats.gold, 0);
        expect(stats.healthPoints, 100);
      });

      test('parse les stats stockées dans Hive', () {
        final stored = PlayerStats(
          level: 5,
          experience: 120,
          gold: 300,
          crystals: 4,
        );
        when(() => box.get('stats')).thenReturn(stored.toJson());

        final stats = repo.loadLocalStats();

        expect(stats.level, 5);
        expect(stats.experience, 120);
        expect(stats.gold, 300);
        expect(stats.crystals, 4);
      });

      test('retourne les stats par défaut si Hive lève une exception', () {
        when(() => box.get('stats')).thenThrow(Exception('corruption Hive'));

        final stats = repo.loadLocalStats();

        expect(stats.level, 1);
        expect(stats.gold, 0);
      });
    });

    group('saveLocalStats', () {
      test('écrit dans Hive avec la clé "stats"', () async {
        when(() => box.put('stats', any())).thenAnswer((_) async {});
        final stats = PlayerStats(level: 3, gold: 50);

        await repo.saveLocalStats(stats);

        final captured =
            verify(() => box.put('stats', captureAny())).captured.single
                as Map;
        expect(captured['level'], 3);
        expect(captured['gold'], 50);
      });

      test('avale les exceptions Hive sans propager', () async {
        when(() => box.put(any(), any()))
            .thenThrow(Exception('disk full'));

        await expectLater(
          () async => repo.saveLocalStats(PlayerStats()),
          returnsNormally,
        );
      });
    });

    group('fetchServerState', () {
      test('délègue à GameApi.getPlayerState (le serveur fait autorité)', () async {
        final state = PlayerServerState(
          stats: PlayerStats(level: 3, seals: 4),
          xpForNextLevel: 450,
          energy: 2,
          premium: false,
          gacha: const {},
        );
        when(() => api.getPlayerState()).thenAnswer((_) async => state);

        final result = await repo.fetchServerState();

        expect(result.stats.level, 3);
        expect(result.stats.seals, 4);
        verify(() => api.getPlayerState()).called(1);
      });

      test('propage les erreurs (l\'appelant garde le cache)', () async {
        when(() => api.getPlayerState()).thenThrow(const GameApiException('erreur_reseau'));
        expect(() => repo.fetchServerState(), throwsA(isA<GameApiException>()));
      });
    });
  });
}
