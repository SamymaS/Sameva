import '../../../data/models/item_model.dart';

/// Un ingrédient d'une recette de forge.
class CraftIngredient {
  final String itemName;
  final int quantity;

  const CraftIngredient({required this.itemName, required this.quantity});
}

/// Une recette de forge permettant de combiner des objets en inventaire.
class CraftRecipe {
  final String id;
  final String name;
  final String description;
  final List<CraftIngredient> ingredients;
  final Item result;
  final int goldCost;
  final String icon;

  const CraftRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.result,
    this.goldCost = 0,
    this.icon = '⚒️',
  });
}
