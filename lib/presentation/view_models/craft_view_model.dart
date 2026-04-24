import 'package:flutter/material.dart';
import '../../data/models/craft_recipe_model.dart';
import '../../domain/services/craft_service.dart';
import 'inventory_view_model.dart';
import 'player_view_model.dart';

/// Résultat d'une opération de forge.
class CraftResult {
  final bool success;
  final String message;
  final String? craftedItemName;

  const CraftResult({
    required this.success,
    required this.message,
    this.craftedItemName,
  });
}

/// ViewModel local à la page de forge.
/// Instancié directement dans la page (pas enregistré dans main.dart).
class CraftViewModel extends ChangeNotifier {
  final List<CraftRecipe> recipes = CraftService.recipes;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Vérifie si la recette est forgeable pour le joueur actuel.
  bool canCraft(
    CraftRecipe recipe,
    InventoryViewModel inventory,
    PlayerViewModel player,
  ) =>
      CraftService.canCraft(
        recipe,
        inventory.items,
        player.stats?.gold ?? 0,
      );

  /// Renvoie la quantité disponible d'un ingrédient.
  int available(String itemName, InventoryViewModel inventory) =>
      CraftService.availableCount(itemName, inventory.items);

  /// Exécute la forge d'une recette.
  Future<CraftResult> craft(
    CraftRecipe recipe,
    InventoryViewModel inventory,
    PlayerViewModel player,
    String userId,
  ) async {
    if (_loading) return const CraftResult(success: false, message: 'En cours…');

    if (!canCraft(recipe, inventory, player)) {
      return const CraftResult(
        success: false,
        message: 'Ingrédients ou or insuffisants.',
      );
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Déduire le coût en or en premier (rollback trivial si échec ultérieur)
      if (recipe.goldCost > 0) {
        await player.addGold(userId, -recipe.goldCost);
      }

      // 2. Retirer les ingrédients
      final toRemove = CraftService.ingredientsToRemove(recipe, inventory.items);
      for (final entry in toRemove) {
        inventory.removeItem(entry.id, quantity: entry.qty);
      }

      // 3. Créer et ajouter l'item résultat
      final newItem = CraftService.craftResult(recipe);
      inventory.addItem(newItem);

      return CraftResult(
        success: true,
        message: '${recipe.icon} ${newItem.name} forgé avec succès !',
        craftedItemName: newItem.name,
      );
    } catch (e) {
      _error = e.toString();
      return CraftResult(success: false, message: 'Erreur : $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
