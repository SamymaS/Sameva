import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/audio/sons.dart';
import 'package:sameva/ui/widgets/cat/cat_widget.dart';
import 'package:sameva/ui/widgets/pixel/pixel_sprite.dart';

void main() {
  group('AnimationPixel', () {
    const a = AnimationPixel([0, 1, 2], [100, 50, 200]);

    test('choisit l\'image selon le temps écoulé', () {
      expect(a.imageA(0), 0);
      expect(a.imageA(99), 0);
      expect(a.imageA(100), 1);
      expect(a.imageA(160), 2);
    });

    test('boucle', () => expect(a.imageA(350 + 120), 1));

    test('égalité par valeur (pas de redémarrage à chaque build)', () {
      expect(const AnimationPixel([0, 1], [10, 20]), AnimationPixel([0, 1], List.of([10, 20])));
      expect(const AnimationPixel([0, 1], [10, 20]) == const AnimationPixel([0, 2], [10, 20]), isFalse);
    });

    test('sans boucle, reste sur la dernière image', () {
      const b = AnimationPixel([4, 5], [100, 100], boucle: false);
      expect(b.imageA(5000), 5);
    });
  });

  test('chaque humeur du chat a son animation', () {
    expect(animationPourHumeur('cat_idle'), 'repos');
    expect(animationPourHumeur('happy'), 'content');
    expect(animationPourHumeur('cat_excited'), 'excite');
    expect(animationPourHumeur('sad'), 'triste');
    expect(animationPourHumeur('cat_sleepy'), 'endormi');
  });

  test('le son d\'invocation suit la rareté', () {
    expect(Sons.invocationPour('common'), Son.invocationCommune);
    expect(Sons.invocationPour('epic'), Son.invocationRare);
    expect(Sons.invocationPour('legendary'), Son.invocationLegendaire);
    expect(Sons.invocationPour('mythic'), Son.invocationLegendaire);
  });

  testWidgets('le manifeste réel décrit toutes les animations utilisées', (t) async {
    final m = await ManifestePixel.charger();
    for (final nom in ['repos', 'content', 'excite', 'triste', 'endormi']) {
      expect(m.animation('chat', nom).images, isNotEmpty, reason: nom);
    }
    for (final nom in ['repos', 'observe', 'accepte', 'refuse']) {
      expect(m.animation('mougibot', nom).images, isNotEmpty, reason: nom);
    }
    for (final chapeau in ['wizard_hat', 'crown', 'bow', 'party_hat', 'santa_hat']) {
      expect(m.chapeau(chapeau), isNotNull, reason: chapeau);
    }
    expect(m.taille('chat'), 96);
    expect(m.taille('mougibot'), 96);
  });

  testWidgets('changer d\'animation ne casse pas le sprite (plusieurs tickers)', (t) async {
    Widget sprite(AnimationPixel a) => Directionality(
          textDirection: TextDirection.ltr,
          child: PixelSprite(feuille: 'assets/sprites/chat_michi.png', animation: a, cote: 64),
        );
    await t.pumpWidget(sprite(const AnimationPixel([0, 1], [100, 100])));
    await t.pump(const Duration(milliseconds: 150));
    // Même animation recréée : rien ne redémarre.
    await t.pumpWidget(sprite(const AnimationPixel([0, 1], [100, 100])));
    // Nouvelle animation : un second ticker est créé.
    await t.pumpWidget(sprite(const AnimationPixel([5, 6], [160, 160])));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
  });
}
