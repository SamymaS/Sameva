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
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/rarity_badge.dart';
import '../invocation/invocation_page.dart';

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
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${player.stats?.gold ?? 0}',
                      style: GoogleFonts.nunito(
                        color: AppColors.gold,
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
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.primaryVioletLight,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryVioletLight,
              labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Boutique'),
                Tab(text: 'Vendre'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _ShopTab(),
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
// Filtres boutique — slots cosmétiques chat
// ─────────────────────────────────────────────────────────────────────────────

enum _CosmeticFilter { all, hat, outfit, pants, shoes, aura, accessory, title }

extension _CosmeticFilterExt on _CosmeticFilter {
  String get label => switch (this) {
        _CosmeticFilter.all       => 'Tout',
        _CosmeticFilter.hat       => 'Chapeau',
        _CosmeticFilter.outfit    => 'Tenue',
        _CosmeticFilter.pants     => 'Pantalon',
        _CosmeticFilter.shoes     => 'Chaussures',
        _CosmeticFilter.aura      => 'Aura',
        _CosmeticFilter.accessory => 'Accessoire',
        _CosmeticFilter.title     => 'Titre',
      };

  String? get slot => switch (this) {
        _CosmeticFilter.all       => null,
        _CosmeticFilter.hat       => 'hat',
        _CosmeticFilter.outfit    => 'outfit',
        _CosmeticFilter.pants     => 'pants',
        _CosmeticFilter.shoes     => 'shoes',
        _CosmeticFilter.aura      => 'aura',
        _CosmeticFilter.accessory => 'accessory',
        _CosmeticFilter.title     => 'title',
      };

  String get emoji => switch (this) {
        _CosmeticFilter.all       => '✨',
        _CosmeticFilter.hat       => '🎩',
        _CosmeticFilter.outfit    => '👘',
        _CosmeticFilter.pants     => '👖',
        _CosmeticFilter.shoes     => '👟',
        _CosmeticFilter.aura      => '🌟',
        _CosmeticFilter.accessory => '💎',
        _CosmeticFilter.title     => '🏆',
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
  // Catalogue filtré : cosmétiques uniquement
  final List<Item> _catalog = ItemFactory.getMarketCatalog()
      .where((i) => i.type == ItemType.cosmetic)
      .toList();

  _CosmeticFilter _filter = _CosmeticFilter.all;

  List<Item> get _filtered => _filter.slot == null
      ? _catalog
      : _catalog.where((i) => i.cosmeticSlot == _filter.slot).toList();

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
            children: _CosmeticFilter.values.map((f) {
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

        // Liste cosmétiques
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'Aucun cosmétique dans cette catégorie.',
                    style: GoogleFonts.nunito(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) =>
                      _CosmeticTile(item: _filtered[i]),
                ),
        ),
      ],
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
                          ? () => _buy(ctx, player, inventory)
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
                          'Acheter',
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

  void _buy(BuildContext context, PlayerViewModel player,
      InventoryViewModel inventory) {
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId ?? '';
    player.addGold(userId, -item.goldValue);
    final newItem = item.copyWith(id: const Uuid().v4());
    inventory.addItem(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} acheté !'),
        backgroundColor: AppColors.mintMagic.withValues(alpha: 0.9),
      ),
    );
  }

  void _showPreviewSheet(BuildContext context) {
    final cat = context.read<CatViewModel>().mainCat;
    final race = cat?.race ?? 'cosmos';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDarkPanel,
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

    // Preview : chapeau uniquement (autres slots → emoji + message)
    final showCatPreview = item.cosmeticSlot == 'hat';
    final hatId = showCatPreview ? item.id : null;

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
                CatWidget(race: race, equippedHat: hatId, size: 150),
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
                          final auth = ctx.read<AuthViewModel>();
                          final userId = auth.userId ?? '';
                          player.addGold(userId, -item.goldValue);
                          inventory.addItem(item.copyWith(id: const Uuid().v4()));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} acheté !'),
                              backgroundColor:
                                  AppColors.mintMagic.withValues(alpha: 0.9),
                            ),
                          );
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
// Onglet vente
// ─────────────────────────────────────────────────────────────────────────────

class _SellTab extends StatelessWidget {
  const _SellTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryViewModel>(
      builder: (context, inventory, _) {
        if (inventory.items.isEmpty) {
          return Center(
            child: Text(
              'Ton inventaire est vide.',
              style: GoogleFonts.nunito(color: AppColors.textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: inventory.items.length,
          itemBuilder: (context, i) {
            final item = inventory.items[i];
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
                        Text(item.name,
                            style: GoogleFonts.nunito(
                                color: color, fontWeight: FontWeight.w700)),
                        Text(
                          'Revente : $sellPrice pièces (50%)',
                          style: GoogleFonts.nunito(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          color: AppColors.gold, size: 14),
                      const SizedBox(width: 2),
                      Text('$sellPrice',
                          style: const TextStyle(color: AppColors.gold)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _sell(context, inventory, item, sellPrice),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Vendre',
                      style: TextStyle(
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

  void _sell(BuildContext context, InventoryViewModel inventory, Item item,
      int sellPrice) {
    final player = context.read<PlayerViewModel>();
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId ?? '';
    inventory.removeItem(item.id);
    player.addGold(userId, sellPrice);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} vendu pour $sellPrice pièces.')),
    );
  }
}
