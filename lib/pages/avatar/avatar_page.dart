import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// TODO: Importer Rive quand les fichiers .riv seront disponibles
// import 'package:rive/rive.dart';

/// AVATAR — placeholder panneau custom
class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Personnalisation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: Builder(
            builder: (context) {
              // Pour l'instant, on utilise Lottie en attendant les fichiers Rive
              // TODO: Remplacer par RiveAnimation.asset quand les fichiers .riv seront disponibles
              return Lottie.asset(
                'assets/animations/rpg_logo.json',
                repeat: true,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.face,
                  size: 120,
                  color: Colors.white54,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text('Tenues, auras, compagnons — à venir'),
      ],
    );
  }
}

