import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/craft_recipe_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/craft_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';

/// Page "Atelier de Forge" — combinaison d'objets en inventaire.
class CraftPage extends StatefulWidget {
  const CraftPage({super.key});

  @override
  State<CraftPage> createState() => _CraftPageState();
}

class _CraftPageState extends State<CraftPage> {
  final _craftVM = CraftViewModel();

  @override
  void dispose() {
    _craftVM.dispose();
    super.dispose();
  }

  Future<void> _doCraft(CraftRecipe recipe) async {
    final inventory = context.read<InventoryViewModel>();
    final player = context.read<PlayerViewModel>();
    final userId = context.read<AuthViewModel>().userId ?? '';

    final result = await _craftVM.craft(recipe, inventory, player, userId);

    if (!mounted) return;

    if (result.success) {
      AppNotification.show(
        context,
        message: result.message,
        backgroundColor: AppColors.mintMagic,
        duration: const Duration(seconds: 3),
      );
    } else {
      AppNotification.show(
        context,
        message: result.message,
        backgroundColor: AppColors.coralRare,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _craftVM,
      child: Scaffold(
        backgroundColor: AppColors.backgroundNightCosmos,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Atelier de Forge',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer3<CraftViewModel, InventoryViewModel, PlayerViewModel>(
          builder: (context, craftVM, inventory, player, _) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: craftVM.recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final recipe = craftVM.recipes[index];
                final craftable = craftVM.canCraft(recipe, inventory, player);
                return _RecipeCard(
                  recipe: recipe,
                  craftable: craftable,
                  loading: craftVM.loading,
                  getAvailable: (name) => craftVM.available(name, inventory),
                  onCraft: () => _doCraft(recipe),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Carte de recette ─────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final CraftRecipe recipe;
  final bool craftable;
  final bool loading;
  final int Function(String) getAvailable;
  final VoidCallback onCraft;

  const _RecipeCard({
    required this.recipe,
    required this.craftable,
    required this.loading,
    required this.getAvailable,
    required this.onCraft,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(recipe.result.rarity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: craftable
              ? rarityColor.withValues(alpha: 0.6)
              : AppColors.inputBorder,
          width: craftable ? 1.5 : 1,
        ),
        boxShadow: craftable
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Text(recipe.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        recipe.description,
                        style: GoogleFonts.nunito(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RarityBadge(rarity: recipe.result.rarity),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColors.inputBorder, height: 1),
            const SizedBox(height: 14),

            // Ingrédients
            Text(
              'Ingrédients',
              style: GoogleFonts.nunito(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: recipe.ingredients.map((ing) {
                final have = getAvailable(ing.itemName);
                final ok = have >= ing.quantity;
                return _IngredientChip(
                  name: ing.itemName,
                  required_: ing.quantity,
                  available: have,
                  ok: ok,
                );
              }).toList(),
            ),

            // Coût en or
            if (recipe.goldCost > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.goldCost} or',
                    style: GoogleFonts.nunito(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Bouton Forger
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: craftable && !loading ? onCraft : null,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.hardware_rounded, size: 18),
                label: Text(
                  craftable ? 'Forger' : 'Ingrédients manquants',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      craftable ? rarityColor : AppColors.inputBorder,
                  foregroundColor:
                      craftable ? Colors.white : AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(QuestRarity rarity) => switch (rarity) {
        QuestRarity.common    => AppColors.rarityCommon,
        QuestRarity.uncommon  => AppColors.rarityUncommon,
        QuestRarity.rare      => AppColors.rarityRare,
        QuestRarity.epic      => AppColors.rarityEpic,
        QuestRarity.legendary => AppColors.rarityLegendary,
        QuestRarity.mythic    => AppColors.rarityMythic,
      };
}

// ── Chip ingrédient ──────────────────────────────────────────────────────────

class _IngredientChip extends StatelessWidget {
  final String name;
  final int required_;
  final int available;
  final bool ok;

  const _IngredientChip({
    required this.name,
    required this.required_,
    required this.available,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.mintMagic : AppColors.coralRare;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '$name ($available/$required_)',
            style: GoogleFonts.nunito(
              color: ok ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge rareté ─────────────────────────────────────────────────────────────

class _RarityBadge extends StatelessWidget {
  final QuestRarity rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRarityColor(rarity.name);
    final label = switch (rarity) {
      QuestRarity.common    => 'Commun',
      QuestRarity.uncommon  => 'Peu commun',
      QuestRarity.rare      => 'Rare',
      QuestRarity.epic      => 'Épique',
      QuestRarity.legendary => 'Légendaire',
      QuestRarity.mythic    => 'Mythique',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
