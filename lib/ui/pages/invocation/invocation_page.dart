import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cat_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/rarity_badge.dart';

/// Page invocation gacha : 50 cristaux ou 1 gratuit/24h.
class InvocationPage extends StatefulWidget {
  const InvocationPage({super.key});

  @override
  State<InvocationPage> createState() => _InvocationPageState();
}

class _InvocationPageState extends State<InvocationPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late Animation<double> _pulseAnim;
  late Animation<double> _revealAnim;

  Item? _lastItem;
  bool _isRevealing = false;
  final List<Item> _history = [];
  List<Item>? _multiPullResults;
  int _lastDupeRefund = 0;

  static const _historyKey = 'gacha_history';
  static const _historyMax = 20;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _revealAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _revealController, curve: Curves.easeInOut));

    _loadHistory();
  }

  void _loadHistory() {
    try {
      final raw = Hive.box('settings').get(_historyKey);
      if (raw is List) {
        final loaded = raw
            .whereType<Map>()
            .map((m) => Item.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        if (mounted) {
          setState(() {
            _history
              ..clear()
              ..addAll(loaded);
          });
        } else {
          _history.addAll(loaded);
        }
      }
    } catch (e) {
      debugPrint('InvocationPage: erreur chargement historique: $e');
    }
  }

  void _persistHistory() {
    try {
      Hive.box('settings').put(
        _historyKey,
        _history.take(_historyMax).map((i) => i.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('InvocationPage: erreur persist historique: $e');
    }
  }

  static const _refundDailyCap = 200;
  static const _refundDateKey = 'dupe_refund_date';
  static const _refundAmountKey = 'dupe_refund_today';

  /// Récupère le total déjà refund aujourd'hui (reset à minuit).
  int _todayRefundTotal() {
    try {
      final box = Hive.box('settings');
      final dateStr = box.get(_refundDateKey) as String?;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (dateStr != today) return 0;
      return box.get(_refundAmountKey, defaultValue: 0) as int;
    } catch (e) {
      debugPrint('refund cap read error: $e');
      return 0;
    }
  }

  Future<void> _addRefundToToday(int amount) async {
    try {
      final box = Hive.box('settings');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final current = _todayRefundTotal();
      await box.put(_refundDateKey, today);
      await box.put(_refundAmountKey, current + amount);
    } catch (e) {
      debugPrint('refund cap write error: $e');
    }
  }

  /// Détecte un cosmétique déjà possédé. Retourne le refund cristaux selon rareté.
  /// Retourne 0 si pas un doublon OU si cap journalier atteint.
  /// Items verrouillés non comptés comme doublons (utilisateur garde le dupe).
  int _checkDupeRefund(Item item, InventoryViewModel inv) {
    if (item.type != ItemType.cosmetic) return 0;
    final exists = inv.items.any((i) =>
        i.type == ItemType.cosmetic && i.name == item.name && i.id != item.id);
    if (!exists) return 0;
    final base = switch (item.rarity) {
      QuestRarity.common    => 2,
      QuestRarity.uncommon  => 5,
      QuestRarity.rare      => 10,
      QuestRarity.epic      => 25,
      QuestRarity.legendary => 50,
      QuestRarity.mythic    => 100,
    };
    final usedToday = _todayRefundTotal();
    final remaining = (_refundDailyCap - usedToday).clamp(0, _refundDailyCap);
    return base.clamp(0, remaining);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Box get _settings => Hive.box('settings');

  bool get _canUseFree {
    final lastStr = _settings.get('lastFreePullAt') as String?;
    if (lastStr == null) return true;
    final last = DateTime.parse(lastStr);
    return DateTime.now().difference(last).inHours >= 24;
  }

  Duration get _freeTimeRemaining {
    final lastStr = _settings.get('lastFreePullAt') as String?;
    if (lastStr == null) return Duration.zero;
    final last = DateTime.parse(lastStr);
    final elapsed = DateTime.now().difference(last);
    final remaining = const Duration(hours: 24) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _pull({required bool isFree}) async {
    if (_isRevealing) return;

    final player = context.read<PlayerViewModel>();
    final inventory = context.read<InventoryViewModel>();
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId ?? '';

    if (!isFree) {
      if ((player.stats?.crystals ?? 0) < 50) {
        AppNotification.show(
          context,
          message: 'Pas assez de cristaux ! (50 requis)',
          backgroundColor: AppColors.error,
        );
        return;
      }
      await player.spendCrystals(userId, 50);
    } else {
      await _settings.put('lastFreePullAt', DateTime.now().toIso8601String());
    }

    setState(() => _isRevealing = true);
    _revealController.reset();

    final pityCount = player.stats?.pityCount ?? 0;
    final pullResult = ItemFactory.rollGachaRarityWithPity(pityCount);
    final item = ItemFactory.generateRandomItem(pullResult.rarity);

    // Mise à jour du compteur pity (centralisé via pityTriggered)
    if (pullResult.pityTriggered) {
      await player.resetPity(userId);
    } else {
      await player.incrementPity(userId);
    }

    // Doublon cosmétique → refund cristaux au lieu d'ajouter à l'inventaire
    final refund = _checkDupeRefund(item, inventory);
    if (refund > 0) {
      await player.addCrystals(userId, refund);
      await _addRefundToToday(refund);
    } else {
      inventory.addItem(item);
    }

    await _revealController.forward();

    if (mounted) {
      setState(() {
        _lastItem = item;
        _lastDupeRefund = refund;
        _isRevealing = false;
        _history.insert(0, item);
        if (_history.length > _historyMax) _history.removeLast();
      });
      _persistHistory();
    }

    await _settings.put('gacha_first_done', true);
  }

  Future<void> _pullMulti() async {
    if (_isRevealing) return;
    const count = 10;
    const cost = 450;

    final player = context.read<PlayerViewModel>();
    final inventory = context.read<InventoryViewModel>();
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId ?? '';

    if ((player.stats?.crystals ?? 0) < cost) {
      if (!mounted) return;
      AppNotification.show(
        context,
        message: 'Pas assez de cristaux ! (450 requis)',
        backgroundColor: AppColors.error,
      );
      return;
    }
    await player.spendCrystals(userId, cost);

    setState(() => _isRevealing = true);
    final results = <Item>[];
    int pityCount = player.stats?.pityCount ?? 0;
    int totalRefund = 0;

    for (int i = 0; i < count; i++) {
      final pullResult = ItemFactory.rollGachaRarityWithPity(pityCount);
      final item = ItemFactory.generateRandomItem(pullResult.rarity);
      results.add(item);

      // Doublon cosmétique → refund au lieu d'ajout
      final refund = _checkDupeRefund(item, inventory);
      if (refund > 0) {
        totalRefund += refund;
      } else {
        inventory.addItem(item);
      }

      pityCount = pullResult.pityTriggered ? 0 : pityCount + 1;
    }

    // Sync pity final en une seule écriture
    await player.setPity(userId, pityCount);

    if (totalRefund > 0) {
      await player.addCrystals(userId, totalRefund);
      await _addRefundToToday(totalRefund);
    }

    if (mounted) {
      setState(() {
        _multiPullResults = results;
        _lastItem = results.last;
        _lastDupeRefund = totalRefund;
        _isRevealing = false;
        for (final item in results) {
          _history.insert(0, item);
        }
        if (_history.length > _historyMax) _history.length = _historyMax;
      });
      _persistHistory();
    }
    await _settings.put('gacha_first_done', true);
    await _settings.put('gacha_multi_done', true);
  }

  Color _rarityColor(QuestRarity r) => AppColors.getRarityColor(r.name);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightCosmos,
        title: const Text(
          'Invocation',
          style: TextStyle(
              color: AppColors.primaryVioletLight, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<PlayerViewModel>(
            builder: (_, player, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.diamond,
                      color: AppColors.primaryViolet, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${player.stats?.crystals ?? 0}',
                    style: const TextStyle(
                        color: AppColors.primaryVioletLight,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          labelColor: AppColors.primaryVioletLight,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryVioletLight,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '⚔️  Objets'),
            Tab(text: '🐱  Chats'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          // ── Onglet Objets (gacha classique) ──
          SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Carte centrale
            SizedBox(
              height: 260,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnim, _revealAnim]),
                  builder: (_, __) {
                    final pulseScale = _isRevealing ? 1.0 : _pulseAnim.value;
                    final item = _lastItem;

                    return Transform.scale(
                      scale: pulseScale * (_isRevealing ? _revealAnim.value : 1.0),
                      child: Container(
                        width: 160,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item != null
                                ? [
                                    _rarityColor(item.rarity).withValues(alpha: 0.3),
                                    AppColors.backgroundDeepViolet,
                                  ]
                                : [
                                    AppColors.backgroundDeepViolet,
                                    AppColors.primaryViolet.withValues(alpha: 0.3),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item != null
                                ? _rarityColor(item.rarity)
                                : AppColors.primaryViolet,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (item != null
                                      ? _rarityColor(item.rarity)
                                      : AppColors.primaryViolet)
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: item != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.getIcon(),
                                      color: _rarityColor(item.rarity),
                                      size: 48),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      item.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _rarityColor(item.rarity),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.rarity.name.toUpperCase(),
                                    style: TextStyle(
                                      color: _rarityColor(item.rarity)
                                          .withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_lastDupeRefund > 0) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.crystalBlue
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.crystalBlue
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        'Doublon · +$_lastDupeRefund 💎',
                                        style: const TextStyle(
                                          color: AppColors.crystalBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_fix_high,
                                      color: AppColors.primaryVioletLight,
                                      size: 48),
                                  SizedBox(height: 12),
                                  Text(
                                    'Invoquez un\nitem mystique',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Boutons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Consumer<PlayerViewModel>(
                        builder: (ctx, player, _) {
                          final crystals = player.stats?.crystals ?? 0;
                          return FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryViolet,
                              disabledBackgroundColor:
                                  AppColors.primaryViolet.withValues(alpha: 0.3),
                            ),
                            onPressed: (!_isRevealing && crystals >= 50)
                                ? () => _pull(isFree: false)
                                : null,
                            icon: const Icon(Icons.diamond, size: 16),
                            label: const Text('Invoquer (50 💎)'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (ctx, setLocalState) {
                          return FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _canUseFree
                                  ? AppColors.gold
                                  : AppColors.gold.withValues(alpha: 0.3),
                            ),
                            onPressed: (!_isRevealing && _canUseFree)
                                ? () {
                                    _pull(isFree: true);
                                    setLocalState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.star, size: 16,
                                color: AppColors.backgroundNightCosmos),
                            label: _canUseFree
                                ? const Text('Gratuit',
                                    style: TextStyle(
                                        color: AppColors.backgroundNightCosmos))
                                : Text(
                                    _formatTimer(_freeTimeRemaining),
                                    style: const TextStyle(
                                        color: AppColors.backgroundNightCosmos,
                                        fontSize: 11),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<PlayerViewModel>(
                  builder: (ctx, player, _) {
                    final crystals = player.stats?.crystals ?? 0;
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: (!_isRevealing && crystals >= 450)
                                ? AppColors.rarityEpic
                                : AppColors.rarityEpic.withValues(alpha: 0.3),
                          ),
                          foregroundColor: AppColors.rarityEpic,
                        ),
                        onPressed: (!_isRevealing && crystals >= 450)
                            ? () {
                                setState(() => _multiPullResults = null);
                                _pullMulti();
                              }
                            : null,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('10× Invoquer (450 💎)'),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Résultats 10× pull
            if (_multiPullResults != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Résultats',
                    style: TextStyle(
                        color: AppColors.primaryVioletLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _multiPullResults = null),
                    child: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.8,
                ),
                itemCount: _multiPullResults!.length,
                itemBuilder: (_, i) {
                  final item = _multiPullResults![i];
                  final color = _rarityColor(item.rarity);
                  return Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.getIcon(), color: color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: color, fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),

            // Compteur pity
            Consumer<PlayerViewModel>(
              builder: (_, player, __) {
                final pity = player.stats?.pityCount ?? 0;
                final epicLeft = (20 - pity).clamp(0, 20);
                final legLeft = (80 - pity).clamp(0, 80);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDarkPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryViolet.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: AppColors.primaryVioletLight, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Garanties Pity',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            epicLeft == 0
                                ? 'Épique garanti au prochain pull !'
                                : '$epicLeft pulls avant épique',
                            style: TextStyle(
                              color: epicLeft == 0
                                  ? AppColors.rarityEpic
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: epicLeft == 0
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _PityBar(
                        label: 'Épique garanti',
                        current: pity,
                        max: 20,
                        color: AppColors.rarityEpic,
                      ),
                      const SizedBox(height: 8),
                      _PityBar(
                        label: 'Légendaire garanti',
                        current: pity,
                        max: 80,
                        color: AppColors.rarityLegendary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        legLeft == 0
                            ? '★ Légendaire garanti au prochain pull !'
                            : '$legLeft pulls avant légendaire garanti',
                        style: TextStyle(
                          color: legLeft == 0
                              ? AppColors.rarityLegendary
                              : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: legLeft == 0
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Taux de drop
            const _DropRatesSection(),
            // Historique
            if (_history.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Derniers pulls',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _history
                    .map((item) => Chip(
                          avatar: Icon(item.getIcon(),
                              color: _rarityColor(item.rarity), size: 14),
                          label: Text(
                            item.name,
                            style: TextStyle(
                                color: _rarityColor(item.rarity), fontSize: 11),
                          ),
                          backgroundColor:
                              _rarityColor(item.rarity).withValues(alpha: 0.15),
                          side: BorderSide(
                              color: _rarityColor(item.rarity).withValues(alpha: 0.5)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),

          // ── Onglet Chats (gacha de compagnons) ──
          const _CatInvocationTab(),
        ],
      ),
    ));
  }

  String _formatTimer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}


// ─────────────────────────────────────────────────────────────────
// Barre pity
// ─────────────────────────────────────────────────────────────────

class _PityBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _PityBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (current / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.backgroundNightCosmos,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$max',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section taux de drop
// ─────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────
// Onglet gacha de chats
// ─────────────────────────────────────────────────────────────────

class _CatInvocationTab extends StatefulWidget {
  const _CatInvocationTab();

  @override
  State<_CatInvocationTab> createState() => _CatInvocationTabState();
}

class _CatInvocationTabState extends State<_CatInvocationTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;
  bool _isRevealing = false;
  CatStats? _lastCat;

  static const _catCost = 100; // cristaux par invocation de chat

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _revealAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _pullCat() async {
    if (_isRevealing) return;
    final player = context.read<PlayerViewModel>();
    final auth = context.read<AuthViewModel>();
    final catProvider = context.read<CatViewModel>();
    final userId = auth.userId ?? '';

    if ((player.stats?.crystals ?? 0) < _catCost) {
      AppNotification.show(
        context,
        message: 'Pas assez de cristaux ! (100 💎 requis)',
        backgroundColor: AppColors.error,
      );
      return;
    }

    await player.spendCrystals(userId, _catCost);
    setState(() => _isRevealing = true);
    _revealCtrl.reset();

    final catPityCount = player.stats?.catPityCount ?? 0;
    final pullResult = ItemFactory.rollGachaRarityWithPity(catPityCount);

    if (pullResult.pityTriggered) {
      await player.resetCatPity(userId);
    } else {
      await player.incrementCatPity(userId);
    }

    final newCat = await catProvider.addRolledCat(pullResult.rarity);
    await _revealCtrl.forward();

    if (mounted) {
      setState(() {
        _lastCat = newCat;
        _isRevealing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _lastCat;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Carte résultat
          SizedBox(
            height: 260,
            child: Center(
              child: AnimatedBuilder(
                animation: _revealAnim,
                builder: (_, __) {
                  final scale = _isRevealing ? _revealAnim.value : 1.0;
                  final rarityColor = cat != null
                      ? AppColors.getRarityColor(cat.rarity)
                      : AppColors.primaryViolet;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rarityColor.withValues(alpha: 0.25),
                            AppColors.backgroundDeepViolet,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rarityColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: rarityColor.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: cat != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CatWidget(race: cat.race, size: 100, mood: 'excited'),
                                const SizedBox(height: 10),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.nunito(
                                    color: rarityColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RarityBadge(rarity: cat.rarity, compact: true),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🐱', style: TextStyle(fontSize: 52)),
                                const SizedBox(height: 12),
                                Text(
                                  'Invoque un\nchat compagnon',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton invocation
          Consumer<PlayerViewModel>(
            builder: (_, player, __) {
              final crystals = player.stats?.crystals ?? 0;
              final canAfford = crystals >= _catCost;
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: canAfford
                        ? AppColors.primaryViolet
                        : AppColors.primaryViolet.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (!_isRevealing && canAfford) ? _pullCat : null,
                  icon: const Icon(Icons.diamond, size: 18),
                  label: Text(
                    'Invoquer un chat (100 💎)',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Info collection
          Consumer<CatViewModel>(
            builder: (_, catProv, __) {
              final total = catProv.cats.length;
              if (total == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDarkPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryViolet.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets, color: AppColors.primaryVioletLight, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Tu possèdes $total chat${total > 1 ? "s" : ""} compagnon${total > 1 ? "s" : ""}',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Taux d'invocation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryViolet.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pets_outlined,
                        color: AppColors.primaryVioletLight, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Races disponibles',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  ('Michi · Neige', 'Commun', AppColors.rarityCommon),
                  ('Braise · Lune', 'Rare', AppColors.rarityRare),
                  ('Cosmos · Sakura', 'Épique', AppColors.rarityEpic),
                  ('Cosmos (spécial)', 'Légendaire+', AppColors.rarityLegendary),
                ].map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: r.$3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.$1,
                              style: TextStyle(color: r.$3, fontSize: 12))),
                          Text(r.$2,
                              style: TextStyle(
                                  color: r.$3,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section taux de drop
// ─────────────────────────────────────────────────────────────────

class _DropRatesSection extends StatelessWidget {
  const _DropRatesSection();

  static const _rates = [
    (rarity: 'Commune', rate: 60.0, color: AppColors.rarityCommon),
    (rarity: 'Peu commune', rate: 25.0, color: AppColors.rarityUncommon),
    (rarity: 'Rare', rate: 10.0, color: AppColors.rarityRare),
    (rarity: 'Épique', rate: 4.9, color: AppColors.rarityEpic),
    (rarity: 'Légendaire', rate: 0.9, color: AppColors.rarityLegendary),
    (rarity: 'Mythique', rate: 0.1, color: AppColors.rarityMythic),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryViolet.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart,
                  color: AppColors.primaryVioletLight, size: 16),
              SizedBox(width: 6),
              Text(
                'Taux d\'invocation',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._rates.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: Text(
                        r.rarity,
                        style: TextStyle(
                            color: r.color, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: r.rate / 100,
                          backgroundColor:
                              AppColors.backgroundNightCosmos,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(r.color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${r.rate}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: r.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
