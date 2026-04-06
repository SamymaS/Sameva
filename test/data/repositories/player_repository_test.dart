import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/player_stats_model.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late _MockBox box;
  late _MockSupabaseClient supabase;
  late PlayerRepository repo;

  setUp(() {
    box = _MockBox();
    supabase = _MockSupabaseClient();
    repo = PlayerRepository(box, supabase);
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

    group('syncToSupabase', () {
      test('avale les exceptions réseau sans propager', () async {
        when(() => supabase.from(any())).thenThrow(Exception('offline'));

        await expectLater(
          () async => repo.syncToSupabase('u1', PlayerStats()),
          returnsNormally,
        );
      });
    });
  });
}
