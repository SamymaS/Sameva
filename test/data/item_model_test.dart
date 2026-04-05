import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';

void main() {
  group('Item', () {
    test('toJson puis fromJson préserve les données', () {
      const original = Item(
        id: 'it-1',
        name: 'Épée',
        description: 'Rouillée',
        type: ItemType.weapon,
        rarity: QuestRarity.uncommon,
        iconCodePoint: 12345,
        stats: {'xpBonus': 10},
        quantity: 2,
        stackable: true,
        goldValue: 99,
        cosmeticSlot: null,
        assetPath: 'assets/items/x.svg',
      );

      final restored = Item.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.rarity, original.rarity);
      expect(restored.stats, original.stats);
      expect(restored.quantity, original.quantity);
      expect(restored.stackable, original.stackable);
      expect(restored.goldValue, original.goldValue);
      expect(restored.assetPath, original.assetPath);
    });

    test('slotForItem mappe le type vers EquipmentSlot', () {
      const w = Item(
        id: 'w',
        name: 'w',
        description: 'd',
        type: ItemType.weapon,
        rarity: QuestRarity.common,
        iconCodePoint: 0,
        goldValue: 1,
      );
      const potion = Item(
        id: 'p',
        name: 'p',
        description: 'd',
        type: ItemType.potion,
        rarity: QuestRarity.common,
        iconCodePoint: 0,
        goldValue: 1,
      );

      expect(Item.slotForItem(w), EquipmentSlot.weapon);
      expect(Item.slotForItem(potion), isNull);
    });

    test('cosmeticSlotForItem lit le champ cosmétique', () {
      const c = Item(
        id: 'c',
        name: 'c',
        description: 'd',
        type: ItemType.cosmetic,
        rarity: QuestRarity.common,
        iconCodePoint: 0,
        goldValue: 1,
        cosmeticSlot: 'hat',
      );

      expect(Item.cosmeticSlotForItem(c), 'hat');
    });
  });
}
