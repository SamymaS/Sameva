import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/craft_recipe_model.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/craft_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Item _makeItem(String name, {int qty = 1, ItemType type = ItemType.material}) =>
    Item(
      id: 'test_${name.replaceAll(' ', '_')}',
      name: name,
      description: '',
      type: type,
      rarity: QuestRarity.common,
      iconCodePoint: Icons.circle.codePoint,
      stats: const {},
      goldValue: 10,
      quantity: qty,
    );

// Recette simple : 2 fragments → 1 cristal, pas de coût or
final _recipe = CraftRecipe(
  id: 'test_recipe',
  name: 'Cristal Test',
  description: '',
  icon: '💎',
  ingredients: const [
    CraftIngredient(itemName: 'Fragment', quantity: 2),
  ],
  result: _makeItem('Cristal'),
);

// Recette avec coût or
final _paidRecipe = CraftRecipe(
  id: 'test_paid_recipe',
  name: 'Cristal Payant',
  description: '',
  icon: '💎',
  goldCost: 100,
  ingredients: const [
    CraftIngredient(itemName: 'Fragment', quantity: 1),
  ],
  result: _makeItem('Cristal Payant'),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CraftService.canCraft', () {
    test('retourne true si ingrédients et or suffisants', () {
      final inventory = [_makeItem('Fragment', qty: 2)];
      expect(CraftService.canCraft(_recipe, inventory, 0), isTrue);
    });

    test('retourne false si ingrédients insuffisants', () {
      final inventory = [_makeItem('Fragment', qty: 1)];
      expect(CraftService.canCraft(_recipe, inventory, 0), isFalse);
    });

    test('retourne false si inventaire vide', () {
      expect(CraftService.canCraft(_recipe, [], 0), isFalse);
    });

    test('retourne false si or insuffisant pour recette payante', () {
      final inventory = [_makeItem('Fragment', qty: 1)];
      expect(CraftService.canCraft(_paidRecipe, inventory, 50), isFalse);
    });

    test('retourne true si or suffisant pour recette payante', () {
      final inventory = [_makeItem('Fragment', qty: 1)];
      expect(CraftService.canCraft(_paidRecipe, inventory, 100), isTrue);
    });

    test('additionne les quantités de plusieurs stacks du même item', () {
      final inventory = [
        _makeItem('Fragment', qty: 1),
        _makeItem('Fragment', qty: 1),
      ];
      expect(CraftService.canCraft(_recipe, inventory, 0), isTrue);
    });
  });

  group('CraftService.availableCount', () {
    test('retourne 0 si item absent', () {
      expect(CraftService.availableCount('Fragment', []), 0);
    });

    test('additionne les quantités de plusieurs stacks', () {
      final inventory = [
        _makeItem('Fragment', qty: 3),
        _makeItem('Fragment', qty: 2),
      ];
      expect(CraftService.availableCount('Fragment', inventory), 5);
    });

    test('ignore les items de noms différents', () {
      final inventory = [
        _makeItem('Fragment', qty: 3),
        _makeItem('Autre', qty: 5),
      ];
      expect(CraftService.availableCount('Fragment', inventory), 3);
    });
  });

  group('CraftService.craftResult', () {
    test('crée un item avec un UUID unique', () {
      final a = CraftService.craftResult(_recipe);
      final b = CraftService.craftResult(_recipe);
      expect(a.id, isNot('recipe_template'));
      expect(a.id, isNot(b.id));
    });

    test('copie le nom et les stats de la recette', () {
      final item = CraftService.craftResult(_recipe);
      expect(item.name, _recipe.result.name);
      expect(item.type, _recipe.result.type);
      expect(item.rarity, _recipe.result.rarity);
    });
  });

  group('CraftService.ingredientsToRemove', () {
    test('retourne les bons items à retirer pour un seul stack', () {
      final item = _makeItem('Fragment', qty: 3);
      final toRemove = CraftService.ingredientsToRemove(_recipe, [item]);
      expect(toRemove.length, 1);
      expect(toRemove.first.id, item.id);
      expect(toRemove.first.qty, 2);
    });

    test('distribue sur plusieurs stacks si nécessaire', () {
      final a = Item(
        id: 'a',
        name: 'Fragment',
        description: '',
        type: ItemType.material,
        rarity: QuestRarity.common,
        iconCodePoint: Icons.circle.codePoint,
        stats: const {},
        goldValue: 10,
        quantity: 1,
      );
      final b = Item(
        id: 'b',
        name: 'Fragment',
        description: '',
        type: ItemType.material,
        rarity: QuestRarity.common,
        iconCodePoint: Icons.circle.codePoint,
        stats: const {},
        goldValue: 10,
        quantity: 1,
      );
      final toRemove = CraftService.ingredientsToRemove(_recipe, [a, b]);
      expect(toRemove.length, 2);
      expect(toRemove.map((e) => e.qty).reduce((a, b) => a + b), 2);
    });
  });

  group('CraftService.recipes', () {
    test('catalogue non vide', () {
      expect(CraftService.recipes, isNotEmpty);
    });

    test('chaque recette a un id unique', () {
      final ids = CraftService.recipes.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('chaque résultat a un goldValue positif', () {
      for (final r in CraftService.recipes) {
        expect(r.result.goldValue, greaterThan(0),
            reason: '${r.name} goldValue invalide');
      }
    });
  });
}
