import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';

/// Page de récompenses animée.
///
/// Peut être ouverte de deux façons :
/// 1. Depuis la navigation principale (sans arguments) → résumé global.
/// 2. Après completion d'une quête (arguments [RewardsArgs]) → célébration.
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

/// Arguments optionnels passés via `Navigator.pushNamed('/rewards', arguments: RewardsArgs(...))`.
class RewardsArgs {
  final int xpGained;
  final int goldGained;
  final bool leveledUp;
  final int newLevel;

  const RewardsArgs({
    required this.xpGained,
    required this.goldGained,
    this.leveledUp = false,
    this.newLevel = 1,
  });
}

class _RewardsPageState extends State<RewardsPage>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _countCtrl;
  late Animation<double> _countAnimation;

  RewardsArgs? _args;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countAnimation = CurvedAnimation(
      parent: _countCtrl,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _args = ModalRoute.of(context)?.settings.arguments as RewardsArgs?;
      if (_args != null) {
        _countCtrl.forward();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Récompenses',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
      ),
      body: _args != null
          ? _CelebrationView(
              args: _args!,
              particleCtrl: _particleCtrl,
              countAnimation: _countAnimation,
            )
          : _SummaryView(countAnimation: _countAnimation),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Vue célébration (post-quête)
// ─────────────────────────────────────────────────────────────────

class _CelebrationView extends StatelessWidget {
  final RewardsArgs args;
  final AnimationController particleCtrl;
  final Animation<double> countAnimation;

  const _CelebrationView({
    required this.args,
    required this.particleCtrl,
    required this.countAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particules de fond
        Positioned.fill(
          child: AnimatedBuilder(
            animation: particleCtrl,
            builder: (_, __) =>
                CustomPaint(painter: _ParticlePainter(particleCtrl.value)),
          ),
        ),
        // Contenu
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Icône centrale
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryTurquoise.withValues(alpha: 0.15),
                      border: Border.all(
                          color: AppColors.primaryTurquoise, width: 2),
                    ),
                    child: const Icon(Icons.military_tech,
                        color: AppColors.primaryTurquoise, size: 52),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Quête accomplie !',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),

                // Compteurs XP + Or animés
                Row(
                  children: [
                    Expanded(
                      child: _AnimatedCounter(
                        animation: countAnimation,
                        target: args.xpGained,
                        icon: Icons.star,
                        color: AppColors.primaryTurquoise,
                        label: 'XP gagnés',
                        prefix: '+',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedCounter(
                        animation: countAnimation,
                        target: args.goldGained,
                        icon: Icons.monetization_on,
                        color: AppColors.gold,
                        label: 'Or gagnés',
                        prefix: '+',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Level up !
                if (args.leveledUp)
                  _LevelUpBanner(newLevel: args.newLevel),

                const SizedBox(height: 24),
                _StatsSection(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurquoise,
                    foregroundColor: AppColors.backgroundNightBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continuer',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Vue résumé (navigation directe)
// ─────────────────────────────────────────────────────────────────

class _SummaryView extends StatelessWidget {
  final Animation<double> countAnimation;

  const _SummaryView({required this.countAnimation});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, player, _) {
        final stats = player.stats;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final level = stats.level;
        final xp = stats.experience;
        final xpNeeded = player.experienceForLevel(level);
        final xpProgress =
            xpNeeded > 0 ? (xp / xpNeeded).clamp(0.0, 1.0) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carte niveau + XP
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.backgroundDarkPanel,
                      AppColors.backgroundDeepViolet
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primaryTurquoise.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Niveau $level',
                          style: const TextStyle(
                              color: AppColors.primaryTurquoise,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.shield,
                            color: AppColors.primaryTurquoise, size: 28),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp / $xpNeeded XP → Niveau ${level + 1}',
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: xpProgress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: v,
                          backgroundColor: AppColors.backgroundNightBlue,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryTurquoise),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatsSection(),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Continuez à valider des quêtes pour progresser.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets communs
// ─────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (_, player, __) {
        final stats = player.stats;
        if (stats == null) return const SizedBox.shrink();
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.monetization_on,
                color: AppColors.gold,
                value: '${stats.gold}',
                label: 'Or',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department,
                color: AppColors.warning,
                value: '${stats.streak}j',
                label: 'Série',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                icon: Icons.favorite,
                color: AppColors.error,
                value: '${stats.healthPoints}',
                label: 'HP',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final Animation<double> animation;
  final int target;
  final IconData icon;
  final Color color;
  final String label;
  final String prefix;

  const _AnimatedCounter({
    required this.animation,
    required this.target,
    required this.icon,
    required this.color,
    required this.label,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final current = (target * animation.value).round();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                '$prefix$current',
                style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _LevelUpBanner extends StatelessWidget {
  final int newLevel;

  const _LevelUpBanner({required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondaryViolet, AppColors.primaryTurquoise],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_upward, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Niveau supérieur !',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('Vous atteignez le niveau $newLevel',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Particules (confetti léger)
// ─────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rand = math.Random();
  static final List<_Particle> _particles = List.generate(
    30,
    (i) => _Particle(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      size: 3 + _rand.nextDouble() * 5,
      speed: 0.1 + _rand.nextDouble() * 0.3,
      color: [
        AppColors.primaryTurquoise,
        AppColors.gold,
        AppColors.secondaryViolet,
        Colors.white,
      ][i % 4],
      phase: _rand.nextDouble(),
    ),
  );

  const _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = ((progress + p.phase) % 1.0);
      final x = p.x * size.width + math.sin(t * math.pi * 2) * 20;
      final y = (p.y + t * p.speed) % 1.0 * size.height;
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - t * 0.5),
        Paint()..color = p.color.withValues(alpha: (1 - t) * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase;
  final Color color;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.phase,
  });
}
