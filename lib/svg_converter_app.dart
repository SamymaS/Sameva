import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const SvgConverterApp());
}

class SvgConverterApp extends StatelessWidget {
  const SvgConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: FutureBuilder<String>(
            future: _convertSvgToPng(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Erreur : ${snapshot.error}');
                }
                return Text(snapshot.data ?? 'Conversion terminée !');
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  Future<String> _convertSvgToPng() async {
    try {
      // Note: Cette fonction utilise l'ancienne API de flutter_svg
      // qui n'est plus disponible dans les versions récentes.
      // Pour convertir SVG en PNG, utilisez plutôt un package comme
      // `flutter_svg` avec `SvgPicture` ou un service externe.
      
      return 'Conversion SVG vers PNG nécessite une mise à jour de l\'implémentation. '
          'Utilisez SvgPicture.asset() pour afficher les SVG directement dans Flutter.';
    } catch (e) {
      return 'Erreur : $e';
    }
  }
} 