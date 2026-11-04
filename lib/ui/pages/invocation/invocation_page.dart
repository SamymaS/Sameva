import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/audio/sons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cat_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/item_factory.dart';
import '../../../data/repositories/game_api.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/rarity_badge.dart';
import 'portail_repos.dart';
import 'sequence_invocation.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Page invocation gacha (Sprint 1) : payée en Sceaux (10, ou 90 pour 10),
/// une invocation gratuite par jour, tirage et pity calculés par le serveur.
class InvocationTab extends StatefulWidget {
  const InvocationTab({super.key});

  @override
  State<InvocationTab> createState() => _InvocationTabState();
}

class _InvocationTabState extends State<InvocationTab>
    with TickerProviderStateMixin {
  /// Horloge des animations du portail au repos (boucle de 4,8 s).
  late AnimationController _pulseController;

  bool _isRevealing = false;
  final List<Item> _history = [];

  /// Garanties anti-malchance renvoyées par le serveur après un tirage.
  int? _epicIn;
  int? _legendaryIn;

  /// Timer périodique qui rafraîchit l'affichage du compte à rebours du
  /// tirage gratuit. S'auto-annule dès que le tirage redevient disponible.
  Timer? _countdownTimer;

  static const _historyKey = 'gacha_history';
  static const _historyMax = 20;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();

    _loadHistory();
    _startCountdownIfNeeded();
    // La disponibilité du tirage gratuit vient du serveur : on relance le
    // compte à rebours dès que l'état joueur est rafraîchi.
    _playerVm = context.read<PlayerViewModel>()..addListener(_onPlayerChanged);
  }

  PlayerViewModel? _playerVm;

  void _onPlayerChanged() {
    if (!mounted) return;
    if (!(_countdownTimer?.isActive ?? false)) _startCountdownIfNeeded();
  }

  /// Démarre un Timer.periodic d'1 seconde pour mettre à jour l'affichage
  /// du compte à rebours du tirage gratuit. Annule le timer précédent avant
  /// d'en créer un nouveau. S'arrête dès que le tirage redevient disponible.
  void _startCountdownIfNeeded() {
    _countdownTimer?.cancel();
    if (_canUseFree) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_canUseFree) {
        t.cancel();
      }
      setState(() {}); // force le rebuild pour afficher le temps restant à jour
    });
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
      debugPrint('InvocationTab: erreur chargement historique: $e');
    }
  }

  void _persistHistory() {
    try {
      Hive.box('settings').put(
        _historyKey,
        _history.take(_historyMax).map((i) => i.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('InvocationTab: erreur persist historique: $e');
    }
  }

  /// Coûts en Sceaux, alignés sur `game_config.gacha.banners`.
  static const _sealCost = 10;
  static const _sealCostX10 = 90;

  /// Remboursement indicatif d'un doublon cosmétique, selon la rareté.
  /// Le serveur plafonne (TRANSITOIRE jusqu'au Sprint 3, Poussière d'étoile).
  int _dupeRefundBase(Item item, InventoryViewModel inv) {
    if (item.type != ItemType.cosmetic) return 0;
    final exists = inv.items.any((i) =>
        i.type == ItemType.cosmetic && i.name == item.name && i.id != item.id);
    if (!exists) return 0;
    return switch (item.rarity) {
      QuestRarity.common => 2,
      QuestRarity.uncommon => 5,
      QuestRarity.rare => 10,
      QuestRarity.epic => 25,
      QuestRarity.legendary => 50,
      QuestRarity.mythic => 100,
    };
  }

  /// Demande le remboursement des doublons ; renvoie le montant accordé.
  Future<int> _claimDupeRefund(PlayerViewModel player, int amount) async {
    if (amount <= 0) return 0;
    try {
      return (await player.claimTransitionalReward('doublon', amount)).grantedInt;
    } on GameApiException catch (e) {
      debugPrint('InvocationTab: remboursement doublon refusé: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    _playerVm?.removeListener(_onPlayerChanged);
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Box get _settings => Hive.box('settings');

  /// Disponibilité du tirage gratuit, lue dans l'état serveur (un par jour
  /// local du joueur).
  bool get _canUseFree =>
      context.read<PlayerViewModel>().gacha['objets']?.freeAvailable ?? true;

  /// Temps restant avant minuit (renouvellement du tirage gratuit).
  Duration get _freeTimeRemaining {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  void _showApiError(GameApiException e) {
    AppNotification.show(context, message: e.userMessage, backgroundColor: AppColors.error);
  }

  Future<void> _pull({required bool isFree}) async {
    if (_isRevealing) return;

    final player = context.read<PlayerViewModel>();
    final inventory = context.read<InventoryViewModel>();

    if (!isFree && (player.stats?.seals ?? 0) < _sealCost) {
      AppNotification.show(
        context,
        message: 'Pas assez de Sceaux ! ($_sealCost requis)',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() => _isRevealing = true);

    final InvokeResult result;
    try {
      result = await player.invoke('objets', useFree: isFree);
    } on GameApiException catch (e) {
      if (mounted) {
        setState(() => _isRevealing = false);
        _showApiError(e);
      }
      return;
    }
    if (isFree) _startCountdownIfNeeded();

    // La rareté vient du serveur ; l'objet concret est encore généré
    // localement (TRANSITOIRE jusqu'au Sprint 3).
    final item = ItemFactory.generateRandomItem(result.results.first.rarity);
    final refund = await _claimDupeRefund(player, _dupeRefundBase(item, inventory));
    if (refund <= 0) inventory.addItem(item);

    // Séquence plein écran (charge du portail puis révélation) ; le son de
    // rareté est joué par la séquence au moment de la révélation.
    if (mounted) {
      await SequenceInvocation.afficher(
        context,
        objets: [item],
        remboursement: refund,
        epiqueDans: result.epicGuaranteedIn,
        legendaireDans: result.legendaryGuaranteedIn,
      );
    }

    if (mounted) {
      setState(() {
        _epicIn = result.epicGuaranteedIn;
        _legendaryIn = result.legendaryGuaranteedIn;
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

    final player = context.read<PlayerViewModel>();
    final inventory = context.read<InventoryViewModel>();

    if ((player.stats?.seals ?? 0) < _sealCostX10) {
      AppNotification.show(
        context,
        message: 'Pas assez de Sceaux ! ($_sealCostX10 requis)',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() => _isRevealing = true);
    final InvokeResult result;
    try {
      result = await player.invoke('objets', count: 10);
    } on GameApiException catch (e) {
      if (mounted) {
        setState(() => _isRevealing = false);
        _showApiError(e);
      }
      return;
    }

    final results = <Item>[];
    final dupes = <Item>[];
    int dupeTotal = 0;
    for (final pull in result.results) {
      final item = ItemFactory.generateRandomItem(pull.rarity);
      results.add(item);
      final base = _dupeRefundBase(item, inventory);
      if (base > 0) {
        dupes.add(item);
        dupeTotal += base;
      } else {
        inventory.addItem(item);
      }
    }
    // Doublons : convertis seulement si le serveur accorde un remboursement.
    final totalRefund = await _claimDupeRefund(player, dupeTotal);
    if (totalRefund <= 0) {
      for (final item in dupes) {
        inventory.addItem(item);
      }
    }

    if (mounted && results.isNotEmpty) {
      await SequenceInvocation.afficher(
        context,
        objets: results,
        remboursement: totalRefund,
        epiqueDans: result.epicGuaranteedIn,
        legendaireDans: result.legendaryGuaranteedIn,
      );
    }

    if (mounted) {
      setState(() {
        _epicIn = result.epicGuaranteedIn;
        _legendaryIn = result.legendaryGuaranteedIn;
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

  @override
  Widget build(BuildContext context) {
    // Pas de Scaffold/AppBar : ce widget est embarqué comme onglet du Portail,
    // qui fournit l'AppBar partagée (or + cristaux). On garde le TabBar interne
    // Objets/Chats via un DefaultTabController dédié.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: PixelCouleurs.nuit,
            child: TabBar(
              labelColor: PixelCouleurs.texte,
              unselectedLabelColor: PixelCouleurs.texteDoux,
              indicator: const BoxDecoration(
                color: PixelCouleurs.violet,
                border: Border(bottom: BorderSide(color: PixelCouleurs.violetClair, width: 3)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: PixelCouleurs.trait,
              labelStyle: PixelTextes.corps(16, poids: FontWeight.w700),
              unselectedLabelStyle: PixelTextes.corps(16, poids: FontWeight.w600),
              tabs: const [
                Tab(text: 'Objets'),
                Tab(text: 'Chats'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // ── Onglet Objets (gacha classique) ──
                _ongletObjets(),

                // ── Onglet Chats (gacha de compagnons) ──
                const _CatInvocationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seuils de garantie affichés. Le serveur reste seul juge (pity dans
  /// `game_config.gacha`) ; après un tirage, ses compteurs exacts priment.
  static const _seuilEpique = 20;
  static const _seuilLegendaire = 80;

  /// Onglet Objets en pixel art (maquette « Portail (repos) »).
  Widget _ongletObjets() {
    return Consumer<PlayerViewModel>(
      builder: (context, player, _) {
        final banniere = player.gacha['objets'];
        final seals = player.stats?.seals ?? 0;
        final gratuit = _canUseFree;
        final epique = _epicIn != null ? _seuilEpique - _epicIn! : (banniere?.sinceEpic ?? 0);
        final legendaire =
            _legendaryIn != null ? _seuilLegendaire - _legendaryIn! : (banniere?.sinceLegendary ?? 0);
        return ColoredBox(
          color: PixelCouleurs.nuit,
          child: Stack(
            children: [
              const Positioned.fill(child: PixelFondPoints()),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 300, child: Center(child: PortailRepos(horloge: _pulseController))),
                    PixelCadre(
                      child: Column(
                        children: [
                          JaugeGarantie(
                              libelle: 'Épique garanti', actuel: epique, seuil: _seuilEpique, couleur: AppColors.rarityEpic),
                          const SizedBox(height: 12),
                          JaugeGarantie(
                              libelle: 'Légendaire garanti',
                              actuel: legendaire,
                              seuil: _seuilLegendaire,
                              couleur: PixelCouleurs.or),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PixelBouton(
                      libelle: gratuit ? 'Invoquer · Gratuit' : 'Invoquer · $_sealCost Sceaux',
                      onPressed: _isRevealing || (!gratuit && seals < _sealCost)
                          ? null
                          : () => _pull(isFree: gratuit),
                    ),
                    if (!gratuit) ...[
                      const SizedBox(height: 6),
                      Text('Prochain tirage gratuit dans ${_formatTimer(_freeTimeRemaining)}',
                          textAlign: TextAlign.center,
                          style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                    ],
                    const SizedBox(height: 12),
                    PixelBouton(
                      libelle: '10× Invoquer · $_sealCostX10 Sceaux',
                      principal: false,
                      onPressed: _isRevealing || seals < _sealCostX10 ? null : _pullMulti,
                    ),
                    const SizedBox(height: 24),
                    if (_history.isNotEmpty) ...[
                      DerniersTirages(objets: _history.take(10).toList()),
                      const SizedBox(height: 24),
                    ],
                    const _DropRatesSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  static const _catCost = 10; // Sceaux par invocation de chat (game_config)

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
    final catProvider = context.read<CatViewModel>();

    if ((player.stats?.seals ?? 0) < _catCost) {
      AppNotification.show(
        context,
        message: 'Pas assez de Sceaux ! ($_catCost requis)',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() => _isRevealing = true);
    _revealCtrl.reset();

    // Tirage et pity côté serveur (bannière « compagnons »).
    final InvokeResult result;
    try {
      result = await player.invoke('compagnons');
    } on GameApiException catch (e) {
      if (mounted) {
        setState(() => _isRevealing = false);
        AppNotification.show(context, message: e.userMessage, backgroundColor: AppColors.error);
      }
      return;
    }

    unawaited(Sons.jouer(Sons.invocationPour(result.results.first.rarity.name)));
    final newCat = await catProvider.addRolledCat(result.results.first.rarity);
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
                                CatWidget(
                                    race: cat.race, size: 100, mood: 'excited'),
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
                                const Text('🐱',
                                    style: TextStyle(fontSize: 52)),
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
              final seals = player.stats?.seals ?? 0;
              final canAfford = seals >= _catCost;
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
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    'Invoquer un chat ($_catCost Sceaux)',
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
                    const Icon(Icons.pets,
                        color: AppColors.primaryVioletLight, size: 18),
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
                  (
                    'Cosmos (spécial)',
                    'Légendaire+',
                    AppColors.rarityLegendary
                  ),
                ].map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: r.$3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(r.$1,
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
    // Taux publiés, identiques à game_config.gacha.rates (bannière standard).
    (rarity: 'Épique', rate: 4.0, color: AppColors.rarityEpic),
    (rarity: 'Légendaire', rate: 1.0, color: AppColors.rarityLegendary),
    (rarity: 'Mythique', rate: 0.0, color: AppColors.rarityMythic),
  ];

  /// « 60 % », « 0,5 % » : virgule décimale et espace insécable à la française
  /// (sur mobile, un double s'affichait « 60.0% »).
  static String _taux(double t) =>
      '${t == t.roundToDouble() ? t.toInt() : t.toString().replaceAll('.', ',')}\u00A0%';

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Taux d\'invocation', style: PixelTextes.chiffres(11, PixelCouleurs.texte)),
          const SizedBox(height: 12),
          for (final r in _rates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 116,
                    child: Text(r.rarity, style: PixelTextes.corps(15, couleur: r.color, poids: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SizedBox(
                      height: 8,
                      child: ColoredBox(
                        color: PixelCouleurs.violetSombre,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: r.rate / 100,
                          child: ColoredBox(color: r.color),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(_taux(r.rate),
                        textAlign: TextAlign.right, style: PixelTextes.chiffres(10, r.color)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
