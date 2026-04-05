import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

Item _item({
  String id = 'id-1',
  String name = 'Objet test',
  ItemType type = ItemType.weapon,
  bool stackable = false,
  int quantity = 1,
}) {
  return Item(
    id: id,
    name: name,
    description: 'd',
    type: type,
    rarity: QuestRarity.common,
    iconCodePoint: 0,
    goldValue: 10,
    stackable: stackable,
    quantity: quantity,
  );
}

void main() {
  late _MockBox box;
  late InventoryViewModel vm;

  setUp(() {
    box = _MockBox();
    vm = InventoryViewModel(box);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
  });

  group('InventoryViewModel', () {
    test('loadInventory avec base vide donne une liste vide', () {
      when(() => box.get('items')).thenReturn(null);

      vm.loadInventory();

      expect(vm.items, isEmpty);
      expect(vm.count, 0);
    });

    test('loadInventory restaure les items depuis la box', () {
      final json = [_item().toJson()];
      when(() => box.get('items')).thenReturn(json);

      vm.loadInventory();

      expect(vm.items, hasLength(1));
      expect(vm.items.first.name, 'Objet test');
    });

    test('addItem persiste et augmente le count', () {
      when(() => box.get('items')).thenReturn(null);
      vm.loadInventory();

      final ok = vm.addItem(_item());

      expect(ok, isTrue);
      expect(vm.count, 1);
      verify(() => box.put('items', any())).called(1);
    });

    test('addItem empile un item stackable de même nom et type', () {
      when(() => box.get('items')).thenReturn(null);
      vm.loadInventory();
      vm.addItem(_item(stackable: true, quantity: 2));

      vm.addItem(_item(stackable: true, quantity: 3));

      expect(vm.items, hasLength(1));
      expect(vm.items.first.quantity, 5);
    });

    test('removeItem diminue la quantité puis supprime', () {
      when(() => box.get('items')).thenReturn(null);
      vm.loadInventory();
      vm.addItem(_item(id: 'rm', quantity: 2));

      vm.removeItem('rm', quantity: 1);
      expect(vm.items.first.quantity, 1);

      vm.removeItem('rm', quantity: 1);
      expect(vm.items, isEmpty);
    });

    test('getItemsByType filtre correctement', () {
      when(() => box.get('items')).thenReturn(null);
      vm.loadInventory();
      vm.addItem(_item(id: 'w', type: ItemType.weapon));
      vm.addItem(_item(id: 'p', type: ItemType.potion));

      expect(vm.getItemsByType(ItemType.weapon), hasLength(1));
    });

    test('addItem retourne false si inventaire plein (50 slots distincts)', () {
      when(() => box.get('items')).thenReturn(null);
      vm.loadInventory();
      for (var i = 0; i < 50; i++) {
        expect(vm.addItem(_item(id: 'slot-$i')), isTrue);
      }
      expect(vm.isFull, isTrue);
      expect(vm.addItem(_item(id: 'overflow')), isFalse);
      expect(vm.items, hasLength(50));
    });

    test('loadInventory avec exception Hive vide la liste sans lever', () {
      when(() => box.get('items')).thenThrow(Exception('corruption'));

      vm.loadInventory();

      expect(vm.items, isEmpty);
      expect(vm.count, 0);
    });
  });
}
