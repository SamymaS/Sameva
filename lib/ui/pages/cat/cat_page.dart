import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cat_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
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

class _CatPageContent extends StatefulWidget {
  final CatStats cat;
  final CatViewModel catProvider;

  const _CatPageContent({required this.cat, required this.catProvider});

  @override
  State<_CatPageContent> createState() => _CatPageContentState();
}

class _CatPageContentState extends State<_CatPageContent> {
  static const _cooldownKey = 'cat_pet_cooldown';
  static const _cooldownHours = 4;

  bool get _canPet {
    final settings = Hive.box('settings');
    final raw = settings.get(_cooldownKey) as String?;
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= _cooldownHours;
  }

  Duration get _cooldownRemaining {
    final settings = Hive.box('settings');
    final raw = settings.get(_cooldownKey) as String?;
    if (raw == null) return Duration.zero;
    final last = DateTime.tryParse(raw);
    if (last == null) return Duration.zero;
    final elapsed = DateTime.now().difference(last);
    final remaining = const Duration(hours: _cooldownHours) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _petCat() async {
    if (!_canPet) return;
    final settings = Hive.box('settings');
    await settings.put(_cooldownKey, DateTime.now().toIso8601String());
    if (!mounted) return;

    final userId = context.read<AuthViewModel>().userId;
    if (userId != null) {
      await context.read<PlayerViewModel>().updateMoral(userId, 0.05);
    }
    if (!mounted) return;
    setState(() {});
    AppNotification.show(
      context,
      message: 'Ronron... +5% moral !',
      backgroundColor: AppColors.mintMagic,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPet = _canPet;
    final remaining = canPet ? null : _cooldownRemaining;
    final cooldownLabel = remaining != null
        ? '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}min'
        : null;

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
                _CatHeroSection(cat: widget.cat),

                const SizedBox(height: 16),

                // ── Bouton Caresser ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: FilledButton.icon(
                    onPressed: canPet ? _petCat : null,
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: Text(
                      canPet
                          ? 'Caresser (+5% moral)'
                          : 'Disponible dans $cooldownLabel',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: canPet
                          ? AppColors.rosePastel
                          : AppColors.backgroundDarkPanel,
                      foregroundColor: canPet
                          ? Colors.white
                          : AppColors.textMuted,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Slots cosmétiques ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Cosmétiques',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      _MiniActionBtn(
                        icon: Icons.shuffle,
                        label: 'Aléatoire',
                        color: AppColors.primaryVioletLight,
                        onTap: () => _randomizeOutfit(context),
                      ),
                      const SizedBox(width: 8),
                      _MiniActionBtn(
                        icon: Icons.layers_clear_outlined,
                        label: 'Retirer',
                        color: AppColors.textMuted,
                        onTap: () => _clearAll(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _CosmeticSlots(cat: widget.cat, catProvider: widget.catProvider),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: Text('Tout retirer',
            style: GoogleFonts.nunito(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Retirer tous les cosmétiques équipés de ${widget.cat.name} ?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer',
                style: TextStyle(
                    color: AppColors.coralRare, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.catProvider.clearAllCosmetics(widget.cat.id);
  }

  Future<void> _randomizeOutfit(BuildContext context) async {
    final inventory = context.read<InventoryViewModel>();
    final bySlot = <String, List<String>>{};
    for (final item in inventory.items) {
      final slot = item.cosmeticSlot;
      if (slot == null) continue;
      bySlot.putIfAbsent(slot, () => []).add(item.id);
    }
    if (bySlot.isEmpty) {
      AppNotification.show(context,
          message: 'Aucun cosmétique disponible',
          backgroundColor: AppColors.backgroundDarkPanel);
      return;
    }
    await widget.catProvider.randomizeCosmetics(widget.cat.id, bySlot);
    if (!mounted) return;
    AppNotification.show(this.context,
        message: 'Tenue aléatoire appliquée !',
        backgroundColor: AppColors.primaryViolet.withValues(alpha: 0.85));
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: widget.cat.name);
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
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await widget.catProvider.renameCat(widget.cat.id, name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Renommer',
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

  /// Résout la couleur d'un cosmétique à partir de l'id de l'objet en inventaire.
  Color? _resolveColor(BuildContext context, String? itemId) {
    if (itemId == null) return null;
    final items = context.read<InventoryViewModel>().items;
    try {
      final item = items.firstWhere((i) => i.id == itemId);
      final v = item.stats['colorValue'];
      return v != null ? Color(v) : null;
    } catch (_) {
      return null;
    }
  }

  /// Résout le nom d'affichage d'un objet cosmétique.
  String? _resolveName(BuildContext context, String? itemId) {
    if (itemId == null) return null;
    final items = context.read<InventoryViewModel>().items;
    try {
      return items.firstWhere((i) => i.id == itemId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitColor    = _resolveColor(context, cat.equippedOutfit);
    final pantsColor     = _resolveColor(context, cat.equippedPants);
    final shoesColor     = _resolveColor(context, cat.equippedShoes);
    final accessoryColor = _resolveColor(context, cat.equippedAccessory);
    final auraColor      = _resolveColor(context, cat.equippedAura);
    final titleName      = _resolveName(context, cat.equippedTitle);

    return Column(
      children: [
        // Glow derrière le chat (couleur de la race ou de l'aura)
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (auraColor ?? catBodyColor(cat.race)).withValues(alpha: 0.30),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: CatWidget(
              race: cat.race,
              equippedHat: cat.equippedHat,
              outfitColor: outfitColor,
              pantsColor: pantsColor,
              shoesColor: shoesColor,
              accessoryColor: accessoryColor,
              auraColor: auraColor,
              size: 200,
              mood: 'happy',
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Nom du chat
        Text(
          cat.name,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
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

        // Titre équipé (si présent)
        if (titleName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Text(
              '✨ $titleName',
              style: GoogleFonts.nunito(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
    (slot: 'hat',       label: 'Chapeau',      icon: Icons.dry_outlined),
    (slot: 'outfit',    label: 'Tenue',        icon: Icons.checkroom_outlined),
    (slot: 'pants',     label: 'Pantalon',     icon: Icons.accessibility_outlined),
    (slot: 'shoes',     label: 'Chaussures',   icon: Icons.directions_walk_outlined),
    (slot: 'aura',      label: 'Aura',         icon: Icons.auto_awesome_outlined),
    (slot: 'accessory', label: 'Accessoire',   icon: Icons.diamond_outlined),
    (slot: 'title',     label: 'Titre',        icon: Icons.workspace_premium_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
        alignment: WrapAlignment.center,
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
        'pants'     => cat.equippedPants,
        'shoes'     => cat.equippedShoes,
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
      useSafeArea: true,
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

  static String _rarityLabelShort(String r) => switch (r.toLowerCase()) {
        'common'    => 'Commun',
        'uncommon'  => 'Peu commun',
        'rare'      => 'Rare',
        'epic'      => 'Épique',
        'legendary' => 'Légendaire',
        'mythic'    => 'Mythique',
        _           => r,
      };

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
                  'pants'     => catProvider.mainCat?.equippedPants,
                  'shoes'     => catProvider.mainCat?.equippedShoes,
                  'aura'      => catProvider.mainCat?.equippedAura,
                  'accessory' => catProvider.mainCat?.equippedAccessory,
                  'title'     => catProvider.mainCat?.equippedTitle,
                  _           => null,
                };
                final isEquipped = equippedId == item.id;
                final rarityColor =
                    AppColors.getRarityColor(item.rarity.name);
                final colorVal = item.stats['colorValue'];
                final swatch = colorVal != null
                    ? Color(colorVal | 0xFF000000)
                    : null;

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
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        IconData(item.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: rarityColor,
                      ),
                      if (swatch != null)
                        Positioned(
                          right: -4,
                          bottom: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: swatch,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.backgroundDarkPanel,
                                  width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(item.name,
                      style: GoogleFonts.nunito(
                          color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: Text(
                    _rarityLabelShort(item.rarity.name),
                    style: TextStyle(color: rarityColor, fontSize: 11),
                  ),
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
// Mini bouton d'action (Randomize / Clear)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
