import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/item_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/rarity_badge.dart';
import '../invocation/invocation_page.dart';

/// Format compact pour grands nombres (ex. 1234 → 1.2k).
String _compactNumber(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final v = n / 1000;
    return v >= 100 ? '${v.toStringAsFixed(0)}k' : '${v.toStringAsFixed(1)}k';
  }
  final v = n / 1000000;
  return v >= 100 ? '${v.toStringAsFixed(0)}M' : '${v.toStringAsFixed(1)}M';
}

/// Page marché : boutique cosmétiques pour chats + vente d'items.
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightCosmos,
        elevation: 0,
        title: Text(
          'Marché',
          style: GoogleFonts.nunito(
            color: AppColors.primaryVioletLight,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<PlayerViewModel>(
            builder: (_, player, __) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _compactNumber(player.stats?.gold ?? 0),
                      style: GoogleFonts.nunito(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.diamond,
                        color: AppColors.crystalBlue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _compactNumber(player.stats?.crystals ?? 0),
                      style: GoogleFonts.nunito(
                        color: AppColors.crystalBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'Invocation',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InvocationPage()),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.primaryVioletLight,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryVioletLight,
              labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Boutique'),
                Tab(text: 'Premium'),
                Tab(text: 'Vendre'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _ShopTab(),
                  _CrystalShopTab(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Filtres boutique — catégories d'items
// ─────────────────────────────────────────────────────────────────────────────

enum _ShopFilter { all, equipment, potion, cosmetic }

extension _ShopFilterExt on _ShopFilter {
  String get label => switch (this) {
        _ShopFilter.all       => 'Tout',
        _ShopFilter.equipment => 'Équipement',
        _ShopFilter.potion    => 'Potions',
        _ShopFilter.cosmetic  => 'Cosmétiques',
      };

  String get emoji => switch (this) {
        _ShopFilter.all       => '🛒',
        _ShopFilter.equipment => '⚔️',
        _ShopFilter.potion    => '🧪',
        _ShopFilter.cosmetic  => '✨',
      };

  bool matches(Item item) => switch (this) {
        _ShopFilter.all       => true,
        _ShopFilter.equipment => const {
            ItemType.weapon, ItemType.armor, ItemType.helmet,
            ItemType.boots, ItemType.ring
          }.contains(item.type),
        _ShopFilter.potion    => item.type == ItemType.potion,
        _ShopFilter.cosmetic  => item.type == ItemType.cosmetic,
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

  List<Item> get _filtered =>
      _catalog.where((i) => _filter.matches(i)).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtres
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _ShopFilter.values.map((f) {
              final active = f == _filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    '${f.emoji}  ${f.label}',
                    style: TextStyle(
                      fontSize: 12,
                      color: active
                          ? AppColors.backgroundNightCosmos
                          : AppColors.textSecondary,
                    ),
                  ),
                  selected: active,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.primaryVioletLight,
                  backgroundColor: AppColors.backgroundDarkPanel,
                  checkmarkColor: AppColors.backgroundNightCosmos,
                  side: BorderSide(
                    color: active
                        ? AppColors.primaryVioletLight
                        : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),

        // Inventaire plein
        Consumer<InventoryViewModel>(
          builder: (_, inventory, __) {
            if (!inventory.isFull) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.coralRare.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.coralRare.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.coralRare, size: 14),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Inventaire plein — vendez des objets pour faire de la place.',
                      style:
                          TextStyle(color: AppColors.coralRare, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Liste items
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'Aucun article dans cette catégorie.',
                    style: GoogleFonts.nunito(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = _filtered[i];
                    return item.type == ItemType.cosmetic
                        ? _CosmeticTile(item: item)
                        : _ItemTile(item: item);
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achat gold centralisé
// ─────────────────────────────────────────────────────────────────────────────

void _executeBuyWithGold(
    BuildContext context, Item item, Color notificationColor) {
  if (item.goldValue <= 0) return;
  final auth = context.read<AuthViewModel>();
  final player = context.read<PlayerViewModel>();
  final inventory = context.read<InventoryViewModel>();
  if ((player.stats?.gold ?? 0) < item.goldValue) return;
  if (inventory.isFull) return;
  final userId = auth.userId ?? '';
  inventory.addItem(item.copyWith(id: const Uuid().v4()));
  player.addGold(userId, -item.goldValue);
  AppNotification.show(
    context,
    message: '${item.name} acheté !',
    backgroundColor: notificationColor,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile équipement / potion
// ─────────────────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final Item item;

  const _ItemTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  String _typeLabel(ItemType t) => switch (t) {
        ItemType.weapon   => 'Arme',
        ItemType.armor    => 'Armure',
        ItemType.helmet   => 'Casque',
        ItemType.boots    => 'Bottes',
        ItemType.ring     => 'Anneau',
        ItemType.potion   => 'Potion',
        ItemType.material => 'Matériau',
        ItemType.cosmetic => 'Cosmétique',
      };

  IconData _typeIcon(ItemType t) => switch (t) {
        ItemType.weapon   => Icons.sports_martial_arts_outlined,
        ItemType.armor    => Icons.shield_outlined,
        ItemType.helmet   => Icons.face_outlined,
        ItemType.boots    => Icons.directions_run_outlined,
        ItemType.ring     => Icons.circle_outlined,
        ItemType.potion   => Icons.local_pharmacy_outlined,
        ItemType.material => Icons.category_outlined,
        ItemType.cosmetic => Icons.auto_fix_high_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, InventoryViewModel>(
      builder: (ctx, player, inventory, _) {
        final canAfford = (player.stats?.gold ?? 0) >= item.goldValue;
        final hasSpace = !inventory.isFull;

        return GestureDetector(
          onTap: canAfford && hasSpace
              ? () => _buy(ctx)
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _rarityColor.withValues(alpha: canAfford ? 0.35 : 0.15)),
            ),
            child: Row(
              children: [
                // Icône type
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(item.type),
                      color: _rarityColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.nunito(
                          color: canAfford ? _rarityColor : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _typeLabel(item.type),
                        style: GoogleFonts.nunito(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                      if (item.stats.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: item.stats.entries
                              .where((e) => e.value != 0)
                              .map((e) {
                            final label = switch (e.key) {
                              'hpBonus'    => 'HP +${e.value}',
                              'xpBonus'    => 'XP +${e.value}%',
                              'goldBonus'  => 'Or +${e.value}%',
                              'moralBonus' => 'Moral +${e.value}',
                              _            => '${e.key} +${e.value}',
                            };
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _rarityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(label,
                                  style: TextStyle(
                                      color: _rarityColor, fontSize: 9)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Prix + bouton
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on,
                            color: canAfford
                                ? AppColors.gold
                                : AppColors.textMuted,
                            size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${item.goldValue}',
                          style: GoogleFonts.nunito(
                            color: canAfford
                                ? AppColors.gold
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: canAfford && hasSpace
                            ? AppColors.primaryViolet.withValues(alpha: 0.20)
                            : AppColors.textMuted.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canAfford && hasSpace
                              ? AppColors.primaryVioletLight
                              : AppColors.inputBorder,
                        ),
                      ),
                      child: Text(
                        canAfford && hasSpace
                            ? 'Acheter'
                            : !hasSpace
                                ? 'Plein'
                                : 'Trop cher',
                        style: GoogleFonts.nunito(
                          color: canAfford && hasSpace
                              ? AppColors.primaryVioletLight
                              : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  void _buy(BuildContext context) {
    _executeBuyWithGold(context, item, AppColors.primaryViolet.withValues(alpha: 0.9));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile cosmétique
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticTile extends StatelessWidget {
  final Item item;

  const _CosmeticTile({required this.item});

  Color get _rarityColor => AppColors.getRarityColor(item.rarity.name);

  String get _slotEmoji => switch (item.cosmeticSlot) {
        'hat'       => '🎩',
        'outfit'    => '👘',
        'pants'     => '👖',
        'shoes'     => '👟',
        'aura'      => '🌟',
        'accessory' => '💎',
        'title'     => '🏆',
        _           => '✨',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreviewSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _rarityColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            // Emoji slot
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _rarityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(_slotEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.nunito(
                      color: _rarityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: GoogleFonts.nunito(
                        color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  RarityBadge(rarity: item.rarity.name, compact: true),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Prix + bouton
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppColors.gold, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${item.goldValue}',
                      style: GoogleFonts.nunito(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Consumer2<PlayerViewModel, InventoryViewModel>(
                  builder: (ctx, player, inventory, _) {
                    final canAfford =
                        (player.stats?.gold ?? 0) >= item.goldValue;
                    final hasSpace = !inventory.isFull;
                    return GestureDetector(
                      onTap: canAfford && hasSpace
                          ? () => _buy(ctx)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: canAfford && hasSpace
                              ? AppColors.primaryViolet.withValues(alpha: 0.20)
                              : AppColors.textMuted.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canAfford && hasSpace
                                ? AppColors.primaryVioletLight
                                : AppColors.inputBorder,
                          ),
                        ),
                        child: Text(
                          canAfford && hasSpace
                              ? 'Acheter'
                              : !hasSpace
                                  ? 'Plein'
                                  : 'Trop cher',
                          style: GoogleFonts.nunito(
                            color: canAfford && hasSpace
                                ? AppColors.primaryVioletLight
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _buy(BuildContext context) {
    _executeBuyWithGold(context, item, AppColors.mintMagic.withValues(alpha: 0.9));
  }

  void _showPreviewSheet(BuildContext context) {
    final cat = context.read<CatViewModel>().mainCat;
    final race = cat?.race ?? 'cosmos';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDarkPanel,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CosmeticPreviewSheet(item: item, race: race),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BottomSheet aperçu cosmétique sur le chat
// ─────────────────────────────────────────────────────────────────────────────

class _CosmeticPreviewSheet extends StatelessWidget {
  final Item item;
  final String race;

  const _CosmeticPreviewSheet({required this.item, required this.race});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.getRarityColor(item.rarity.name);

    // Preview : la plupart des cosmétiques → aperçu chat en direct
    final slot = item.cosmeticSlot;
    const previewableSlots = {
      'hat', 'outfit', 'pants', 'shoes', 'accessory', 'aura',
    };
    final showCatPreview = previewableSlots.contains(slot);
    final hatId = slot == 'hat' ? item.id : null;

    // Résoudre couleur depuis stats['colorValue'] selon le slot
    final colorVal = item.stats['colorValue'];
    final resolved = colorVal != null ? Color(colorVal | 0xFF000000) : null;
    final outfitColor    = slot == 'outfit'    ? resolved : null;
    final pantsColor     = slot == 'pants'     ? resolved : null;
    final shoesColor     = slot == 'shoes'     ? resolved : null;
    final accessoryColor = slot == 'accessory' ? resolved : null;
    final auraColor      = slot == 'aura'      ? resolved : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),

          // Aperçu chat
          if (showCatPreview) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.30),
                        blurRadius: 40,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
                CatWidget(
                  race: race,
                  equippedHat: hatId,
                  outfitColor: outfitColor,
                  pantsColor: pantsColor,
                  shoesColor: shoesColor,
                  accessoryColor: accessoryColor,
                  auraColor: auraColor,
                  size: 150,
                ),
              ],
            ),
          ] else ...[
            // Pour les autres slots, afficher un grand emoji
            Text(
              _slotEmoji(item.cosmeticSlot),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 8),
            Text(
              'Aperçu disponible\naprès équipement',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Nom + rareté
          Text(
            item.name,
            style: GoogleFonts.nunito(
              color: rarityColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          RarityBadge(rarity: item.rarity.name),
          const SizedBox(height: 10),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Bouton acheter
          Consumer2<PlayerViewModel, InventoryViewModel>(
            builder: (ctx, player, inventory, _) {
              final canAfford =
                  (player.stats?.gold ?? 0) >= item.goldValue;
              final hasSpace = !inventory.isFull;

              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: canAfford && hasSpace
                        ? AppColors.primaryViolet
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canAfford && hasSpace
                      ? () {
                          _executeBuyWithGold(ctx, item, AppColors.mintMagic.withValues(alpha: 0.9));
                          Navigator.pop(ctx);
                        }
                      : null,
                  icon: const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 18),
                  label: Text(
                    '${item.goldValue} pièces d\'or',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _slotEmoji(String? slot) => switch (slot) {
        'outfit'    => '👘',
        'pants'     => '👖',
        'shoes'     => '👟',
        'aura'      => '🌟',
        'accessory' => '💎',
        'title'     => '🏆',
        _           => '✨',
      };
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
      padding: const EdgeInsets.all(12),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rarityColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _rarityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: _rarityColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.nunito(
                    color: _rarityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.nunito(
                      color: AppColors.textMuted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RarityBadge(rarity: item.rarity.name, compact: true),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond,
                      color: AppColors.crystalBlue, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${item.crystalValue}',
                    style: GoogleFonts.nunito(
                      color: AppColors.crystalBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Consumer2<PlayerViewModel, InventoryViewModel>(
                builder: (ctx, player, inventory, _) {
                  final canAfford =
                      (player.stats?.crystals ?? 0) >= item.crystalValue;
                  final hasSpace = !inventory.isFull;
                  return GestureDetector(
                    onTap: canAfford && hasSpace
                        ? () => _buy(ctx, player, inventory)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: canAfford && hasSpace
                            ? AppColors.crystalBlue.withValues(alpha: 0.15)
                            : AppColors.textMuted.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canAfford && hasSpace
                              ? AppColors.crystalBlue
                              : AppColors.inputBorder,
                        ),
                      ),
                      child: Text(
                        'Acheter',
                        style: GoogleFonts.nunito(
                          color: canAfford && hasSpace
                              ? AppColors.crystalBlue
                              : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _buy(BuildContext context, PlayerViewModel player,
      InventoryViewModel inventory) {
    if (item.crystalValue <= 0) return;
    if ((player.stats?.crystals ?? 0) < item.crystalValue) return;
    if (inventory.isFull) return;
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId ?? '';
    player.spendCrystals(userId, item.crystalValue);
    final newItem = item.copyWith(id: const Uuid().v4());
    inventory.addItem(newItem);
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
        if (inventory.items.isEmpty) {
          return Center(
            child: Text(
              'Ton inventaire est vide.',
              style: GoogleFonts.nunito(color: AppColors.textMuted),
            ),
          );
        }
        if (sellable.isEmpty) {
          return Center(
            child: Text(
              'Tous tes objets sont verrouillés.',
              style: GoogleFonts.nunito(color: AppColors.textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sellable.length,
          itemBuilder: (context, i) {
            final item = sellable[i];
            final sellPrice = (item.goldValue * 0.5).round();
            final color = AppColors.getRarityColor(item.rarity.name);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                        color: color,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              color: color, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Revente : $sellPrice pièces (50%)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _confirmSell(context, inventory, item, sellPrice),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          AppColors.primaryViolet.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.monetization_on,
                        color: AppColors.gold, size: 14),
                    label: Text(
                      '+${_compactNumber(sellPrice)}',
                      style: const TextStyle(
                          color: AppColors.primaryVioletLight, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSell(BuildContext context, InventoryViewModel inventory,
      Item item, int sellPrice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: Text(
          'Vendre',
          style: GoogleFonts.nunito(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Vendre ${item.name} pour $sellPrice pièces ?',
          style: GoogleFonts.nunito(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.nunito(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Vendre',
              style: GoogleFonts.nunito(
                color: AppColors.primaryVioletLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      _sell(context, inventory, item, sellPrice);
    }
  }

  void _sell(BuildContext context, InventoryViewModel inventory, Item item,
      int sellPrice) {
    final player = context.read<PlayerViewModel>();
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId ?? '';
    inventory.removeItem(item.id, force: true);
    player.addGold(userId, sellPrice);
    AppNotification.show(
      context,
      message: '${item.name} vendu pour $sellPrice pièces.',
      backgroundColor: AppColors.gold.withValues(alpha: 0.85),
    );
  }
}
