import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/visuels/visuels.dart';

void main() {
  tearDown(() => Visuels.definirManifeste(const {}));

  group('sans direction artistique livrée : pixel art provisoire', () {
    test('objet : nom logique tiré de l\'ancien chemin', () {
      expect(Visuels.objet('assets/items/sword_rusty.svg'), const Visuel('assets/sprites/objets/sword_rusty.png'));
      expect(Visuels.objet('hat_crown_gold')!.chemin, 'assets/sprites/objets/hat_crown_gold.png');
      expect(Visuels.objet(null), isNull);
      expect(Visuels.objet(''), isNull);
    });

    test('chat, MougiBot, avatar, son', () {
      expect(Visuels.chat('lune'), const Visuel('assets/sprites/chat_lune.png'));
      expect(Visuels.mougibot.chemin, 'assets/sprites/mougibot.png');
      expect(Visuels.mougibot.pixel, isTrue);
      expect(Visuels.avatar, isNull, reason: 'avatar provisoire dessiné par le code');
      expect(Visuels.son('quete_accomplie'), 'sfx/quete_accomplie.wav');
    });
  });

  group('avec un manifeste de DA', () {
    setUp(() => Visuels.definirManifeste({
          'style': {'pixel': false},
          'objets': {'sword_rusty': 'assets/da/objets/epee.png'},
          'chats': {'lune': 'assets/da/chats/lune.png'},
          'mougibot': 'assets/da/robot.png',
          'avatar': 'assets/da/avatar.png',
          'sons': {'quete_accomplie': 'assets/da/sfx/victoire.ogg'},
        }));

    test('le visuel livré remplace le provisoire, lissé', () {
      final epee = Visuels.objet('assets/items/sword_rusty.svg')!;
      expect(epee.chemin, 'assets/da/objets/epee.png');
      expect(epee.pixel, isFalse);
      expect(Visuels.chat('lune').chemin, 'assets/da/chats/lune.png');
      expect(Visuels.mougibot.chemin, 'assets/da/robot.png');
      expect(Visuels.avatar!.chemin, 'assets/da/avatar.png');
      expect(Visuels.son('quete_accomplie'), 'da/sfx/victoire.ogg');
    });

    test('ce qui n\'est pas livré reste en pixel art', () {
      expect(Visuels.objet('potion_heal')!.chemin, 'assets/sprites/objets/potion_heal.png');
      expect(Visuels.objet('potion_heal')!.pixel, isTrue);
      expect(Visuels.chat('braise').chemin, 'assets/sprites/chat_braise.png');
      expect(Visuels.son('piece'), 'sfx/piece.wav');
    });
  });

  test('le manifeste du dépôt est valide et ne pointe que vers des fichiers présents', () {
    final m = jsonDecode(File(Visuels.cheminManifeste).readAsStringSync()) as Map<String, dynamic>;
    final chemins = <String>[
      for (final section in ['objets', 'chats', 'sons']) ...((m[section] as Map?)?.values.cast<String>() ?? const []),
      for (final cle in ['mougibot', 'avatar'])
        if ((m[cle] as String?)?.isNotEmpty ?? false) m[cle] as String,
    ];
    for (final c in chemins) {
      expect(File(c).existsSync(), isTrue, reason: '$c est cité dans le manifeste mais absent');
    }
  });
}
