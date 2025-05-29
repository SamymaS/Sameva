import 'package:flutter/widgets.dart';
import '../lib/utils/svg_to_png_converter.dart';

void main() async {
  // Initialiser le binding Flutter
  WidgetsFlutterBinding.ensureInitialized();

  print('Conversion du motif SVG en PNG...');
  await convertSvgToPng();
  print('Conversion terminée !');
} 