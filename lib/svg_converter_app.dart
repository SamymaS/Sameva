import 'dart:io';
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
      // Charger le SVG
      final String svgString = await File('assets/images/rpg_pattern.svg').readAsString();
      final DrawableRoot svgRoot = await svg.fromSvgString(svgString, 'rpg_pattern');

      // Créer une image de 64x64 pixels
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Size size = const Size(64, 64);

      // Dessiner le SVG
      svgRoot.scaleCanvasToViewBox(canvas, size);
      svgRoot.draw(canvas, Rect.fromLTWH(0, 0, size.width, size.height));

      // Convertir en image
      final ui.Image image = await recorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      // Convertir en bytes
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        // Sauvegarder le PNG
        await File('assets/images/rpg_pattern.png').writeAsBytes(pngBytes);
        return 'Conversion réussie !';
      }
      return 'Erreur : ByteData est null';
    } catch (e) {
      return 'Erreur : $e';
    }
  }
} 