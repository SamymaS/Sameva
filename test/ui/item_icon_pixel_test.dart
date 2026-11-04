import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/ui/widgets/common/item_icon.dart';

void main() {
  test('l\'ancien chemin SVG mène à l\'icône pixel art', () {
    expect(iconePixelPour('assets/items/sword_rusty.svg'), 'assets/sprites/objets/sword_rusty.png');
    expect(iconePixelPour(null), isNull);
    expect(iconePixelPour(''), isNull);
  });

  test('chaque objet du jeu a son icône pixel art', () {
    final sources = ['lib/domain/services/item_factory.dart', 'lib/domain/services/craft_service.dart']
        .map((f) => File(f).readAsStringSync())
        .join('\n');
    final chemins = RegExp(r"assets/items/[a-z_]+\.svg").allMatches(sources).map((m) => m.group(0)!).toSet();
    expect(chemins, isNotEmpty);
    for (final c in chemins) {
      expect(File(iconePixelPour(c)!).existsSync(), isTrue, reason: c);
    }
  });
}
