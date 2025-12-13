import 'package:flutter/material.dart';

class RPGPageTransition extends PageRouteBuilder {
  final Widget page;

  RPGPageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return Stack(
              children: [
                // Effet de flou sur la page précédente
                FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.8)
                      .animate(CurvedAnimation(parent: animation, curve: curve)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 0.95)
                        .animate(CurvedAnimation(parent: animation, curve: curve)),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                // Nouvelle page avec slide et fade
                SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
} 