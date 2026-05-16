import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/cat_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/cat_repository.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

class _MockCatRepository extends Mock implements CatRepository {}

class _FakeCatStats extends Fake implements CatStats {}

// userId injecté en test pour éviter l'accès à Supabase.instance.
const _testUserId = 'test-user-1';
const _testKey = 'cats_list_$_testUserId';

CatStats _cat({
  required String id,
  String name = 'Michi',
  bool isMain = false,
}) =>
    CatStats(
      id: id,
      name: name,
      race: 'michi',
      isMain: isMain,
      obtainedAt: DateTime.utc(2024, 1, 1),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCatStats());
  });

  late _MockBox box;
  late CatViewModel vm;

  setUp(() {
    box = _MockBox();
    vm = CatViewModel(box, testUserId: _testUserId);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
  });

  group('CatViewModel', () {
    test('loadCats avec box vide', () {
      when(() => box.get(_testKey)).thenReturn(null);

      vm.loadCats();

      expect(vm.cats, isEmpty);
      expect(vm.error, isNull);
    });

    test('loadCats restaure depuis JSON', () {
      final json = [
        _cat(id: 'c1', isMain: true).toJson(),
      ];
      when(() => box.get(_testKey)).thenReturn(json);

      vm.loadCats();

      expect(vm.cats, hasLength(1));
      expect(vm.mainCat?.id, 'c1');
    });

    test('createMainCat persiste et marque un seul main', () async {
      when(() => box.get(_testKey)).thenReturn(null);
      vm.loadCats();

      await vm.createMainCat('michi', 'Ronron');

      expect(vm.cats, hasLength(1));
      expect(vm.cats.first.isMain, isTrue);
      expect(vm.cats.first.name, 'Ronron');
      verify(() => box.put(_testKey, any())).called(1);
    });

    test('createMainCat avec nom vide utilise le défaut de race', () async {
      when(() => box.get(_testKey)).thenReturn(null);
      vm.loadCats();

      await vm.createMainCat('lune', '   ');

      expect(vm.cats.first.name, 'Luna');
    });

    test('createMainCat no-op si un mainCat existe déjà en mémoire', () async {
      // Garde idempotente : _cats déjà chargés avec un isMain
      when(() => box.get(_testKey))
          .thenReturn([_cat(id: 'existing', isMain: true).toJson()]);
      vm.loadCats();

      await vm.createMainCat('lune', 'Doublon');

      expect(vm.cats, hasLength(1));
      expect(vm.cats.first.id, 'existing');
      verifyNever(() => box.put(_testKey, any()));
    });

    test('createMainCat no-op si Hive contient un mainCat mais _cats est vide',
        () async {
      // Simule le cas où createMainCat est appelé sans loadCats() préalable
      // mais Hive contient déjà un compagnon principal.
      when(() => box.get(_testKey))
          .thenReturn([_cat(id: 'hive-cat', isMain: true).toJson()]);
      // _cats est vide en mémoire (loadCats pas appelé)

      await vm.createMainCat('michi', 'Doublon');

      // La garde a relu Hive et trouvé un isMain → no-op
      verifyNever(() => box.put(_testKey, any()));
    });

    test('renameCat met à jour le nom', () async {
      when(() => box.get(_testKey)).thenReturn([_cat(id: 'x').toJson()]);
      vm.loadCats();

      await vm.renameCat('x', '  Nouveau  ');

      expect(vm.cats.first.name, 'Nouveau');
    });

    test('equipCosmetic sur slot hat', () async {
      when(() => box.get(_testKey)).thenReturn([_cat(id: 'x').toJson()]);
      vm.loadCats();

      await vm.equipCosmetic('x', 'hat', 'cosm-1');

      expect(vm.cats.first.equippedHat, 'cosm-1');
    });

    test('addRolledCat ajoute un chat avec la rareté demandée', () async {
      when(() => box.get(_testKey)).thenReturn(null);
      vm.loadCats();

      final added = await vm.addRolledCat(QuestRarity.rare);

      expect(added.rarity, 'rare');
      expect(vm.cats, contains(added));
    });

    test('setMainCat bascule le flag isMain', () async {
      when(() => box.get(_testKey)).thenReturn([
        _cat(id: 'a', isMain: true).toJson(),
        _cat(id: 'b').toJson(),
      ]);
      vm.loadCats();

      await vm.setMainCat('b');

      expect(vm.cats.firstWhere((c) => c.id == 'b').isMain, isTrue);
      expect(vm.cats.firstWhere((c) => c.id == 'a').isMain, isFalse);
    });

    test('getCatMoodExpression cohérent avec les seuils', () {
      expect(vm.getCatMoodExpression(0.85, 7), 'excited');
      expect(vm.getCatMoodExpression(0.75, 0), 'happy');
      expect(vm.getCatMoodExpression(0.5, 0), 'neutral');
      expect(vm.getCatMoodExpression(0.25, 0), 'sad');
      expect(vm.getCatMoodExpression(0.1, 0), 'sleepy');
    });

    test('loadCats no-op si userId null (utilisateur non connecté)', () {
      // Pas de testUserId → _hiveKey null → aucun accès Hive
      final vmNoUser = CatViewModel(box);
      vmNoUser.loadCats();

      expect(vmNoUser.cats, isEmpty);
      verifyNever(() => box.get(any()));
    });

    test('reset vide le state in-memory sans toucher Hive', () async {
      when(() => box.get(_testKey))
          .thenReturn([_cat(id: 'x', isMain: true).toJson()]);
      vm.loadCats();
      expect(vm.cats, hasLength(1));

      vm.reset();

      expect(vm.cats, isEmpty);
      // Hive non touché par reset()
      verifyNever(() => box.delete(any()));
    });
  });

  group('CatViewModel avec CatRepository', () {
    late _MockBox box;
    late _MockCatRepository repo;

    final remoteCat = CatStats(
      id: 'remote-1',
      name: 'Luna',
      race: 'lune',
      rarity: 'rare',
      isMain: true,
      obtainedAt: DateTime.utc(2025, 1, 1),
    );

    setUp(() {
      box = _MockBox();
      repo = _MockCatRepository();
      when(() => box.put(any(), any())).thenAnswer((_) async {});
    });

    test('loadCats avec Hive vide + repo → hydrate depuis remote', () async {
      when(() => box.get(_testKey)).thenReturn(null);
      when(() => repo.fetchRemoteCompanions(_testUserId))
          .thenAnswer((_) async => [remoteCat]);

      final vm = CatViewModel(
        box,
        catRepository: repo,
        testUserId: _testUserId,
      );
      await vm.loadCats();

      expect(vm.cats, hasLength(1));
      expect(vm.cats.first.id, 'remote-1');
      // Hive persisté avec les cats remote
      verify(() => box.put(_testKey, any())).called(1);
    });

    test('loadCats avec Hive non-vide + repo → ne fetch PAS remote', () async {
      when(() => box.get(_testKey))
          .thenReturn([_cat(id: 'local-1', isMain: true).toJson()]);

      final vm = CatViewModel(
        box,
        catRepository: repo,
        testUserId: _testUserId,
      );
      await vm.loadCats();

      expect(vm.cats.first.id, 'local-1');
      verifyNever(() => repo.fetchRemoteCompanions(any()));
    });

    test('createMainCat avec repo → upsert appelé après persist Hive', () async {
      when(() => box.get(_testKey)).thenReturn(null);
      when(() => repo.fetchRemoteCompanions(any()))
          .thenAnswer((_) async => []);
      when(() => repo.upsertCompanion(any(), any()))
          .thenAnswer((_) async {});

      final vm = CatViewModel(
        box,
        catRepository: repo,
        testUserId: _testUserId,
      );
      await vm.loadCats();
      await vm.createMainCat('michi', 'Ronron');

      verify(() => repo.upsertCompanion(_testUserId, any())).called(1);
    });

    test('createMainCat : upsert échoue → cat reste créé localement', () async {
      when(() => box.get(_testKey)).thenReturn(null);
      when(() => repo.fetchRemoteCompanions(any()))
          .thenAnswer((_) async => []);
      when(() => repo.upsertCompanion(any(), any()))
          .thenThrow(Exception('réseau coupé'));

      final vm = CatViewModel(
        box,
        catRepository: repo,
        testUserId: _testUserId,
      );
      await vm.loadCats();

      // Ne doit pas propager l'exception de upsert
      await expectLater(
        () async => vm.createMainCat('sakura', 'Sakura'),
        returnsNormally,
      );
      expect(vm.cats, hasLength(1));
      expect(vm.error, isNull);
    });
  });
}
