import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/achievement_service.dart';
import '../../../domain/services/activity_log_service.dart';
import '../../../domain/services/cat_mood_service.dart';
import '../../../domain/services/minigame_service.dart';
import '../../../domain/services/weekly_boss_service.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cat/cat_widget.dart';

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
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) return;
    await questVM.loadQuests(userId);
    if (!mounted) return;
    await questVM.resetDailyQuests(userId);
    if (!mounted) return;
    await playerVM.loadPlayerStats(userId);
    if (!mounted) return;
    await _applyEquipmentHpBonus(userId);
    if (!mounted) return;
    await _applyMissedQuestPenalties();
    if (!mounted) return;
    await _checkWeeklySummary(userId);
    if (!mounted) return;
    await _checkDailyReward(userId);
    if (!mounted) return;
    await _checkWeeklyBoss(userId);
    if (!mounted) return;
    await _checkAchievements();
  }

  Future<void> _checkAchievements() async {
    final playerVM = context.read<PlayerViewModel>();
    final questVM = context.read<QuestViewModel>();
    final stats = playerVM.stats;
    if (stats == null) return;

    final settings = Hive.box('settings');
    final bossDefeated = questVM.completedQuests.any((q) => q.category == 'boss');
    final minigamesPlayed = MinigameService.totalPlayed(settings);
    final hasGachaFirst = settings.get('gacha_first_done', defaultValue: false) as bool;
    final hasGachaMulti = settings.get('gacha_multi_done', defaultValue: false) as bool;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(achievement.icon, color: achievement.color, size: 18),
            const SizedBox(width: 8),
            Text('Succès débloqué : ${achievement.name}'),
          ],
        ),
        backgroundColor: AppColors.backgroundDarkPanel,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _checkDailyReward(String userId) async {
    final settings = Hive.box('settings');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if ((settings.get('last_login_date') as String?) == today) return;
    await settings.put('last_login_date', today);
    if (!mounted) return;

    final playerVM = context.read<PlayerViewModel>();
    final streak = playerVM.stats?.streak ?? 0;

    // Récompense : 50 or + 5 cristaux de base, +10 or/+2 cristaux par tranche de 7 jours
    final streakBonus = streak ~/ 7;
    final gold = 50 + streakBonus * 10;
    final crystals = 5 + streakBonus * 2;

    await playerVM.addGold(userId, gold);
    await playerVM.addCrystals(userId, crystals);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _DailyRewardDialog(gold: gold, crystals: crystals, streak: streak),
    );
  }

  Future<void> _checkWeeklyBoss(String userId) async {
    if (WeeklyBossService.hasGeneratedThisWeek()) return;
    final questVM = context.read<QuestViewModel>();
    // Vérifier qu'il n'existe pas déjà un boss actif cette semaine
    final hasBoss = questVM.activeQuests.any((q) => q.category == 'boss');
    if (hasBoss) {
      await WeeklyBossService.markGenerated();
      return;
    }
    final boss = WeeklyBossService.buildBossQuest(userId);
    await questVM.addQuest(boss);
    await WeeklyBossService.markGenerated();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Un nouveau boss hebdomadaire est apparu !'),
        backgroundColor: AppColors.rarityEpic,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkWeeklySummary(String userId) async {
    final settings = Hive.box('settings');
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${monday.year}_${monday.month}_${monday.day}';

    // Montrer le résumé une seule fois par semaine, seulement à partir du lundi (j≥1)
    if (settings.get('last_weekly_summary') == weekKey) return;
    // Attendre au moins 24h dans la semaine avant de l'afficher
    final dayOfWeek = now.weekday; // 1=Lundi … 7=Dimanche
    if (dayOfWeek < 2) return; // Lundi même jour : pas encore de résumé

    await settings.put('last_weekly_summary', weekKey);

    // Stats de la semaine précédente (lundi dernier → dimanche dernier)
    final prevMonday = monday.subtract(const Duration(days: 7));
    final prevSunday = monday.subtract(const Duration(seconds: 1));

    final questVM = context.read<QuestViewModel>();
    final playerVM = context.read<PlayerViewModel>();

    final weekQuests = questVM.completedQuests.where((q) =>
      q.completedAt != null &&
      q.completedAt!.isAfter(prevMonday) &&
      q.completedAt!.isBefore(prevSunday)
    ).toList();

    // XP depuis l'ActivityLog
    final log = ActivityLogService.getLog();
    int weekXp = 0;
    for (final entry in log) {
      if (entry.type == ActivityType.quest &&
          entry.date.isAfter(prevMonday) &&
          entry.date.isBefore(prevSunday) &&
          entry.subtitle != null) {
        final match = RegExp(r'\+(\d+) XP').firstMatch(entry.subtitle!);
        if (match != null) weekXp += int.tryParse(match.group(1)!) ?? 0;
      }
    }

    final bossDefeated = weekQuests.any((q) => q.category == 'boss');
    final streak = playerVM.stats?.streak ?? 0;

    // Récompense bonus si boss vaincu
    if (bossDefeated) {
      await playerVM.addCrystals(userId, 15);
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeeklySummarySheet(
        questsCompleted: weekQuests.length,
        xpEarned: weekXp,
        bossDefeated: bossDefeated,
        streak: streak,
      ),
    );
  }

  /// Synchronise le bonus maxHP de l'équipement au démarrage.
  /// Utilise une clé Hive 'last_equipment_hp_bonus' pour détecter les delta.
  Future<void> _applyEquipmentHpBonus(String userId) async {
    final equipment = context.read<EquipmentViewModel>();
    final playerVM = context.read<PlayerViewModel>();
    final settings = Hive.box('settings');

    final expected = equipment.hpBonus;
    final stored = settings.get('last_equipment_hp_bonus', defaultValue: 0) as int;
    if (expected == stored) return;

    final delta = expected - stored;
    await playerVM.adjustMaxHp(userId, delta);
    await settings.put('last_equipment_hp_bonus', expected);
  }

  Future<void> _applyMissedQuestPenalties() async {
    final settings = Hive.box('settings');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if ((settings.get('last_penalty_date') as String?) == today) return;

    final questVM = context.read<QuestViewModel>();
    final playerVM = context.read<PlayerViewModel>();
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) return;

    final missed = questVM.getMissedQuests();
    await settings.put('last_penalty_date', today);

    if (missed.isEmpty) return;

    // Dommages : 10 HP × difficulté par quête manquée
    int totalDamage = 0;
    for (final q in missed) {
      final dmg = 10 * q.difficulty;
      totalDamage += dmg;
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.quest,
        title: 'Quête manquée : ${q.title}',
        subtitle: '-$dmg HP · -10% moral',
        date: DateTime.now(),
      ));
      // Supprimer la quête manquée pour éviter la double pénalité
      await questVM.deleteQuest(q.id!);
    }

    await playerVM.takeDamage(userId, totalDamage);
    await playerVM.updateMoral(userId, -(missed.length * 0.1));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${missed.length} quête${missed.length > 1 ? 's' : ''} manquée${missed.length > 1 ? 's' : ''} — $totalDamage HP perdus',
        ),
        backgroundColor: AppColors.coralRare.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
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
            final todayQuests = quests.activeQuests.where((q) {
              if (q.deadline != null && now.isAfter(q.deadline!)) return false;
              final created = DateTime(
                  q.createdAt.year, q.createdAt.month, q.createdAt.day);
              return created == today || q.frequency == QuestFrequency.daily;
            }).take(3).toList();

            final xpForNext = player.experienceForLevel(stats.level);
            final cat = catProvider.mainCat;
            final mood = CatMoodService.getMoodExpression(
                stats.moral, stats.streak);

            return RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primaryVioletLight,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ─────────────────────────────────────────────
                  SliverAppBar(
                    backgroundColor: AppColors.backgroundNightCosmos,
                    floating: true,
                    elevation: 0,
                    title: Text(
                      'Sanctuaire',
                      style: GoogleFonts.nunito(
                        color: AppColors.primaryVioletLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${stats.streak}j',
                              style: GoogleFonts.nunito(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                              Text(
                                'En retard',
                                style: GoogleFonts.nunito(
                                  color: AppColors.coralRare,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...missedQuests.map((q) => _MissedQuestTile(quest: q)),
                          const SizedBox(height: 20),
                        ],

                        // ── Quêtes du jour ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Aujourd'hui",
                              style: GoogleFonts.nunito(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/quests'),
                              child: const Text(
                                'Voir tout',
                                style: TextStyle(
                                    color: AppColors.primaryVioletLight),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (quests.isLoading)
                          const Center(child: CircularProgressIndicator())
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
    final bodyColor = catBodyColor(race);
    final message = questCount > 0
        ? _questMessage(questCount, mood)
        : CatMoodService.getBubbleMessage(mood, streak);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Chat avec glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow derrière
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bodyColor.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            CatWidget(
              race: race,
              equippedHat: equippedHat,
              size: 130,
              mood: CatMoodService.getIdleAnimation(mood),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Colonne : nom + bulle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom + humeur
              Row(
                children: [
                  Text(
                    catName,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    CatMoodService.moodEmoji(mood),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bulle de dialogue
              _SpeechBubble(message: message),
            ],
          ),
        ),
      ],
    );
  }

  String _questMessage(int count, CatMood mood) {
    if (count == 1) return 'Tu as 1 quête aujourd\'hui, allez ! 🐾';
    if (count == 2) return '$count quêtes t\'attendent, courage ! ✨';
    return '$count quêtes aujourd\'hui — je crois en toi ! 🌟';
  }
}

class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4), // pointe vers le chat
        ),
        border: Border.all(
          color: AppColors.primaryVioletLight.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryViolet.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        style: GoogleFonts.nunito(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre animée réutilisable
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;

  const _AnimatedBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: height,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte stats
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.backgroundDarkPanel,
            AppColors.backgroundDeepViolet,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryViolet.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Niveau ${stats.level}',
                    style: GoogleFonts.nunito(
                      color: AppColors.primaryVioletLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${stats.experience} / $xpForNext XP',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.gold}',
                    style: const TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.diamond,
                      color: AppColors.crystalBlue, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.crystals}',
                    style: const TextStyle(
                        color: AppColors.crystalBlue,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre XP
          _AnimatedBar(
            value: xpProgress,
            color: AppColors.primaryViolet,
            backgroundColor: AppColors.backgroundNightCosmos,
          ),
          const SizedBox(height: 12),
          // HP + streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite,
                      color: AppColors.rosePastel, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.healthPoints} / ${stats.maxHealthPoints} HP',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.warning, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.streak} jour${stats.streak > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barre HP
          _AnimatedBar(
            value: hpProgress,
            color: AppColors.rosePastel,
            backgroundColor: AppColors.backgroundNightCosmos,
            height: 6,
          ),
        ],
      ),
    );
  }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Moral',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(moral * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _AnimatedBar(
          value: moral,
          color: color,
          backgroundColor: AppColors.backgroundDarkPanel,
          height: 6,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile quête
// ─────────────────────────────────────────────────────────────────────────────

class _QuestTile extends StatelessWidget {
  final Quest quest;

  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryViolet.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined,
              color: AppColors.primaryVioletLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quest.title,
              style: const TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${quest.estimatedDurationMinutes} min',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile quête en retard
// ─────────────────────────────────────────────────────────────────────────────

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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coralRare.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.coralRare.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.coralRare, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quest.title,
              style: const TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            retardLabel,
            style: const TextStyle(color: AppColors.coralRare, fontSize: 11),
          ),
        ],
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
    return Container(
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
        border: Border.all(color: AppColors.rarityEpic.withValues(alpha: 0.6), width: 1.5),
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
              const Icon(Icons.whatshot, color: AppColors.rarityEpic, size: 18),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.rarityEpic.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.rarityEpic.withValues(alpha: 0.5)),
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
          Row(
            children: [
              _RewardChip(
                icon: Icons.star,
                color: AppColors.primaryTurquoise,
                label: '+${quest.xpReward ?? 0} XP',
              ),
              const SizedBox(width: 8),
              _RewardChip(
                icon: Icons.monetization_on,
                color: AppColors.gold,
                label: '+${quest.goldReward ?? 0} or',
              ),
              const SizedBox(width: 8),
              _RewardChip(
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
                const Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  _deadlineLabel(quest.deadline!),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
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
// État vide quêtes
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyQuestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          "Aucune quête pour aujourd'hui.\nCrée ta première quête !",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Récompense quotidienne
// ─────────────────────────────────────────────────────────────────────────────

class _DailyRewardDialog extends StatelessWidget {
  final int gold;
  final int crystals;
  final int streak;

  const _DailyRewardDialog({
    required this.gold,
    required this.crystals,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDarkPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Récompense quotidienne',
              style: GoogleFonts.nunito(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jour $streak de série',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                  icon: Icons.diamond,
                  color: AppColors.crystalBlue,
                  label: '+$crystals cristaux',
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryViolet,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Récupérer'),
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

  const _RewardChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
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
              _WeekStat(icon: Icons.check_circle_outline, color: AppColors.primaryTurquoise, value: '$questsCompleted', label: 'Quêtes'),
              _WeekStat(icon: Icons.star_outline,         color: AppColors.primaryTurquoise, value: '$xpEarned',         label: 'XP'),
              _WeekStat(icon: Icons.local_fire_department, color: AppColors.warning,          value: '${streak}j',        label: 'Série'),
              _WeekStat(
                icon: Icons.shield_outlined,
                color: bossDefeated ? AppColors.rarityEpic : AppColors.textMuted,
                value: bossDefeated ? 'Vaincu' : 'Manqué',
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
                border: Border.all(color: AppColors.rarityEpic.withValues(alpha: 0.3)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Nouvelle semaine !', style: TextStyle(fontWeight: FontWeight.bold)),
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

  const _WeekStat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
