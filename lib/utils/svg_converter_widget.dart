import 'package:flutter/material.dart';

/// Widget pour convertir SVG en PNG
/// 
/// Note: Cette fonctionnalité nécessite une mise à jour car l'ancienne API
/// de flutter_svg n'est plus disponible dans les versions récentes.
/// 
/// Pour afficher des SVG dans Flutter, utilisez plutôt:
/// ```dart
/// SvgPicture.asset('assets/images/rpg_pattern.svg')
/// ```
class SvgConverterWidget extends StatelessWidget {
  const SvgConverterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SVG Converter')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'La conversion SVG vers PNG nécessite une mise à jour de l\'implémentation.\n\n'
              'Utilisez SvgPicture.asset() pour afficher les SVG directement dans Flutter.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
} 