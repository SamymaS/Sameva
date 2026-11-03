import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/game_api.dart';
import 'package:uuid/uuid.dart';
import '../../../config/feature_flags.dart';
import '../../../data/models/item_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/ai_credit_counter.dart';
import '../../widgets/common/item_icon.dart';
import '../../widgets/pixel/pixel_ui.dart';
import '../invocation/invocation_page.dart';

/// Format compact pour grands nombres (ex. 1234 → 1,2k).
String _compactNumber(int n) {
  String un(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final v = n / 1000;
    return v >= 100 ? '${v.toStringAsFixed(0)}k' : '${un(v)}k';
  }
  final v = n / 1000000;
  return v >= 100 ? '${v.toStringAsFixed(0)}M' : '${un(v)}M';
}

String _rareteLabel(String r) => switch (r.toLowerCase()) {
      'common' => 'Commun',
      'uncommon' => 'Peu commun',
      'rare' => 'Rare',
      'epic' => 'Épique',
      'legendary' => 'Légendaire',
      'mythic' => 'Mythique',
      _ => r,
    };

/// Portail : Invocation (gacha), Boutique et Vendre, sous une barre unique
/// (énergie de l'Oracle, or, Sceaux). L'onglet Premium est gardé en code mais
/// masqué par drapeau. Style pixel.
class PortailPage extends StatelessWidget {
  const PortailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      appBar: pixelBarre(
        'Portail',
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Center(child: AiCreditCounter()),
          ),
          Consumer<PlayerViewModel>(
            builder: (_, player, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Solde(
                      icone: Icons.monetization_on,
                      couleur: PixelCouleurs.or,
                      valeur: player.stats?.gold ?? 0,
                      nom: 'or',
                    ),
                    const SizedBox(width: 6),
                    if (FeatureFlags.showMarketPremium)
                      _Solde(
                        icone: Icons.diamond,
                        couleur: PixelCouleurs.violetClair,
                        valeur: player.stats?.crystals ?? 0,
                        nom: 'cristaux',
                      )
                    else
                      _Solde(
                        icone: Icons.auto_awesome,
                        couleur: PixelCouleurs.violetClair,
                        valeur: player.stats?.seals ?? 0,
                        nom: 'Sceaux',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: FeatureFlags.showMarketPremium ? 4 : 3,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: PixelCouleurs.nuit,
                border: Border(bottom: BorderSide(color: PixelCouleurs.trait, width: 3)),
              ),
              child: TabBar(
                labelColor: PixelCouleurs.orClair,
                unselectedLabelColor: PixelCouleurs.texteDoux,
                indicator: const BoxDecoration(
                  color: PixelCouleurs.panneau,
                  border: Border(bottom: BorderSide(color: PixelCouleurs.or, width: 4)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: PixelTextes.corps(16, poids: FontWeight.w700),
                unselectedLabelStyle: PixelTextes.corps(16),
                tabs: const [
                  Tab(text: 'Invocation'),
                  Tab(text: 'Boutique'),
                  if (FeatureFlags.showMarketPremium) Tab(text: 'Premium'),
                  Tab(text: 'Vendre'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  InvocationTab(),
                  _ShopTab(),
                  if (FeatureFlags.showMarketPremium) _CrystalShopTab(),
                  _SellTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solde compact de la barre (icône et chiffre pixel), lu en entier.
class _Solde extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final int valeur;
  final String nom;

  const _Solde({required this.icone, required this.couleur, required this.valeur, required this.nom});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$valeur $nom',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: couleur, size: 16),
          const SizedBox(width: 3),
          Text(_compactNumber(valeur), style: PixelTextes.chiffres(9, couleur)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtres boutique : catégories d'objets
// ─────────────────────────────────────────────────────────────────────────────

enum _ShopFilter { all, equipment, potion, cosmetic }

extension _ShopFilterExt on _ShopFilter {
  String get label => switch (this) {
        _ShopFilter.all => 'Tout',
        _ShopFilter.equipment => 'Équipement',
        _ShopFilter.potion => 'Potions',
        _ShopFilter.cosmetic => 'Cosmétiques',
      };

  IconData get icone => switch (this) {
        _ShopFilter.all => Icons.storefront_outlined,
        _ShopFilter.equipment => Icons.shield_outlined,
        _ShopFilter.potion => Icons.local_pharmacy_outlined,
        _ShopFilter.cosmetic => Icons.checkroom_outlined,
      };

  bool matches(Item item) => switch (this) {
        _ShopFilter.all => true,
        _ShopFilter.equipment =>
          const {ItemType.weapon, ItemType.armor, ItemType.helmet, ItemType.boots, ItemType.ring}.contains(item.type),
        _ShopFilter.potion => item.type == ItemType.potion,
        _ShopFilter.cosmetic => item.type == ItemType.cosmetic,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet boutique
// ─────────────────────────────────────────────────────────────────────────────

class _ShopTab extends StatefulWidget {
  const _ShopTab();

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  final List<Item> _catalog = ItemFactory.getMarketCatalog();

  _ShopFilter _filter = _ShopFilter.all;

  List<Item> get _filtered => _catalog.where((i) => _filter.matches(i)).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Filtres
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in _ShopFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PixelChoix(
                    libelle: f.label,
                    icone: f.icone,
                    choisi: f == _filter,
                    onTap: () => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Inventaire plein
        Consumer<InventoryViewModel>(
          builder: (_, inventory, __) {
            if (!inventory.isFull) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelCadre(
                bord: const Color(0xFFFCA5A5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFCA5A5), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Inventaire plein : vends des objets pour faire de la place.',
                          style: PixelTextes.corps(15, couleur: const Color(0xFFFCA5A5))),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text('Aucun article dans cette catégorie.',
                textAlign: TextAlign.center, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
          )
        else
          for (final item in filtered)
            item.type == ItemType.cosmetic ? _CosmeticTile(item: item) : _ItemTile(item: item),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achat en or centralisé
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _executeBuyWithGold(BuildContext context, Item item, Color notificationColor) async {
  if (item.goldValue <= 0) return;
  final player = context.read<PlayerViewModel>();
  final inventory = context.read<InventoryViewModel>();
  if ((player.stats?.gold ?? 0) < item.goldValue) return;
  if (inventory.isFull) return;
  // Débit serveur d'abord ; l'objet n'arrive qu'après succès
  // (TRANSITOIRE jusqu'au Sprint 3, catalogue serveur).
  try {
    await player.spend(
      resource: 'gold',
      amount: item.goldValue,
      reason: 'marche_achat',
      ref: item.id,
    );
  } on GameApiException catch (e) {
    if (context.mounted) {
      AppNotification.show(context, message: e.userMessage, backgroundColor: AppColors.error);
    }
    return;
  }
  inventory.addItem(item.copyWith(id: const Uuid().v4()));
  if (!context.mounted) return;
  AppNotification.show(
    context,
    message: '${item.name} acheté !',
    backgroundColor: notificationColor,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Briques communes des tuiles
// ─────────────────────────────────────────────────────────────────────────────

/// Bouton d'achat compact (prix et état), cible tactile de 44 px.
class _BoutonAchat extends StatelessWidget {
  final String libelle;
  final bool actif;
  final VoidCallback? onTap;
  final String semantique;

  const _BoutonAchat({required this.libelle, required this.actif, required this.onTap, required this.semantique});

  @override
  Widget build(BuildContext context) {
    final bord = actif ? PixelCouleurs.orClair : PixelCouleurs.trait;
    return Semantics(
      container: true,
      button: true,
      enabled: actif,
      label: semantique,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: actif ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 84),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: actif ? PixelCouleurs.or : PixelCouleurs.panneauProfond,
            border: Border(
              top: BorderSide(color: bord, width: 2),
              left: BorderSide(color: bord, width: 2),
              right: BorderSide(color: bord, width: 2),
              bottom: BorderSide(color: actif ? PixelCouleurs.orSombre : PixelCouleurs.trait, width: 5),
            ),
          ),
          child: Text(libelle,
              style: PixelTextes.corps(15,
                  couleur: actif ? PixelCouleurs.nuit : PixelCouleurs.texteDoux, poids: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// Prix pixel : icône et montant.
class _Prix extends StatelessWidget {
  final int montant;
  final bool abordable;
  final IconData icone;
  final Color couleur;

  const _Prix(this.montant, {required this.abordable, this.icone = Icons.monetization_on, this.couleur = PixelCouleurs.or});

  @override
  Widget build(BuildContext context) {
    final c = abordable ? couleur : PixelCouleurs.texteDoux;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: c, size: 16),
        const SizedBox(width: 4),
        Text(_compactNumber(montant), style: PixelTextes.chiffres(9, c)),
      ],
    );
  }
}

/// Vignette d'objet carrée, bord de la couleur de rareté.
class _Vignette extends StatelessWidget {
  final Item item;
  final Color rarete;
  const _Vignette(this.item, this.rarete);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PixelCouleurs.panneauProfond,
        border: Border.all(color: rarete, width: 2),
      ),
      child: ItemIcon(item: item, size: 40, showBackground: false),
    );
  }
}

String _etatAchat({required bool abordable, required bool place}) =>
    abordable && place ? 'Acheter' : (!place ? 'Plein' : 'Trop cher');

// ─────────────────────────────────────────────────────────────────────────────
// Tuile équipement / potion
// ─────────────────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final Item item;

  const _ItemTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  String _typeLabel(ItemType t) => switch (t) {
        ItemType.weapon => 'Arme',
        ItemType.armor => 'Armure',
        ItemType.helmet => 'Casque',
        ItemType.boots => 'Bottes',
        ItemType.ring => 'Anneau',
        ItemType.potion => 'Potion',
        ItemType.material => 'Matériau',
        ItemType.cosmetic => 'Cosmétique',
      };

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, InventoryViewModel>(
      builder: (ctx, player, inventory, _) {
        final canAfford = (player.stats?.gold ?? 0) >= item.goldValue;
        final hasSpace = !inventory.isFull;
        final etat = _etatAchat(abordable: canAfford, place: hasSpace);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PixelCadre(
            bord: canAfford ? _rarityColor : PixelCouleurs.trait,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Vignette(item, _rarityColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: PixelTextes.corps(16,
                              couleur: canAfford ? PixelCouleurs.texte : PixelCouleurs.texteDoux,
                              poids: FontWeight.w700)),
                      Text('${_typeLabel(item.type)} · ${_rareteLabel(item.rarity.name)}',
                          style: PixelTextes.corps(14, couleur: _rarityColor)),
                      if (item.stats.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: item.stats.entries.where((e) => e.value != 0).map((e) {
                            final label = switch (e.key) {
                              'hpBonus' => 'PV +${e.value}',
                              'xpBonus' => 'XP +${e.value} %',
                              'goldBonus' => 'Or +${e.value} %',
                              'moralBonus' => 'Moral +${e.value}',
                              _ => '${e.key} +${e.value}',
                            };
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              color: PixelCouleurs.panneauProfond,
                              child: Text(label, style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Prix(item.goldValue, abordable: canAfford),
                    const SizedBox(height: 8),
                    _BoutonAchat(
                      libelle: etat,
                      actif: canAfford && hasSpace,
                      semantique: '$etat ${item.name}, ${item.goldValue} or',
                      onTap: () => _executeBuyWithGold(ctx, item, AppColors.primaryViolet.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile cosmétique
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticTile extends StatelessWidget {
  final Item item;

  const _CosmeticTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, InventoryViewModel>(
      builder: (ctx, player, inventory, _) {
        final canAfford = (player.stats?.gold ?? 0) >= item.goldValue;
        final hasSpace = !inventory.isFull;
        final etat = _etatAchat(abordable: canAfford, place: hasSpace);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PixelCadre(
            bord: _rarityColor,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Toucher la vignette et le texte : aperçu sur le chat
                Expanded(
                  child: MergeSemantics(
                    child: Semantics(
                      button: true,
                      hint: 'Aperçu sur ton chat',
                      child: GestureDetector(
                        onTap: () => _showPreviewSheet(ctx),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            _Vignette(item, _rarityColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: PixelTextes.corps(16, poids: FontWeight.w700)),
                                  Text(item.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                                  Text(_rareteLabel(item.rarity.name),
                                      style: PixelTextes.corps(14, couleur: _rarityColor, poids: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Prix(item.goldValue, abordable: canAfford),
                    const SizedBox(height: 8),
                    _BoutonAchat(
                      libelle: etat,
                      actif: canAfford && hasSpace,
                      semantique: '$etat ${item.name}, ${item.goldValue} or',
                      onTap: () => _executeBuyWithGold(ctx, item, AppColors.mintMagic.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreviewSheet(BuildContext context) {
    final cat = context.read<CatViewModel>().mainCat;
    final race = cat?.race ?? 'cosmos';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PixelCouleurs.panneau,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(side: BorderSide(color: _rarityColor, width: 3)),
      builder: (_) => _CosmeticPreviewSheet(item: item, race: race, buyContext: context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feuille d'aperçu d'un cosmétique sur le chat
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticPreviewSheet extends StatelessWidget {
  final Item item;
  final String race;

  /// Contexte de la page : l'achat et sa notification survivent à la
  /// fermeture de la feuille (son propre contexte est démonté aussitôt).
  final BuildContext buyContext;

  const _CosmeticPreviewSheet({required this.item, required this.race, required this.buyContext});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.getRarityColor(item.rarity.name);

    // La plupart des cosmétiques ont un aperçu direct sur le chat
    final slot = item.cosmeticSlot;
    const previewableSlots = {'hat', 'outfit', 'pants', 'shoes', 'accessory', 'aura'};
    final showCatPreview = previewableSlots.contains(slot);
    final hatId = slot == 'hat' ? item.id : null;

    // Couleur depuis stats['colorValue'] selon l'emplacement
    final colorVal = item.stats['colorValue'];
    final resolved = colorVal != null ? Color(colorVal | 0xFF000000) : null;
    final outfitColor = slot == 'outfit' ? resolved : null;
    final pantsColor = slot == 'pants' ? resolved : null;
    final shoesColor = slot == 'shoes' ? resolved : null;
    final accessoryColor = slot == 'accessory' ? resolved : null;
    final auraColor = slot == 'aura' ? resolved : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCatPreview)
            Center(
              child: SizedBox(
                width: 190,
                height: 170,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (auraColor != null) Positioned(bottom: 18, child: PixelAnneau(cote: 150, couleur: auraColor)),
                    const Positioned(
                      bottom: 0,
                      child: SizedBox(
                        width: 150,
                        height: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: PixelCouleurs.panneauProfond,
                            border: Border(top: BorderSide(color: PixelCouleurs.trait, width: 3)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -9,
                      child: CatWidget(
                        race: race,
                        equippedHat: hatId,
                        outfitColor: outfitColor,
                        pantsColor: pantsColor,
                        shoesColor: shoesColor,
                        accessoryColor: accessoryColor,
                        auraColor: auraColor,
                        size: 150,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Center(child: ItemIcon(item: item, size: 72, showBackground: false)),
            const SizedBox(height: 8),
            Text('Aperçu disponible après équipement',
                textAlign: TextAlign.center, style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
          ],
          const SizedBox(height: 18),
          Text(item.name, textAlign: TextAlign.center, style: PixelTextes.chiffres(12, PixelCouleurs.texte)),
          const SizedBox(height: 6),
          Text(_rareteLabel(item.rarity.name),
              textAlign: TextAlign.center, style: PixelTextes.corps(15, couleur: rarityColor, poids: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(item.description,
              textAlign: TextAlign.center, style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
          const SizedBox(height: 18),
          Consumer2<PlayerViewModel, InventoryViewModel>(
            builder: (ctx, player, inventory, _) {
              final canAfford = (player.stats?.gold ?? 0) >= item.goldValue;
              final hasSpace = !inventory.isFull;
              return PixelBouton(
                libelle: canAfford && hasSpace
                    ? 'Acheter · ${item.goldValue} or'
                    : _etatAchat(abordable: canAfford, place: hasSpace),
                onPressed: canAfford && hasSpace
                    ? () {
                        Navigator.pop(ctx);
                        _executeBuyWithGold(buyContext, item, AppColors.mintMagic.withValues(alpha: 0.9));
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet boutique premium (cristaux)
// ─────────────────────────────────────────────────────────────────────────────

class _CrystalShopTab extends StatelessWidget {
  const _CrystalShopTab();

  @override
  Widget build(BuildContext context) {
    final catalog = ItemFactory.getCrystalCatalog();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: catalog.length,
      itemBuilder: (ctx, i) => _CrystalTile(item: catalog[i]),
    );
  }
}

class _CrystalTile extends StatelessWidget {
  final Item item;

  const _CrystalTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, InventoryViewModel>(
      builder: (ctx, player, inventory, _) {
        final canAfford = (player.stats?.crystals ?? 0) >= item.crystalValue;
        final hasSpace = !inventory.isFull;
        final etat = _etatAchat(abordable: canAfford, place: hasSpace);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PixelCadre(
            bord: _rarityColor,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Vignette(item, _rarityColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: PixelTextes.corps(16, poids: FontWeight.w700)),
                      Text(item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                      Text(_rareteLabel(item.rarity.name),
                          style: PixelTextes.corps(14, couleur: _rarityColor, poids: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Prix(item.crystalValue,
                        abordable: canAfford, icone: Icons.diamond, couleur: PixelCouleurs.violetClair),
                    const SizedBox(height: 8),
                    _BoutonAchat(
                      libelle: etat,
                      actif: canAfford && hasSpace,
                      semantique: '$etat ${item.name}, ${item.crystalValue} cristaux',
                      onTap: () => _buy(ctx, player, inventory),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _buy(BuildContext context, PlayerViewModel player, InventoryViewModel inventory) async {
    if (item.crystalValue <= 0) return;
    if ((player.stats?.crystals ?? 0) < item.crystalValue) return;
    if (inventory.isFull) return;
    // Débit serveur d'abord (TRANSITOIRE jusqu'au Sprint 3).
    try {
      await player.spend(
        resource: 'crystals',
        amount: item.crystalValue,
        reason: 'boutique_cristaux',
        ref: item.id,
      );
    } on GameApiException catch (e) {
      if (context.mounted) {
        AppNotification.show(context, message: e.userMessage, backgroundColor: AppColors.error);
      }
      return;
    }
    final newItem = item.copyWith(id: const Uuid().v4());
    inventory.addItem(newItem);
    if (!context.mounted) return;
    AppNotification.show(
      context,
      message: '${item.name} acheté !',
      backgroundColor: AppColors.crystalBlue.withValues(alpha: 0.9),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet vente
// ─────────────────────────────────────────────────────────────────────────────

class _SellTab extends StatelessWidget {
  const _SellTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryViewModel>(
      builder: (context, inventory, _) {
        final sellable = inventory.items.where((i) => !i.isLocked).toList();
        if (inventory.items.isEmpty || sellable.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                inventory.items.isEmpty ? 'Ton inventaire est vide.' : 'Tous tes objets sont verrouillés.',
                textAlign: TextAlign.center,
                style: PixelTextes.corps(17, couleur: PixelCouleurs.texteDoux),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: sellable.length,
          itemBuilder: (context, i) {
            final item = sellable[i];
            final sellPrice = (item.goldValue * 0.5).round();
            final color = AppColors.getRarityColor(item.rarity.name);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelCadre(
                bord: color,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _Vignette(item, color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PixelTextes.corps(16, poids: FontWeight.w700)),
                          Text('Revente : $sellPrice or (50 %)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BoutonAchat(
                      libelle: '+${_compactNumber(sellPrice)}',
                      actif: true,
                      semantique: 'Vendre ${item.name} pour $sellPrice or',
                      onTap: () => _confirmSell(context, inventory, item, sellPrice),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSell(BuildContext context, InventoryViewModel inventory, Item item, int sellPrice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => PixelDialogue(
        titre: 'Vendre',
        contenu: Text('Vendre ${item.name} pour $sellPrice or ?',
            textAlign: TextAlign.center, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
        actions: [
          PixelBouton(libelle: 'Annuler', principal: false, onPressed: () => Navigator.pop(ctx, false)),
          PixelBouton(libelle: 'Vendre', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      _sell(context, inventory, item, sellPrice);
    }
  }

  Future<void> _sell(BuildContext context, InventoryViewModel inventory, Item item, int sellPrice) async {
    final player = context.read<PlayerViewModel>();
    // Crédit serveur plafonné d'abord (TRANSITOIRE jusqu'au Sprint 3) ;
    // l'objet ne quitte l'inventaire qu'après succès.
    final int granted;
    try {
      granted = (await player.claimTransitionalReward('vente_objet', sellPrice, ref: item.id)).grantedInt;
    } on GameApiException catch (e) {
      if (context.mounted) {
        AppNotification.show(context, message: e.userMessage, backgroundColor: AppColors.error);
      }
      return;
    }
    if (!context.mounted) return;
    if (granted <= 0) {
      AppNotification.show(context,
          message: 'Limite de ventes du jour atteinte. Reviens demain !', backgroundColor: AppColors.warning);
      return;
    }
    inventory.removeItem(item.id, force: true);
    AppNotification.show(
      context,
      message: granted < sellPrice
          ? '${item.name} vendu pour $granted or (plafond du jour atteint).'
          : '${item.name} vendu pour $granted or.',
      backgroundColor: AppColors.gold.withValues(alpha: 0.85),
    );
  }
}
