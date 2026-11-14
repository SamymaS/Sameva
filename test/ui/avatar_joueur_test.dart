import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sameva/core/avatar/apparence_avatar.dart';
import 'package:sameva/core/providers.dart';
import 'package:sameva/core/visuels/visuels.dart';
import 'package:sameva/data/models/character_model.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/ui/widgets/avatar/avatar_joueur.dart';
import 'package:sameva/ui/widgets/character/character_painter.dart';

CharacterPainter _peintre(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(of: find.byType(AvatarJoueur), matching: find.byType(CustomPaint)).first)
    .painter! as CharacterPainter;

Item _cosmetique(String id, {required int couleur, int? style}) => Item(
      id: id,
      name: id,
      description: '',
      type: ItemType.cosmetic,
      rarity: QuestRarity.common,
      iconCodePoint: 0xe000,
      goldValue: 0,
      stats: {'colorValue': couleur, if (style != null) 'styleIndex': style},
    );

void main() {
  tearDown(() => Visuels.definirManifeste(const {}));

  testWidgets('avatar provisoire : dessiné par le code, annoncé aux lecteurs d\'écran', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: AvatarJoueur(apparence: CharacterAppearance(skinTone: SkinTone.dark), hauteur: 200)),
    ));
    expect(find.bySemanticsLabel('Ton personnage'), findsOneWidget);
    expect(_peintre(tester).appearance.skinTone, SkinTone.dark);
    expect(tester.getSize(find.byType(AvatarJoueur)).height, 200);
  });

  testWidgets('la tenue vient des cosmétiques équipés', (tester) async {
    final equipes = {
      'outfit': _cosmetique('haut', couleur: 0xFFAA0000),
      'hat': _cosmetique('chapeau', couleur: 0xFF00AA00, style: 2),
    };
    await tester.pumpWidget(MaterialApp(
      home: AvatarJoueur(
        apparence: const CharacterAppearance(),
        tenue: TenueAvatar.depuisCosmetiques((e) => equipes[e]),
      ),
    ));
    final p = _peintre(tester);
    expect(p.outfitColor, const Color(0xFFAA0000));
    expect(p.hatStyle, 2);
    expect(p.hatColor, const Color(0xFF00AA00));
    expect(p.auraColor, isNull);
  });

  testWidgets('« réduire les animations » : l\'avatar ne bouge pas', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: AvatarJoueur(apparence: CharacterAppearance())),
    ));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('un avatar livré par la DA remplace le dessin provisoire', (tester) async {
    Visuels.definirManifeste({'avatar': 'assets/da/avatar.png'});
    await tester.pumpWidget(const MaterialApp(home: AvatarJoueur(apparence: CharacterAppearance(), anime: false)));
    expect(find.descendant(of: find.byType(AvatarJoueur), matching: find.byType(Image)), findsOneWidget);
    expect(find.descendant(of: find.byType(AvatarJoueur), matching: find.byType(CustomPaint)), findsNothing);
    tester.takeException(); // le fichier n'existe pas dans le bundle de test
  });

  group('apparence enregistrée', () {
    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('hive_avatar_test');
      Hive.init(dir.path);
      await Hive.openBox('settings');
    });

    ProviderContainer conteneur(String? uid) {
      final c = ProviderContainer(overrides: [currentUserIdProvider.overrideWith((ref) => Stream.value(uid))]);
      addTearDown(c.dispose);
      return c;
    }

    test('conservée par compte et relue', () async {
      final a = conteneur('alice');
      await a.read(currentUserIdProvider.future);
      await a
          .read(apparenceAvatarProvider.notifier)
          .definir(const CharacterAppearance(gender: CharacterGender.female, hairStyle: HairStyle.bun));

      final encoreAlice = conteneur('alice');
      await encoreAlice.read(currentUserIdProvider.future);
      expect(encoreAlice.read(apparenceAvatarProvider).hairStyle, HairStyle.bun);
      expect(encoreAlice.read(apparenceAvatarProvider).gender, CharacterGender.female);

      final bob = conteneur('bob');
      await bob.read(currentUserIdProvider.future);
      expect(bob.read(apparenceAvatarProvider).hairStyle, HairStyle.medium, reason: 'apparence par défaut');
    });
  });
}
