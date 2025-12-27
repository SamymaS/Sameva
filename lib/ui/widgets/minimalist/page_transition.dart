import 'package:flutter/material.dart';

/// Transition de page personnalisée avec fade et slide
/// Style "Magie Minimaliste" - Transitions douces
class MinimalistPageTransition extends PageRouteBuilder {
  final Widget child;
  final Duration transitionDuration;

  MinimalistPageTransition({
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade in
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            // Slide from bottom (subtle)
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Hero animation pour les éléments partagés
class MinimalistHero extends StatelessWidget {
  final String tag;
  final Widget child;

  const MinimalistHero({
    super.key,
    required this.tag,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}





