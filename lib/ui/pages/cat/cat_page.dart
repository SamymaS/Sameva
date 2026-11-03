import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/game_api.dart';
import '../../../config/feature_flags.dart';
import '../../../data/models/cat_model.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/item_icon.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Page principale du chat compagnon (style pixel).
/// Affiche le chat sur son socle avec ses cosmétiques équipés et permet de les gérer.
class CatPage extends StatelessWidget {
  const CatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatViewModel>(
      builder: (context, catProvider, _) {
        final cat = catProvider.mainCat;

        if (cat == null) {
          return const _EmptyCatState();
        }

        return _CatPageContent(cat: cat, catProvider: catProvider);
      },
    );
  }
}

String _rarityLabel(String r) => switch (r.toLowerCase()) {
      'common' => 'Commun',
      'uncommon' => 'Peu commun',
      'rare' => 'Rare',
      'epic' => 'Épique',
      'legendary' => 'Légendaire',
      'mythic' => 'Mythique',
      _ => r,
    };

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

    // Gain de moral accordé par le serveur, plafonné par jour
    // (TRANSITOIRE jusqu'au Sprint 3).
    var message = 'Ronron... ton chat est ravi !';
    try {
      final reward = await context
          .read<PlayerViewModel>()
          .claimTransitionalReward('caresse_chat', 0.05);
      if (reward.granted > 0) {
        message = 'Ronron... +${(reward.granted * 100).round()} % de moral !';
      }
    } on GameApiException catch (e) {
      debugPrint('CatPage: caresse non créditée: $e');
    }
    if (!mounted) return;
    setState(() {});
    AppNotification.show(
      context,
      message: message,
      backgroundColor: AppColors.mintMagic,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPet = _canPet;
    final remaining = canPet ? null : _cooldownRemaining;
    final cooldownLabel = remaining != null
        ? '${remaining.inHours} h ${remaining.inMinutes.remainder(60)} min'
        : null;

    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      appBar: pixelBarre(
        'Mon chat',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: PixelCouleurs.texteDoux),
            onPressed: () => _showRenameDialog(context),
            tooltip: 'Renommer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Le chat sur son socle ────────────────────────────────────────
          _CatHeroSection(cat: widget.cat),
          const SizedBox(height: 20),

          // ── Caresser ─────────────────────────────────────────────────────
          PixelBouton(
            libelle: canPet ? 'Caresser (+5 % de moral)' : 'Disponible dans $cooldownLabel',
            onPressed: canPet ? _petCat : null,
          ),
          const SizedBox(height: 28),

          // ── Cosmétiques ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Cosmétiques', style: PixelTextes.chiffres(11, PixelCouleurs.violetClair)),
                ),
              ),
              _MiniActionBtn(
                icon: Icons.shuffle,
                label: 'Aléatoire',
                color: PixelCouleurs.violetClair,
                onTap: () => _randomizeOutfit(context),
              ),
              const SizedBox(width: 8),
              _MiniActionBtn(
                icon: Icons.layers_clear_outlined,
                label: 'Retirer',
                color: PixelCouleurs.texteDoux,
                onTap: () => _clearAll(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CosmeticSlots(cat: widget.cat, catProvider: widget.catProvider),
        ],
      ),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => PixelDialogue(
        titre: 'Tout retirer',
        contenu: Text(
          'Retirer tous les cosmétiques équipés de ${widget.cat.name} ?',
          textAlign: TextAlign.center,
          style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux),
        ),
        actions: [
          PixelBouton(libelle: 'Annuler', principal: false, onPressed: () => Navigator.pop(ctx, false)),
          PixelBouton(libelle: 'Retirer', onPressed: () => Navigator.pop(ctx, true)),
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
      builder: (ctx) => PixelDialogue(
        titre: 'Renommer',
        contenu: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          style: PixelTextes.corps(17),
          decoration: pixelChamp(exemple: 'Nom du chat').copyWith(labelText: 'Nom du chat'),
        ),
        actions: [
          PixelBouton(libelle: 'Annuler', principal: false, onPressed: () => Navigator.pop(ctx)),
          PixelBouton(
            libelle: 'Renommer',
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await widget.catProvider.renameCat(widget.cat.id, name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section hero : le chat posé sur un socle, aura en anneau pixel
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
    final outfitColor = _resolveColor(context, cat.equippedOutfit);
    final pantsColor = _resolveColor(context, cat.equippedPants);
    final shoesColor = _resolveColor(context, cat.equippedShoes);
    final accessoryColor = _resolveColor(context, cat.equippedAccessory);
    final auraColor = _resolveColor(context, cat.equippedAura);
    final titleName = _resolveName(context, cat.equippedTitle);
    final rarete = AppColors.getRarityColor(cat.rarity);

    return PixelCadre(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          SizedBox(
            width: 230,
            height: 210,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Aura équipée : anneau pixel derrière le chat.
                if (auraColor != null)
                  Positioned(bottom: 22, child: PixelAnneau(cote: 190, couleur: auraColor)),
                // Socle et ombre.
                const Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: 190,
                    height: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PixelCouleurs.panneauProfond,
                        border: Border(top: BorderSide(color: PixelCouleurs.trait, width: 3)),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 20,
                  child: SizedBox(width: 120, height: 8, child: ColoredBox(color: PixelCouleurs.abysse)),
                ),
                // Marge transparente sous les pattes du sprite : on le descend
                // d'autant pour qu'il repose sur l'ombre (comme au sanctuaire).
                Positioned(
                  bottom: -11,
                  child: CatWidget(
                    race: cat.race,
                    equippedHat: cat.equippedHat,
                    outfitColor: outfitColor,
                    pantsColor: pantsColor,
                    shoesColor: shoesColor,
                    accessoryColor: accessoryColor,
                    auraColor: auraColor,
                    size: 192,
                    mood: 'happy',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            cat.name,
            textAlign: TextAlign.center,
            style: PixelTextes.chiffres(16, PixelCouleurs.texte).copyWith(
              shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(2, 2))],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(_raceLabel(cat.race), style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: rarete, width: 2)),
                child: Text(_rarityLabel(cat.rarity),
                    style: PixelTextes.corps(14, couleur: rarete, poids: FontWeight.w700)),
              ),
            ],
          ),
          if (titleName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: PixelCouleurs.panneauProfond,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: PixelCouleurs.or),
                  const SizedBox(width: 6),
                  Text(titleName, style: PixelTextes.corps(15, couleur: PixelCouleurs.orClair, poids: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _raceLabel(String race) => switch (race) {
        'michi' => 'Michi · Sage',
        'lune' => 'Lune · Mystérieux',
        'braise' => 'Braise · Énergique',
        'neige' => 'Neige · Doux',
        'cosmos' => 'Cosmos · Mystique',
        'sakura' => 'Sakura · Joyeux',
        _ => race,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Grille de slots cosmétiques
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticSlots extends StatelessWidget {
  final CatStats cat;
  final CatViewModel catProvider;

  const _CosmeticSlots({required this.cat, required this.catProvider});

  // Slots de base toujours visibles + slots extra masqués pour le MVP
  // (showExtraCosmeticSlots) : Pantalon, Chaussures, Accessoire, Titre.
  static const _baseSlots = [
    (slot: 'hat', label: 'Chapeau', icon: Icons.dry_outlined),
    (slot: 'outfit', label: 'Tenue', icon: Icons.checkroom_outlined),
    (slot: 'aura', label: 'Aura', icon: Icons.auto_awesome_outlined),
  ];

  static const _extraSlots = [
    (slot: 'pants', label: 'Pantalon', icon: Icons.accessibility_outlined),
    (slot: 'shoes', label: 'Chaussures', icon: Icons.directions_walk_outlined),
    (slot: 'accessory', label: 'Accessoire', icon: Icons.diamond_outlined),
    (slot: 'title', label: 'Titre', icon: Icons.workspace_premium_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final slots = [
      ..._baseSlots,
      if (FeatureFlags.showExtraCosmeticSlots) ..._extraSlots,
    ];
    final items = context.watch<InventoryViewModel>().items;
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: slots.map((s) {
        final equippedId = _equippedForSlot(s.slot);
        Item? equipped;
        if (equippedId != null) {
          for (final i in items) {
            if (i.id == equippedId) equipped = i;
          }
        }
        return _SlotButton(
          label: s.label,
          icon: s.icon,
          equipped: equipped,
          isEquipped: equippedId != null,
          onTap: () => _showCosmeticSheet(context, s.slot, s.label),
        );
      }).toList(),
    );
  }

  String? _equippedForSlot(String slot) => switch (slot) {
        'hat' => cat.equippedHat,
        'outfit' => cat.equippedOutfit,
        'pants' => cat.equippedPants,
        'shoes' => cat.equippedShoes,
        'aura' => cat.equippedAura,
        'accessory' => cat.equippedAccessory,
        'title' => cat.equippedTitle,
        _ => null,
      };

  void _showCosmeticSheet(BuildContext context, String slot, String label) {
    final inventory = context.read<InventoryViewModel>();
    // Filtrer les items cosmétiques correspondant au slot
    final cosmetics = inventory.items.where((item) => item.cosmeticSlot == slot).toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PixelCouleurs.panneau,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: PixelCouleurs.violet, width: 3),
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
  final Item? equipped;
  final bool isEquipped;
  final VoidCallback onTap;

  const _SlotButton({
    required this.label,
    required this.icon,
    required this.equipped,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bord = isEquipped ? PixelCouleurs.violetClair : PixelCouleurs.trait;
    return Semantics(
      container: true,
      button: true,
      label: isEquipped && equipped != null ? '$label : ${equipped!.name}' : '$label : vide',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEquipped ? PixelCouleurs.violetSombre : PixelCouleurs.panneau,
                  border: Border(
                    top: BorderSide(color: bord, width: 3),
                    left: BorderSide(color: bord, width: 3),
                    right: BorderSide(color: bord, width: 3),
                    bottom: BorderSide(color: bord, width: 6),
                  ),
                ),
                child: equipped != null
                    ? ItemIcon(item: equipped!, size: 40, showBackground: false)
                    : Icon(icon, color: isEquipped ? PixelCouleurs.violetClair : PixelCouleurs.texteDoux, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: PixelTextes.corps(14, couleur: isEquipped ? PixelCouleurs.texte : PixelCouleurs.texteDoux)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feuille du bas : liste des cosmétiques disponibles
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticSheet extends StatelessWidget {
  final String label;
  final String slot;
  final List<Item> cosmetics;
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Semantics(
            header: true,
            child: Text(label, style: PixelTextes.chiffres(12, PixelCouleurs.orClair)),
          ),
          const SizedBox(height: 14),
          if (cosmetics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucun cosmétique disponible.\nObtiens-en au Marché ou au Portail !',
                textAlign: TextAlign.center,
                style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux),
              ),
            )
          else
            for (final item in cosmetics) ...[
              _LigneCosmetique(
                item: item,
                isEquipped: _equippedId() == item.id,
                onTap: () async {
                  final isEquipped = _equippedId() == item.id;
                  await catProvider.equipCosmetic(cat.id, slot, isEquipped ? null : item.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  String? _equippedId() => switch (slot) {
        'hat' => catProvider.mainCat?.equippedHat,
        'outfit' => catProvider.mainCat?.equippedOutfit,
        'pants' => catProvider.mainCat?.equippedPants,
        'shoes' => catProvider.mainCat?.equippedShoes,
        'aura' => catProvider.mainCat?.equippedAura,
        'accessory' => catProvider.mainCat?.equippedAccessory,
        'title' => catProvider.mainCat?.equippedTitle,
        _ => null,
      };
}

class _LigneCosmetique extends StatelessWidget {
  final Item item;
  final bool isEquipped;
  final VoidCallback onTap;

  const _LigneCosmetique({required this.item, required this.isEquipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.getRarityColor(item.rarity.name);
    final colorVal = item.stats['colorValue'];
    final swatch = colorVal != null ? Color(colorVal | 0xFF000000) : null;

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isEquipped,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: PixelCadre(
            fond: isEquipped ? PixelCouleurs.violetSombre : PixelCouleurs.panneauProfond,
            bord: isEquipped ? PixelCouleurs.violetClair : rarityColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ItemIcon(item: item, size: 36, showBackground: false),
                if (swatch != null) ...[
                  const SizedBox(width: 8),
                  Container(width: 12, height: 12, color: swatch),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: PixelTextes.corps(16, poids: FontWeight.w700)),
                      Text(_rarityLabel(item.rarity.name), style: PixelTextes.corps(14, couleur: rarityColor)),
                    ],
                  ),
                ),
                if (isEquipped)
                  Text('Équipé', style: PixelTextes.corps(14, couleur: const Color(0xFF4ADE80), poids: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État vide (pas de chat)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCatState extends StatelessWidget {
  const _EmptyCatState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CatWidget(race: 'michi', size: 128, mood: 'sleepy'),
              const SizedBox(height: 24),
              Text(
                'Pas encore de chat compagnon',
                textAlign: TextAlign.center,
                style: PixelTextes.chiffres(12, PixelCouleurs.texte),
              ),
              const SizedBox(height: 12),
              Text(
                'Termine l\'accueil pour choisir ton chat.',
                textAlign: TextAlign.center,
                style: PixelTextes.corps(17, couleur: PixelCouleurs.texteDoux),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini bouton d'action (Aléatoire / Retirer)
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
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: PixelCouleurs.panneau,
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: PixelTextes.corps(15, couleur: color, poids: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
