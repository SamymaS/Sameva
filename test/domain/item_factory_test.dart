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

      test('pityCount < 20 utilise le tirage standard (rareté valide)', () {
        // pityTriggered peut être true si épique+ naturel — on ne teste pas false
        final r = ItemFactory.rollGachaRarityWithPity(0);
        expect(QuestRarity.values, contains(r.rarity));
      });

      test('pityCount >= 20 garantit minimum épique', () {
        for (var i = 0; i < 30; i++) {
          final r = ItemFactory.rollGachaRarityWithPity(20);
          expect(r.rarity.index, greaterThanOrEqualTo(QuestRarity.epic.index),
              reason: 'pityCount=20 doit forcer épique minimum');
          expect(r.pityTriggered, isTrue,
              reason: 'pity triggered doit être true');
        }
      });

      test('pityTriggered true si rareté ≥ épique (reset compteur)', () {
        // Force plusieurs tirages pour vérifier la cohérence
        for (var i = 0; i < 200; i++) {
          final r = ItemFactory.rollGachaRarityWithPity(0);
          if (r.rarity.index >= QuestRarity.epic.index) {
            expect(r.pityTriggered, isTrue,
                reason: 'épique+ doit déclencher reset pity');
          }
        }
      });
    });

    group('generateRandomItem cascade fallback', () {
      test('toujours retourne item avec rareté valide même si template absent',
          () {
        // Toutes les raretés ont au moins un template dans le catalogue,
        // donc la rareté retournée doit toujours être ≤ rareté demandée.
        for (final rarity in QuestRarity.values) {
          final item = ItemFactory.generateRandomItem(rarity);
          expect(item.rarity.index, lessThanOrEqualTo(rarity.index),
              reason: 'cascade ne doit jamais monter en rareté');
        }
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
