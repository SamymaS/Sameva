import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sameva/core/avatar/apparence_avatar.dart';
import 'package:sameva/core/providers.dart';
import 'package:sameva/data/models/character_model.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/ui/widgets/avatar/avatar_joueur.dart';

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
  // Le vrai manifeste du dépôt, produit par tools/avatar3d/generer_avatar.py.
  final json = jsonDecode(File('assets/avatar/manifeste.json').readAsStringSync()) as Map<String, dynamic>;
  final manifeste = ManifesteAvatar('assets/avatar', json);

  group('couches rendues par Blender', () {
    test('toutes les combinaisons d\'apparence ont leurs images', () {
      for (final g in CharacterGender.values) {
        for (final h in HairStyle.values) {
          final noms = manifeste
              .couches(CharacterAppearance(gender: g, hairStyle: h), const TenueAvatar())
              .map((c) => c.nom)
              .toList();
          expect(noms.first, 'corps_${g.name}');
          expect(noms, containsAll(['bas_${g.name}', 'haut_${g.name}', 'chaussures', 'visage', 'sourcils']));
          expect(noms.where((n) => n.startsWith('cheveux_${h.name}')), hasLength(1), reason: '$g $h');
        }
      }
    });

    test('chaque feuille citée existe, avec 8 angles de la bonne taille', () {
      expect(manifeste.angles, 8);
      for (final fichier in (json['couches'] as Map).values) {
        final f = File('assets/avatar/$fichier');
        expect(f.existsSync(), isTrue, reason: '$fichier');
        // En-tête PNG : largeur et hauteur sur 4 octets chacun à partir du 16e.
        final o = f.readAsBytesSync();
        int entier(int i) => (o[i] << 24) | (o[i + 1] << 16) | (o[i + 2] << 8) | o[i + 3];
        expect(entier(16), manifeste.largeur * manifeste.angles, reason: '$fichier largeur');
        expect(entier(20), manifeste.hauteur, reason: '$fichier hauteur');
      }
    });

    test('les coiffures longues suivent la silhouette (elles tombent sur les épaules)', () {
      String cheveux(CharacterGender g) => manifeste
          .couches(CharacterAppearance(gender: g, hairStyle: HairStyle.long), const TenueAvatar())
          .firstWhere((c) => c.nom.startsWith('cheveux_'))
          .nom;
      expect(cheveux(CharacterGender.male), 'cheveux_long_male');
      expect(cheveux(CharacterGender.female), 'cheveux_long_female');
    });

    test('teintes : peau, cheveux et sourcils suivent l\'apparence, le visage n\'est pas teinté', () {
      const a = CharacterAppearance(skinTone: SkinTone.dark, hairColor: Color(0xFF8B008B));
      final c = {for (final x in manifeste.couches(a, const TenueAvatar())) x.nom: x.teinte};
      expect(c['corps_male'], SkinTone.dark.color);
      expect(c['cheveux_medium'], const Color(0xFF8B008B));
      expect(c['sourcils'], const Color(0xFF8B008B));
      expect(c['visage'], isNull);
    });

    test('la tenue vient des cosmétiques équipés, le chapeau se pose en dernier', () {
      final equipes = {
        'outfit': _cosmetique('haut', couleur: 0xFFAA0000),
        'hat': _cosmetique('chapeau', couleur: 0xFF00AA00, style: 2),
      };
      final couches = manifeste.couches(const CharacterAppearance(), TenueAvatar.depuisCosmetiques((e) => equipes[e]));
      expect(couches.firstWhere((c) => c.nom == 'haut_male').teinte, const Color(0xFFAA0000));
      expect(couches.last.nom, 'chapeau_2');
      expect(couches.last.teinte, const Color(0xFF00AA00));
      expect(manifeste.couches(const CharacterAppearance(), const TenueAvatar()).any((c) => c.nom.startsWith('chapeau')),
          isFalse);
    });
  });

  testWidgets('personnage entier en 1 : 2, buste carré, annoncé aux lecteurs d\'écran', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        AvatarJoueur(apparence: CharacterAppearance(), hauteur: 200),
        AvatarJoueur(
            apparence: CharacterAppearance(), hauteur: 60, cadrage: CadrageAvatar.buste, semanticLabel: null),
      ]),
    ));
    expect(find.bySemanticsLabel('Ton personnage'), findsOneWidget);
    expect(tester.getSize(find.byType(AvatarJoueur).first), const Size(100, 200));
    expect(tester.getSize(find.byType(AvatarJoueur).last), const Size(60, 60));
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
