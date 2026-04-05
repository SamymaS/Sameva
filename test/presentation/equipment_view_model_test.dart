import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/presentation/view_models/equipment_view_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

Item _weapon({String id = 'sw'}) => Item(
      id: id,
      name: 'Épée',
      description: 'd',
      type: ItemType.weapon,
      rarity: QuestRarity.common,
      iconCodePoint: 1,
      stats: const {'xpBonus': 5},
      goldValue: 50,
    );

Item _hat({String id = 'h1'}) => Item(
      id: id,
      name: 'Chapeau',
      description: 'cosmétique',
      type: ItemType.cosmetic,
      rarity: QuestRarity.common,
      iconCodePoint: 2,
      goldValue: 10,
      cosmeticSlot: 'hat',
    );

void main() {
  late _MockBox equipBox;
  late _MockBox invBox;
  late EquipmentViewModel equipVm;
  late InventoryViewModel invVm;

  setUp(() {
    equipBox = _MockBox();
    invBox = _MockBox();
    equipVm = EquipmentViewModel(equipBox);
    invVm = InventoryViewModel(invBox);
    when(() => equipBox.put(any(), any())).thenAnswer((_) async {});
    when(() => invBox.put(any(), any())).thenAnswer((_) async {});
    when(() => invBox.get('items')).thenReturn(null);
    invVm.loadInventory();
  });

  group('EquipmentViewModel', () {
    test('loadEquipment avec box vide laisse les slots vides', () {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      equipVm.loadEquipment();

      expect(equipVm.getSlot(EquipmentSlot.weapon), isNull);
    });

    test('xpBonusPercent somme les stats des items équipés', () async {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);
      equipVm.loadEquipment();

      invVm.addItem(_weapon(id: 'w1'));
      equipVm.equip(_weapon(id: 'w1'), EquipmentSlot.weapon, invVm);

      expect(equipVm.xpBonusPercent, 5);
    });

    test('equip retire l\'item de l\'inventaire', () {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);
      equipVm.loadEquipment();
      final w = _weapon();
      invVm.addItem(w);

      equipVm.equip(w, EquipmentSlot.weapon, invVm);

      expect(invVm.items, isEmpty);
      expect(equipVm.getSlot(EquipmentSlot.weapon)?.id, w.id);
    });

    test('equip renvoie l\'ancien équipement vers l\'inventaire', () {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);
      equipVm.loadEquipment();
      final first = _weapon(id: 'a');
      final second = _weapon(id: 'b');
      invVm.addItem(first);
      invVm.addItem(second);
      equipVm.equip(first, EquipmentSlot.weapon, invVm);
      expect(invVm.items, hasLength(1));

      equipVm.equip(second, EquipmentSlot.weapon, invVm);

      expect(equipVm.getSlot(EquipmentSlot.weapon)?.id, 'b');
      expect(invVm.items.map((e) => e.id), contains('a'));
    });

    test('unequip remet l\'item dans l\'inventaire', () {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);
      equipVm.loadEquipment();
      final w = _weapon();
      invVm.addItem(w);
      equipVm.equip(w, EquipmentSlot.weapon, invVm);

      equipVm.unequip(EquipmentSlot.weapon, invVm);

      expect(equipVm.getSlot(EquipmentSlot.weapon), isNull);
      expect(invVm.items, hasLength(1));
    });

    test('unequip sur slot vide ne modifie pas l\'inventaire', () {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);
      equipVm.loadEquipment();
      invVm.addItem(_weapon(id: 'only'));

      equipVm.unequip(EquipmentSlot.weapon, invVm);

      expect(invVm.items, hasLength(1));
    });

    test('equipCosmetic / unequipCosmetic échangent avec l\'inventaire', () {
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);
      equipVm.loadEquipment();
      final a = _hat(id: 'hat-a');
      final b = _hat(id: 'hat-b');
      invVm.addItem(a);
      invVm.addItem(b);

      equipVm.equipCosmetic(a, 'hat', invVm);
      expect(equipVm.getCosmeticSlot('hat')?.id, 'hat-a');
      expect(invVm.items, hasLength(1));

      equipVm.equipCosmetic(b, 'hat', invVm);
      expect(equipVm.getCosmeticSlot('hat')?.id, 'hat-b');
      expect(invVm.items.map((e) => e.id), contains('hat-a'));

      equipVm.unequipCosmetic('hat', invVm);
      expect(equipVm.getCosmeticSlot('hat'), isNull);
      expect(invVm.items.map((e) => e.id), contains('hat-b'));
    });

    test('loadEquipment restaure weapon depuis la map Hive', () {
      final w = _weapon(id: 'stored');
      when(() => equipBox.get('equipment')).thenReturn({
        'weapon': w.toJson(),
      });
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      equipVm.loadEquipment();

      expect(equipVm.getSlot(EquipmentSlot.weapon)?.id, 'stored');
      expect(equipVm.xpBonusPercent, 5);
    });
  });
}
