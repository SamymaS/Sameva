import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/cat_mood_service.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/cat_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
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
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await context.read<QuestProvider>().loadQuests(userId);
    await context.read<PlayerProvider>().loadPlayerStats(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      body: SafeArea(
        child: Consumer3<PlayerProvider, QuestProvider, CatProvider>(
          builder: (context, player, quests, catProvider, _) {
            final stats = player.stats;
            if (stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final todayQuests = quests.activeQuests.where((q) {
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
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Carte stats XP/HP ──────────────────────────
                        _StatsCard(stats: stats, xpForNext: xpForNext),
                        const SizedBox(height: 12),

                        // ── Barre moral ────────────────────────────────
                        _MoralBar(moral: stats.moral),
                        const SizedBox(height: 24),

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
                              child: Text(
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

  const _CatHeroSection({
    required this.catName,
    required this.race,
    required this.equippedHat,
    required this.mood,
    required this.moral,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor = catBodyColor(race);
    final message = CatMoodService.getBubbleMessage(mood, streak);

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
