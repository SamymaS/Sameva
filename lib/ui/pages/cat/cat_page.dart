import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cat_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cat/cat_widget.dart';

/// Page principale du chat compagnon.
/// Affiche le chat avec ses cosmétiques équipés et permet de les gérer.
class CatPage extends StatelessWidget {
  const CatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatViewModel>(
      builder: (context, catProvider, _) {
        final cat = catProvider.mainCat;

        if (cat == null) {
          return _EmptyCatState();
        }

        return _CatPageContent(cat: cat, catProvider: catProvider);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenu principal
// ─────────────────────────────────────────────────────────────────────────────

class _CatPageContent extends StatelessWidget {
  final CatStats cat;
  final CatViewModel catProvider;

  const _CatPageContent({required this.cat, required this.catProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      body: CustomScrollView(
        slivers: [
          // AppBar avec fond transparent
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            title: Text(
              'Mon Chat',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 22,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                onPressed: () => _showRenameDialog(context),
                tooltip: 'Renommer',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Zone hero du chat ─────────────────────────────────────
                _CatHeroSection(cat: cat),

                const SizedBox(height: 32),

                // ── Slots cosmétiques ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Cosmétiques',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _CosmeticSlots(cat: cat, catProvider: catProvider),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: cat.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: Text(
          'Renommer',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800,color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nom du chat',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundNightCosmos,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryVioletLight),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await catProvider.renameCat(cat.id, name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Renommer',
                style: TextStyle(color: AppColors.primaryVioletLight)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section hero
// ─────────────────────────────────────────────────────────────────────────────

class _CatHeroSection extends StatelessWidget {
  final CatStats cat;

  const _CatHeroSection({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glow violet derrière le chat
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: catBodyColor(cat.race).withValues(alpha: 0.30),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: CatWidget(
              race: cat.race,
              equippedHat: cat.equippedHat,
              size: 200,
              mood: 'happy',
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Nom du chat
        Text(
          cat.name,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontSize: 26,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Race + badge rareté
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _raceLabel(cat.race),
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            _RarityBadge(rarity: cat.rarity),
          ],
        ),
      ],
    );
  }

  String _raceLabel(String race) => switch (race) {
        'michi'  => 'Michi · Sage',
        'lune'   => 'Lune · Mystérieux',
        'braise' => 'Braise · Énergique',
        'neige'  => 'Neige · Doux',
        'cosmos' => 'Cosmos · Mystique',
        'sakura' => 'Sakura · Joyeux',
        _        => race,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Grille de slots cosmétiques
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticSlots extends StatelessWidget {
  final CatStats cat;
  final CatViewModel catProvider;

  const _CosmeticSlots({required this.cat, required this.catProvider});

  static const _slots = [
    (slot: 'hat',       label: 'Chapeau',    icon: Icons.dry_outlined),
    (slot: 'outfit',    label: 'Tenue',      icon: Icons.checkroom_outlined),
    (slot: 'aura',      label: 'Aura',       icon: Icons.auto_awesome_outlined),
    (slot: 'accessory', label: 'Accessoire', icon: Icons.diamond_outlined),
    (slot: 'title',     label: 'Titre',      icon: Icons.workspace_premium_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _slots.map((s) {
          final equipped = _equippedForSlot(s.slot);
          return _SlotButton(
            label: s.label,
            icon: s.icon,
            equipped: equipped,
            onTap: () => _showCosmeticSheet(context, s.slot, s.label),
          );
        }).toList(),
      ),
    );
  }

  String? _equippedForSlot(String slot) => switch (slot) {
        'hat'       => cat.equippedHat,
        'outfit'    => cat.equippedOutfit,
        'aura'      => cat.equippedAura,
        'accessory' => cat.equippedAccessory,
        'title'     => cat.equippedTitle,
        _           => null,
      };

  void _showCosmeticSheet(
      BuildContext context, String slot, String label) {
    final inventory = context.read<InventoryViewModel>();
    // Filtrer les items cosmétiques correspondant au slot
    final cosmetics = inventory.items
        .where((item) => item.cosmeticSlot == slot)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDarkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CosmeticSheet(
        label: label,
        slot: slot,
        cosmetics: cosmetics,
        cat: cat,
        catProvider: catProvider,
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? equipped;
  final VoidCallback onTap;

  const _SlotButton({
    required this.label,
    required this.icon,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEquipped = equipped != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isEquipped
                  ? AppColors.primaryViolet.withValues(alpha: 0.20)
                  : AppColors.backgroundDarkPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isEquipped
                    ? AppColors.primaryVioletLight
                    : AppColors.inputBorder,
                width: isEquipped ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              icon,
              color: isEquipped
                  ? AppColors.primaryVioletLight
                  : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BottomSheet — liste des cosmétiques disponibles
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticSheet extends StatelessWidget {
  final String label;
  final String slot;
  final List cosmetics;
  final CatStats cat;
  final CatViewModel catProvider;

  const _CosmeticSheet({
    required this.label,
    required this.slot,
    required this.cosmetics,
    required this.cat,
    required this.catProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            label,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          if (cosmetics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucun cosmétique disponible.\nObtiens-en via le Marché ou les invocations !',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cosmetics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = cosmetics[i];
                final equippedId = switch (slot) {
                  'hat'       => catProvider.mainCat?.equippedHat,
                  'outfit'    => catProvider.mainCat?.equippedOutfit,
                  'aura'      => catProvider.mainCat?.equippedAura,
                  'accessory' => catProvider.mainCat?.equippedAccessory,
                  'title'     => catProvider.mainCat?.equippedTitle,
                  _           => null,
                };
                final isEquipped = equippedId == item.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tileColor: isEquipped
                      ? AppColors.primaryViolet.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isEquipped
                          ? AppColors.primaryVioletLight
                          : AppColors.inputBorder,
                    ),
                  ),
                  leading: Icon(
                    IconData(item.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: AppColors.getRarityColor(item.rarity.name),
                  ),
                  title: Text(item.name,
                      style: GoogleFonts.nunito(
                          color: AppColors.textPrimary, fontSize: 14)),
                  trailing: isEquipped
                      ? const Icon(Icons.check_circle,
                          color: AppColors.mintMagic, size: 20)
                      : null,
                  onTap: () async {
                    await catProvider.equipCosmetic(
                        cat.id, slot, isEquipped ? null : item.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État vide (pas de chat)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCatState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐱', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Pas encore de chat compagnon',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complète l\'onboarding pour créer ton chat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge rareté (interne à cat_page pour l'instant)
// ─────────────────────────────────────────────────────────────────────────────

class _RarityBadge extends StatelessWidget {
  final String rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRarityColor(rarity);
    final label = switch (rarity.toLowerCase()) {
      'common'    => 'Commun',
      'uncommon'  => 'Peu commun',
      'rare'      => 'Rare',
      'epic'      => 'Épique',
      'legendary' => 'Légendaire',
      'mythic'    => 'Mythique',
      _           => rarity,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
