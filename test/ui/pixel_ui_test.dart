import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/ui/pages/invocation/portail_repos.dart';
import 'package:sameva/ui/widgets/pixel/pixel_ui.dart';

Widget _cadre(Widget enfant) =>
    MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 200, child: enfant))));

void main() {
  // Régression : une boîte de couleur sans enfant dans une Stack ou une Row
  // recevait une hauteur nulle (remplissage invisible sur la capture du banc).
  testWidgets('PixelBarreSeuil : remplissage et repère visibles, à la bonne place', (tester) async {
    await tester.pumpWidget(_cadre(const PixelBarreSeuil(valeur: .9, seuil: .7, couleur: Colors.green)));
    final rempli = tester.getSize(find.byKey(const ValueKey('remplissage')));
    expect(rempli.width, closeTo(180, .01));
    expect(rempli.height, 12);
    final seuil = tester.getTopLeft(find.byKey(const ValueKey('seuil')));
    final origine = tester.getTopLeft(find.byType(PixelBarreSeuil));
    expect(seuil.dx - origine.dx, closeTo(140 - 1.5, .01));
  });

  testWidgets('JaugeGarantie en cases : les cases ont une hauteur', (tester) async {
    await tester.pumpWidget(_cadre(
        const JaugeGarantie(libelle: 'Épique garanti', actuel: 3, seuil: 20, couleur: Colors.purple)));
    final cases = find.descendant(of: find.byType(Row).last, matching: find.byType(ColoredBox));
    expect(cases, findsNWidgets(20));
    expect(tester.getSize(cases.first).height, 10);
  });

  // Régression : dans une boîte de dialogue, le bouton fusionnait avec le texte
  // voisin (« Titre Récupérer ») et n'était plus trouvable par son nom.
  testWidgets('PixelBouton garde son propre nœud sémantique dans une boîte de dialogue', (tester) async {
    final semantique = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () => showDialog<void>(
              context: c,
              builder: (_) => Dialog(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Titre'),
                  PixelBouton(libelle: 'Récupérer', onPressed: () {}),
                ]),
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Récupérer'), findsOneWidget);
    expect(tester.getSemantics(find.byType(PixelBouton)).label, 'Récupérer');
    semantique.dispose();
  });
}
