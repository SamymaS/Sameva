import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/cat_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

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
  late _MockBox box;
  late CatViewModel vm;

  setUp(() {
    box = _MockBox();
    vm = CatViewModel(box);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
  });

  group('CatViewModel', () {
    test('loadCats avec box vide', () {
      when(() => box.get('cats_list')).thenReturn(null);

      vm.loadCats();

      expect(vm.cats, isEmpty);
      expect(vm.error, isNull);
    });

    test('loadCats restaure depuis JSON', () {
      final json = [
        _cat(id: 'c1', isMain: true).toJson(),
      ];
      when(() => box.get('cats_list')).thenReturn(json);

      vm.loadCats();

      expect(vm.cats, hasLength(1));
      expect(vm.mainCat?.id, 'c1');
    });

    test('createMainCat persiste et marque un seul main', () async {
      when(() => box.get('cats_list')).thenReturn(null);
      vm.loadCats();

      await vm.createMainCat('michi', 'Ronron');

      expect(vm.cats, hasLength(1));
      expect(vm.cats.first.isMain, isTrue);
      expect(vm.cats.first.name, 'Ronron');
      verify(() => box.put('cats_list', any())).called(1);
    });

    test('createMainCat avec nom vide utilise le défaut de race', () async {
      when(() => box.get('cats_list')).thenReturn(null);
      vm.loadCats();

      await vm.createMainCat('lune', '   ');

      expect(vm.cats.first.name, 'Luna');
    });

    test('renameCat met à jour le nom', () async {
      when(() => box.get('cats_list')).thenReturn([_cat(id: 'x').toJson()]);
      vm.loadCats();

      await vm.renameCat('x', '  Nouveau  ');

      expect(vm.cats.first.name, 'Nouveau');
    });

    test('equipCosmetic sur slot hat', () async {
      when(() => box.get('cats_list')).thenReturn([_cat(id: 'x').toJson()]);
      vm.loadCats();

      await vm.equipCosmetic('x', 'hat', 'cosm-1');

      expect(vm.cats.first.equippedHat, 'cosm-1');
    });

    test('addRolledCat ajoute un chat avec la rareté demandée', () async {
      when(() => box.get('cats_list')).thenReturn(null);
      vm.loadCats();

      final added = await vm.addRolledCat(QuestRarity.rare);

      expect(added.rarity, 'rare');
      expect(vm.cats, contains(added));
    });

    test('setMainCat bascule le flag isMain', () async {
      when(() => box.get('cats_list')).thenReturn([
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
  });
}
