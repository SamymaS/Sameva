import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/ui/pages/invocation/sequence_invocation.dart';
import 'package:sameva/ui/widgets/pixel/pixel_ui.dart';

Item _objet(String nom, QuestRarity r) => Item(
      id: nom,
      name: nom,
      description: 'Description de $nom',
      type: ItemType.potion,
      rarity: r,
      iconCodePoint: Icons.star.codePoint,
      goldValue: 10,
      assetPath: 'assets/items/potion_heal.svg',
    );

/// Ouvre la séquence depuis un bouton, comme la page d'invocation.
Future<void> _ouvrir(WidgetTester tester, List<Item> objets, {bool sansAnimation = false}) async {
  await tester.pumpWidget(MaterialApp(
    // MediaQuery au-dessus du navigateur : la séquence est poussée à la racine.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: sansAnimation),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => SequenceInvocation.afficher(ctx,
              objets: objets, remboursement: 0, epiqueDans: 7, legendaireDans: 41),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('ouvrir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  group('règles de la séquence', () {
    test('le meilleur objet est révélé en dernier, le reste garde son ordre', () {
      final a = _objet('a', QuestRarity.common);
      final b = _objet('b', QuestRarity.legendary);
      final c = _objet('c', QuestRarity.rare);
      expect(ordreRevelation([a, b, c]).map((o) => o.id), ['a', 'c', 'b']);
      expect(ordreRevelation([a]).single.id, 'a');
    });

    test('la colonne de lumière ne trahit pas les raretés modestes', () {
      expect(couleurColonne(QuestRarity.common), couleurColonne(QuestRarity.uncommon));
      expect(couleurColonne(QuestRarity.legendary), PixelCouleurs.or);
      expect(couleurColonne(QuestRarity.epic), isNot(couleurColonne(QuestRarity.common)));
    });

    test('parPaliers saute de palier en palier', () {
      expect(parPaliers(0.49, 4), 0.25);
      expect(parPaliers(1, 4), 1);
      expect(parPaliers(-1, 4), 0);
    });
  });

  testWidgets('un objet : charge, « Passer », révélation puis retour', (tester) async {
    await _ouvrir(tester, [_objet('Épée Légendaire', QuestRarity.legendary)]);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Épée Légendaire'), findsNothing);

    await tester.tap(find.text('Passer'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('LÉGENDAIRE'), findsOneWidget);
    expect(find.text('Épée Légendaire'), findsOneWidget);
    expect(find.text('Légendaire dans 41'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(SequenceInvocation), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
  });

  testWidgets('la charge passe seule à la révélation', (tester) async {
    await _ouvrir(tester, [_objet('Potion', QuestRarity.common)]);
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('COMMUN'), findsOneWidget);
  });

  testWidgets('dix objets : cartes retournées, « Tout révéler » puis « Continuer »', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final objets = [
      for (var i = 0; i < 9; i++) _objet('o$i', QuestRarity.common),
      _objet('Couronne', QuestRarity.legendary),
    ];
    await _ouvrir(tester, objets);
    await tester.tap(find.text('Passer'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('10 invocations'), findsOneWidget);
    expect(find.text('Tout révéler'), findsOneWidget);
    expect(find.bySemanticsLabel('Couronne, Légendaire'), findsNothing);

    await tester.tap(find.text('Tout révéler'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.bySemanticsLabel('Couronne, Légendaire'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('« réduire les animations » saute directement à la révélation', (tester) async {
    await _ouvrir(tester, [_objet('Potion', QuestRarity.rare)], sansAnimation: true);
    expect(find.text('Passer'), findsNothing);
    expect(find.text('RARE'), findsOneWidget);
  });
}
