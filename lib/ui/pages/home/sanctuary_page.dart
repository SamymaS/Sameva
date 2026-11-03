import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/audio/sons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../config/feature_flags.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/achievement_service.dart';
import '../../../domain/services/cat_mood_service.dart';
import '../../../domain/services/minigame_service.dart';
import '../../../presentation/use_cases/daily_reset_use_case.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/ai_validation_credits_service.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/pixel/pixel_ui.dart';
import '../../widgets/common/quest_detail_sheet.dart';

/// Page d'accueil : sanctuaire du joueur.
/// Le chat compagnon est en position hero centrale.
class SanctuaryPage extends StatefulWidget {
  const SanctuaryPage({super.key});

  @override
  State<SanctuaryPage> createState() => _SanctuaryPageState();
}

class _SanctuaryPageState extends State<SanctuaryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final questVM = context.read<QuestViewModel>();
    final playerVM = context.read<PlayerViewModel>();
    final creditsVM = context.read<AiValidationCreditsService>();
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) return;

    await questVM.loadQuests(userId);
    if (!mounted) return;
    await questVM.resetDailyQuests(userId);
    if (!mounted) return;
    await playerVM.loadPlayerStats(userId);
    if (!mounted) return;

    // Règles quotidiennes calculées par le serveur (claim_daily).
    final DailyResetResult result;
    try {
      result = await DailyResetUseCase(
        player: playerVM,
        quests: questVM,
      ).execute(userId);
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: dailyErrorMessage(e),
          backgroundColor: AppColors.error,
        );
      }
      return;
    }
    // L'énergie de l'Oracle a pu être rechargée : relecture du solde.
    await creditsVM.refresh();

    if (!mounted) return;

    if (result.penalties != null) {
      unawaited(Sons.jouer(Son.degats));
      AppNotification.show(
        context,
        message:
            '${result.penalties!.missedCount} quête${result.penalties!.missedCount > 1 ? 's' : ''} manquée${result.penalties!.missedCount > 1 ? 's' : ''} : ${result.penalties!.totalDamage} PV perdus',
        backgroundColor: AppColors.coralRare.withValues(alpha: 0.95),
      );
    }

    if (!mounted) return;
    if (result.weeklySummary != null) {
      final s = result.weeklySummary!;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => _WeeklySummarySheet(
          questsCompleted: s.questsCompleted,
          xpEarned: s.xpEarned,
          bossDefeated: false,
          streak: s.streak,
        ),
      );
    }

    if (!mounted) return;
    if (result.dailyReward != null) {
      final r = result.dailyReward!;
      await showDialog<void>(
        context: context,
        builder: (_) => _DailyRewardDialog(
          gold: r.gold,
          seals: r.seals,
          streak: r.streak,
        ),
      );
    }

    if (!mounted) return;
    if (result.streakLost) {
      AppNotification.show(
        context,
        message:
            'Ta flamme s\'est éteinte. Valide une quête pour la rallumer !',
        backgroundColor: AppColors.coralRare.withValues(alpha: 0.95),
      );
    }

    if (!mounted) return;
    await _checkAchievements();
  }

  Future<void> _checkAchievements() async {
    final playerVM = context.read<PlayerViewModel>();
    final questVM = context.read<QuestViewModel>();
    final stats = playerVM.stats;
    if (stats == null) return;

    final settings = Hive.box('settings');
    final bossDefeated =
        questVM.completedQuests.any((q) => q.category == 'boss');
    final minigamesPlayed = MinigameService.totalPlayed(settings);
    final hasGachaFirst =
        settings.get('gacha_first_done', defaultValue: false) as bool;
    final hasGachaMulti =
        settings.get('gacha_multi_done', defaultValue: false) as bool;

    final newlyUnlocked = await AchievementService.checkAll(
      level: stats.level,
      totalQuests: stats.totalQuestsCompleted,
      streak: stats.streak,
      gold: stats.gold,
      minigamesPlayed: minigamesPlayed,
      bossDefeated: bossDefeated,
      hasGachaFirst: hasGachaFirst,
      hasGachaMulti: hasGachaMulti,
    );

    if (!mounted) return;
    for (final id in newlyUnlocked) {
      final achievement = AchievementService.all.firstWhere((a) => a.id == id);
      AppNotification.show(
        context,
        message: 'Succès débloqué : ${achievement.name}',
        icon: achievement.icon,
        iconColor: achievement.color,
        backgroundColor: AppColors.backgroundDarkPanel,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      body: SafeArea(
        child: Consumer3<PlayerViewModel, QuestViewModel, CatViewModel>(
          builder: (context, player, quests, catProvider, _) {
            final stats = player.stats;
            if (stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final missedQuests = quests.getMissedQuests();
            final todayQuests = quests.activeQuests
                .where((q) {
                  if (q.deadline != null && now.isAfter(q.deadline!)) {
                    return false;
                  }
                  final created = DateTime(
                      q.createdAt.year, q.createdAt.month, q.createdAt.day);
                  return created == today ||
                      q.frequency == QuestFrequency.daily;
                })
                .take(3)
                .toList();

            final xpForNext = player.experienceForLevel(stats.level);
            final cat = catProvider.mainCat;
            final mood =
                CatMoodService.getMoodExpression(stats.moral, stats.streak);

            return RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primaryVioletLight,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ─────────────────────────────────────────────
                  SliverAppBar(
                    backgroundColor: PixelCouleurs.nuit,
                    surfaceTintColor: Colors.transparent,
                    floating: true,
                    elevation: 0,
                    title: Semantics(
                      header: true,
                      child: Text(
                        'Sanctuaire',
                        style: PixelTextes.chiffres(15, PixelCouleurs.texte).copyWith(
                          shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(3, 3))],
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Hero : chat compagnon ──────────────────────
                        if (cat != null) ...[
                          _CatHeroSection(
                            catName: cat.name,
                            race: cat.race,
                            equippedHat: cat.equippedHat,
                            mood: mood,
                            moral: stats.moral,
                            streak: stats.streak,
                            questCount: todayQuests.length,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Carte stats XP/HP ──────────────────────────
                        _StatsCard(stats: stats, xpForNext: xpForNext),
                        const SizedBox(height: 12),

                        // ── Barre moral ────────────────────────────────
                        _MoralBar(moral: stats.moral),
                        const SizedBox(height: 24),

                        // ── Boss hebdomadaire ──────────────────────────
                        ...() {
                          if (!FeatureFlags.showWeeklyBoss) return <Widget>[];
                          final boss = quests.activeQuests
                              .where((q) => q.category == 'boss')
                              .toList();
                          if (boss.isEmpty) return <Widget>[];
                          return [
                            _BossQuestCard(quest: boss.first),
                            const SizedBox(height: 20),
                          ];
                        }(),

                        // ── Quêtes en retard ───────────────────────────
                        if (missedQuests.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.coralRare, size: 16),
                              const SizedBox(width: 6),
                              Text('En retard', style: PixelTextes.chiffres(11, AppColors.coralRare)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...missedQuests
                              .map((q) => _MissedQuestTile(quest: q)),
                          const SizedBox(height: 20),
                        ],

                        // ── Quêtes du jour ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Semantics(
                              header: true,
                              child: Text("Aujourd'hui", style: PixelTextes.chiffres(12, PixelCouleurs.texte)),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.go(Routes.quetes),
                              style: TextButton.styleFrom(
                                foregroundColor: PixelCouleurs.violetClair,
                                minimumSize: const Size(48, 48),
                                textStyle: PixelTextes.corps(16, poids: FontWeight.w600),
                              ),
                              child: const Text('Voir tout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (quests.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (quests.error != null)
                          _ErrorCard(message: quests.error!)
                        else if (todayQuests.isEmpty)
                          _EmptyQuestCard()
                        else
                          ...todayQuests.map((q) => _QuestTile(quest: q)),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero chat
// ─────────────────────────────────────────────────────────────────────────────

/// Chat compagnon sur son socle, avec sa bulle (maquette « Accueil · Sanctuaire »).
class _CatHeroSection extends StatelessWidget {
  final String catName;
  final String race;
  final String? equippedHat;
  final CatMood mood;
  final double moral;
  final int streak;
  final int questCount;

  const _CatHeroSection({
    required this.catName,
    required this.race,
    required this.equippedHat,
    required this.mood,
    required this.moral,
    required this.streak,
    required this.questCount,
  });

  @override
  Widget build(BuildContext context) {
    final message = questCount > 0
        ? _questMessage(questCount)
        : CatMoodService.getBubbleMessage(mood, streak);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Socle en pierre et ombre : le chat est « posé » dans le sanctuaire.
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                bottom: 0,
                child: SizedBox(
                  width: 132,
                  height: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PixelCouleurs.panneauProfond,
                      border: Border(top: BorderSide(color: PixelCouleurs.trait, width: 3)),
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                child: SizedBox(width: 84, height: 6, child: ColoredBox(color: PixelCouleurs.abysse)),
              ),
              // le sprite garde une marge transparente sous les pattes : on le
              // descend d'autant pour qu'il repose sur l'ombre
              Positioned(
                bottom: -9,
                child: CatWidget(
                  race: race,
                  equippedHat: equippedHat,
                  size: 136,
                  mood: CatMoodService.getIdleAnimation(mood),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catName, style: PixelTextes.corps(18, poids: FontWeight.w700)),
                Text(CatMoodService.moodLabel(mood),
                    style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                const SizedBox(height: 8),
                _SpeechBubble(message: message),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _questMessage(int count) {
    if (count == 1) return 'Tu as 1 quête aujourd\'hui, allez !';
    if (count == 2) return '$count quêtes t\'attendent, courage !';
    return '$count quêtes aujourd\'hui, je crois en toi !';
  }
}

/// Bulle de dialogue pixel : fond blanc, ombre franche, petite pointe carrée.
class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: PixelCouleurs.violet, offset: Offset(4, 4))],
          ),
          child: Text(message, style: PixelTextes.corps(15, couleur: PixelCouleurs.nuit, poids: FontWeight.w600)),
        ),
        const Positioned(
          left: -8,
          bottom: 10,
          child: SizedBox(width: 8, height: 8, child: ColoredBox(color: Colors.white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte stats (tête haute : niveau, monnaies, série, PV, XP)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final PlayerStats stats;
  final int xpForNext;

  const _StatsCard({required this.stats, required this.xpForNext});

  @override
  Widget build(BuildContext context) {
    final xpProgress =
        xpForNext > 0 ? (stats.experience / xpForNext).clamp(0.0, 1.0) : 0.0;
    final hpProgress = stats.maxHealthPoints > 0
        ? (stats.healthPoints / stats.maxHealthPoints).clamp(0.0, 1.0)
        : 0.0;
    final serie = '${stats.streak} jour${stats.streak > 1 ? 's' : ''}';

    // Q10 : les chiffres du Sanctuaire sont lus d'un seul tenant par les
    // lecteurs d'écran.
    return Semantics(
      container: true,
      label: 'Niveau ${stats.level}, ${stats.experience} sur $xpForNext points d\'expérience, '
          '${stats.healthPoints} sur ${stats.maxHealthPoints} points de vie, série de $serie, '
          '${stats.gold} or, ${stats.crystals} cristaux',
      excludeSemantics: true,
      child: PixelCadre(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: PixelCouleurs.violetClair,
                  child: Text('NIV ${stats.level}', style: PixelTextes.chiffres(10, PixelCouleurs.nuit)),
                ),
                const Spacer(),
                _Compteur(icone: Icons.local_fire_department, couleur: PixelCouleurs.or, texte: serie),
                const SizedBox(width: 12),
                _Compteur(icone: Icons.monetization_on, couleur: PixelCouleurs.orClair, texte: '${stats.gold}'),
                const SizedBox(width: 12),
                _Compteur(icone: Icons.diamond, couleur: AppColors.crystalBlue, texte: '${stats.crystals}'),
              ],
            ),
            const SizedBox(height: 14),
            _LigneJauge(
              libelle: 'PV',
              couleurLibelle: AppColors.rarityMythic,
              valeur: hpProgress,
              couleur: const Color(0xFFF87171),
              texte: '${stats.healthPoints} / ${stats.maxHealthPoints}',
            ),
            const SizedBox(height: 10),
            _LigneJauge(
              libelle: 'XP',
              couleurLibelle: AppColors.rarityUncommon,
              valeur: xpProgress,
              couleur: const Color(0xFF4ADE80),
              texte: '${stats.experience} / $xpForNext',
            ),
          ],
        ),
      ),
    );
  }
}

class _Compteur extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String texte;
  const _Compteur({required this.icone, required this.couleur, required this.texte});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: couleur, size: 16),
          const SizedBox(width: 4),
          Text(texte, style: PixelTextes.corps(15, couleur: couleur, poids: FontWeight.w700)),
        ],
      );
}

/// Ligne « libellé, jauge, valeur » de la tête haute.
class _LigneJauge extends StatelessWidget {
  final String libelle;
  final Color couleurLibelle;
  final double valeur;
  final Color couleur;
  final String texte;

  const _LigneJauge({
    required this.libelle,
    required this.couleurLibelle,
    required this.valeur,
    required this.couleur,
    required this.texte,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(width: 30, child: Text(libelle, style: PixelTextes.chiffres(9, couleurLibelle))),
          Expanded(child: PixelJauge(valeur: valeur, couleur: couleur, hauteur: 14)),
          const SizedBox(width: 10),
          Text(texte, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux, poids: FontWeight.w600)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre moral
// ─────────────────────────────────────────────────────────────────────────────

class _MoralBar extends StatelessWidget {
  final double moral;

  const _MoralBar({required this.moral});

  @override
  Widget build(BuildContext context) {
    final color = moral > 0.7
        ? AppColors.mintMagic
        : moral > 0.3
            ? AppColors.warning
            : AppColors.coralRare;
    final pourcent = (moral * 100).round();

    return Semantics(
      label: 'Moral $pourcent pour cent',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Moral', style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux, poids: FontWeight.w600)),
              Text('$pourcent %', style: PixelTextes.chiffres(10, color)),
            ],
          ),
          const SizedBox(height: 6),
          PixelJauge(valeur: moral, couleur: color, hauteur: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile quête
// ─────────────────────────────────────────────────────────────────────────────

/// Carte de quête pixel : pastille d'icône colorée selon le mode de
/// validation, titre, sous-titre (« Preuve photo · Oracle », durée...).
class _QuestTile extends StatelessWidget {
  final Quest quest;

  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final duree = quest.estimatedDurationMinutes > 0 ? '${quest.estimatedDurationMinutes} min' : null;
    final (icone, couleur, sousTitre) = switch (quest.validationType) {
      ValidationType.photo => (Icons.photo_camera_outlined, PixelCouleurs.oracle, 'Preuve photo · Oracle'),
      ValidationType.timer => (Icons.timer_outlined, PixelCouleurs.orClair, duree == null ? 'Minuteur' : 'Minuteur · $duree'),
      ValidationType.geolocation => (Icons.place_outlined, AppColors.mintMagic, 'Lieu à visiter'),
      ValidationType.manual => (Icons.check_box_outlined, PixelCouleurs.violetClair, duree ?? quest.category),
    };
    // L'objet Quest complet est passé directement : pas de lookup par id.
    return _CartePixel(
      onTap: () => _ouvrirQuete(context, quest),
      bord: PixelCouleurs.trait,
      icone: icone,
      couleurIcone: couleur,
      titre: quest.title,
      sousTitre: sousTitre,
      couleurSousTitre: quest.validationType == ValidationType.photo ? PixelCouleurs.oracle : PixelCouleurs.texteDoux,
    );
  }
}

/// Tuile quête en retard : bord corail et retard affiché.
class _MissedQuestTile extends StatelessWidget {
  final Quest quest;

  const _MissedQuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final deadline = quest.deadline!;
    final diff = DateTime.now().difference(deadline);
    final retardLabel = diff.inHours < 24
        ? '${diff.inHours}h de retard'
        : '${diff.inDays}j de retard';

    return _CartePixel(
      onTap: () => _ouvrirQuete(context, quest),
      bord: AppColors.coralRare,
      icone: Icons.warning_amber_rounded,
      couleurIcone: AppColors.coralRare,
      titre: quest.title,
      sousTitre: retardLabel,
      couleurSousTitre: AppColors.coralRare,
    );
  }
}

class _CartePixel extends StatelessWidget {
  final VoidCallback onTap;
  final Color bord;
  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String sousTitre;
  final Color couleurSousTitre;

  const _CartePixel({
    required this.onTap,
    required this.bord,
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    required this.sousTitre,
    required this.couleurSousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: PixelCadre(
              bord: bord,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PixelCouleurs.panneauProfond,
                      border: Border.all(color: couleurIcone, width: 2),
                    ),
                    child: Icon(icone, color: couleurIcone, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: PixelTextes.corps(17, poids: FontWeight.w600)),
                        Text(sousTitre, style: PixelTextes.corps(14, couleur: couleurSousTitre)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: PixelCouleurs.texteDoux, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte boss hebdomadaire
// ─────────────────────────────────────────────────────────────────────────────

class _BossQuestCard extends StatelessWidget {
  final Quest quest;

  const _BossQuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    // L'objet Quest complet est passé directement — pas de lookup par id.
    return GestureDetector(
      onTap: () => _ouvrirQuete(context, quest),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.rarityEpic.withValues(alpha: 0.18),
              AppColors.backgroundDarkPanel,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.rarityEpic.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.rarityEpic.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.whatshot,
                    color: AppColors.rarityEpic, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Boss de la semaine',
                  style: GoogleFonts.nunito(
                    color: AppColors.rarityEpic,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.rarityEpic.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.rarityEpic.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'ÉPIQUE',
                    style: TextStyle(
                      color: AppColors.rarityEpic,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quest.title,
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (quest.description != null) ...[
              const SizedBox(height: 4),
              Text(
                quest.description!,
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _RewardChip(
                  icon: Icons.star,
                  color: AppColors.primaryTurquoise,
                  label: '+${quest.xpReward ?? 0} XP',
                ),
                _RewardChip(
                  icon: Icons.monetization_on,
                  color: AppColors.gold,
                  label: '+${quest.goldReward ?? 0} or',
                ),
                const _RewardChip(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.rarityLegendary,
                  label: 'Loot rare+',
                ),
              ],
            ),
            if (quest.deadline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _deadlineLabel(quest.deadline!),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _deadlineLabel(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.inDays > 1) return 'Expire dans ${diff.inDays} jours';
    if (diff.inHours > 0) return 'Expire dans ${diff.inHours}h';
    return 'Expire bientôt !';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Erreur chargement quêtes
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      bord: AppColors.error,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: PixelTextes.corps(15, couleur: AppColors.error))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État vide quêtes
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyQuestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Aucune quête pour aujourd'hui.",
            textAlign: TextAlign.center,
            style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux),
          ),
          const SizedBox(height: 14),
          // L'état vide mène directement à l'action attendue.
          PixelBouton(
            // « Première » seulement si le joueur n'a encore aucune quête (Q20).
            libelle: context.watch<QuestViewModel>().quests.isEmpty
                ? 'Créer ma première quête'
                : 'Créer une quête',
            onPressed: () => context.push(Routes.nouvelleQuete),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Récompense quotidienne
// ─────────────────────────────────────────────────────────────────────────────

class _DailyRewardDialog extends StatelessWidget {
  final int gold;
  final int seals;
  final int streak;

  const _DailyRewardDialog({
    required this.gold,
    required this.seals,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PixelCouleurs.panneau,
      shape: const RoundedRectangleBorder(side: BorderSide(color: PixelCouleurs.or, width: 3)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Récompense quotidienne',
              textAlign: TextAlign.center,
              style: PixelTextes.chiffres(13, PixelCouleurs.orClair).copyWith(
                shadows: const [Shadow(color: PixelCouleurs.orSombre, offset: Offset(2, 2))],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              streak > 0
                  ? 'Jour $streak de série'
                  : 'Valide une quête aujourd\'hui pour lancer ta série !',
              textAlign: TextAlign.center,
              style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(
                  icon: Icons.monetization_on,
                  color: AppColors.gold,
                  label: '+$gold or',
                ),
                const SizedBox(width: 16),
                _RewardChip(
                  icon: Icons.auto_awesome,
                  color: AppColors.crystalBlue,
                  label: '+$seals Sceau${seals > 1 ? 'x' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            PixelBouton(
              libelle: 'Récupérer',
              onPressed: () {
                unawaited(Sons.jouer(Son.piece));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RewardChip(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PixelCouleurs.panneauProfond,
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: PixelTextes.corps(16, couleur: color, poids: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Résumé hebdomadaire ──────────────────────────────────────────────────────

class _WeeklySummarySheet extends StatelessWidget {
  final int questsCompleted;
  final int xpEarned;
  final bool bossDefeated;
  final int streak;

  const _WeeklySummarySheet({
    required this.questsCompleted,
    required this.xpEarned,
    required this.bossDefeated,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Résumé de la semaine',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Voici ce que tu as accompli',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _WeekStat(
                  icon: Icons.check_circle_outline,
                  color: AppColors.primaryTurquoise,
                  value: '$questsCompleted',
                  label: 'Quêtes'),
              _WeekStat(
                  icon: Icons.star_outline,
                  color: AppColors.primaryTurquoise,
                  value: '$xpEarned',
                  label: 'XP'),
              _WeekStat(
                  icon: Icons.local_fire_department,
                  color: AppColors.warning,
                  value: '${streak}j',
                  label: 'Série'),
              // Boss hebdomadaire : de retour au Sprint 4 (boss serveur à PV).
              if (bossDefeated)
                const _WeekStat(
                  icon: Icons.shield_outlined,
                  color: AppColors.rarityEpic,
                  value: 'Vaincu',
                  label: 'Boss',
                ),
            ],
          ),
          if (bossDefeated) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.rarityEpic.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.rarityEpic.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond, color: AppColors.rarityEpic, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '+15 cristaux — bonus boss vaincu !',
                    style: TextStyle(
                        color: AppColors.rarityEpic,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTurquoise,
                foregroundColor: AppColors.backgroundNightBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Nouvelle semaine !',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _WeekStat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Détail d'une quête depuis l'accueil : une quête active peut être validée
/// directement (avant, la fiche n'offrait aucune action depuis le Sanctuaire).
Future<void> _ouvrirQuete(BuildContext context, Quest quest) {
  final active = quest.status == QuestStatus.active;
  return QuestDetailSheet.show(
    context,
    quest: quest,
    onValidate: active
        ? () => context.push(Routes.validerQuete(quest.id ?? ''), extra: quest)
        : null,
  );
}
