import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

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

    final player = context.read<PlayerProvider>();
    final inventory = context.read<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? '';

    if (!isFree) {
      if ((player.stats?.crystals ?? 0) < 50) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pas assez de cristaux ! (50 requis)'),
          backgroundColor: AppColors.error,
        ));
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

    // Mise à jour du compteur pity
    if (pullResult.pityTriggered ||
        pullResult.rarity == QuestRarity.epic ||
        pullResult.rarity == QuestRarity.legendary ||
        pullResult.rarity == QuestRarity.mythic) {
      await player.resetPity(userId);
    } else {
      await player.incrementPity(userId);
    }

    await _revealController.forward();

    if (mounted) {
      setState(() {
        _lastItem = item;
        _isRevealing = false;
        _history.insert(0, item);
        if (_history.length > 10) _history.removeLast();
      });
    }

    inventory.addItem(item);
  }

  Color _rarityColor(QuestRarity r) => AppColors.getRarityColor(r.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightCosmos,
        title: const Text(
          'Invocation',
          style: TextStyle(
              color: AppColors.primaryVioletLight, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<PlayerProvider>(
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
      ),
      body: SingleChildScrollView(
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
            Row(
              children: [
                Expanded(
                  child: Consumer<PlayerProvider>(
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
            const SizedBox(height: 32),

            // Compteur pity
            Consumer<PlayerProvider>(
              builder: (_, player, __) {
                final pity = player.stats?.pityCount ?? 0;
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
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppColors.primaryVioletLight, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Garanties Pity',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
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
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Taux de drop
            _DropRatesSection(),
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
    );
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
