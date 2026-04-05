import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/item_factory.dart';

void main() {
  group('ItemFactory', () {
    test('generateRandomItem produit un item valide avec la rareté demandée', () {
      final item = ItemFactory.generateRandomItem(QuestRarity.rare);

      expect(item.id, isNotEmpty);
      expect(item.name, isNotEmpty);
      expect(item.rarity, QuestRarity.rare);
      expect(item.goldValue, greaterThan(0));
    });

    test('generateRandomItem common utilise le catalogue common', () {
      final item = ItemFactory.generateRandomItem(QuestRarity.common);
      expect(item.rarity, QuestRarity.common);
      expect(ItemType.values, contains(item.type));
    });

    test('getMarketCatalog exclut les matériaux', () {
      final catalog = ItemFactory.getMarketCatalog();

      expect(catalog, isNotEmpty);
      expect(catalog.every((i) => i.type != ItemType.material), isTrue);
    });

    test('getMarketCatalog conserve cohérence rareté / type par entrée', () {
      for (final item in ItemFactory.getMarketCatalog()) {
        expect(item.name, isNotEmpty);
        expect(item.description, isNotEmpty);
        expect(QuestRarity.values, contains(item.rarity));
      }
    });

    group('rollGachaRarityWithPity', () {
      test('pityCount >= 80 garantit legendary', () {
        final r = ItemFactory.rollGachaRarityWithPity(80);
        expect(r.rarity, QuestRarity.legendary);
        expect(r.pityTriggered, isTrue);
      });

      test('pityCount < 20 utilise le tirage standard', () {
        final r = ItemFactory.rollGachaRarityWithPity(0);
        expect(QuestRarity.values, contains(r.rarity));
        expect(r.pityTriggered, isFalse);
      });
    });

    test('rollGachaRarity retourne une rareté connue', () {
      for (var i = 0; i < 20; i++) {
        expect(QuestRarity.values, contains(ItemFactory.rollGachaRarity()));
      }
    });

    test('generateRandomItem pour chaque rareté produit un item cohérent', () {
      for (final rarity in QuestRarity.values) {
        final item = ItemFactory.generateRandomItem(rarity);
        expect(item.rarity, rarity);
        expect(item.name, isNotEmpty);
        expect(item.description, isNotEmpty);
        expect(item.goldValue, greaterThan(0));
      }
    });
  });
}
