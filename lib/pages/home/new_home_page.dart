import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/animations/avatar_idle_animation.dart';
import '../../widgets/animations/particles_halo.dart';
import '../../widgets/fantasy/fantasy_button.dart';
import '../../widgets/fantasy/animated_background.dart';
import '../../pages/quest/fantasy_create_quest_page.dart';
// TODO: Importer Rive quand les fichiers .riv seront disponibles
// import 'package:rive/rive.dart';

/// ACCUEIL — Avatar plein cadre + bouton "Créer une quête" + mini-récap
class NewHomePage extends StatelessWidget {
  const NewHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond animé avec gradient et particules
        const Positioned.fill(
          child: AnimatedBackground(),
        ),
        // Contenu
        Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FantasyButton(
                label: 'Créer une quête',
                icon: Icons.add,
                glowColor: const Color(0xFFF59E0B),
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const FantasyCreateQuestPage(),
                      transitionsBuilder: (_, animation, __, child) {
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );
                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // Avatar Rive (idle)
            SizedBox(
              height: 360,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Avatar animé avec CustomPaint (remplace Rive temporairement)
                  const AvatarIdleAnimation(size: 280),
                  // Halo de particules autour de l'avatar
                  const ParticlesHalo(
                    color: Color(0xFF1AA7EC),
                    size: 320,
                  ),
                  // Compagnon Lottie (idle léger)
                  Positioned(
                    right: 32,
                    bottom: 80,
                    child: SizedBox(
                      width: 96,
                      child: Lottie.asset(
                        'assets/animations/loading.json',
                        repeat: true,
                        frameRate: FrameRate.max,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Quêtes du jour — mini-cards
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  QuestCard(title: 'Aller au sport', color: Color(0xFF22C55E)),
                  QuestCard(title: 'Lire 20 min', color: Color(0xFF60A5FA)),
                  QuestCard(title: 'Projet cours', color: Color(0xFFF59E0B)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}

class QuestCard extends StatefulWidget {
  final String title;
  final Color color;

  const QuestCard({super.key, required this.title, required this.color});

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHovered) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1422),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.color.withOpacity(_isHovered ? _glowAnimation.value : 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_isHovered ? _glowAnimation.value * 0.4 : 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: widget.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: 0.3,
                    color: widget.color,
                    backgroundColor: const Color(0xFF1B2336),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '30%',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

