import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sameva/core/router/app_router.dart';

Widget _ecran(String nom) => Builder(
      builder: (context) => Scaffold(
        body: Column(children: [
          Text(nom),
          TextButton(onPressed: () => quitterEcran(context), child: const Text('quitter')),
          TextButton(onPressed: () => context.push('/detail'), child: const Text('ouvrir')),
        ]),
      ),
    );

GoRouter _routeur(String depart) => GoRouter(initialLocation: depart, routes: [
      GoRoute(path: Routes.quetes, builder: (_, __) => _ecran('liste')),
      GoRoute(path: '/detail', builder: (_, __) => _ecran('detail')),
    ]);

void main() {
  testWidgets('ouvert par un lien profond : retombe sur la liste, pas sur un écran noir', (t) async {
    final r = _routeur('/detail');
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    expect(find.text('detail'), findsOneWidget);
    await t.tap(find.text('quitter'));
    await t.pumpAndSettle();
    expect(find.text('liste'), findsOneWidget);
  });

  testWidgets('ouvert normalement : simple retour', (t) async {
    final r = _routeur(Routes.quetes);
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    await t.tap(find.text('quitter'));
    await t.pumpAndSettle();
    expect(find.text('liste'), findsOneWidget);
    expect(r.canPop(), isFalse);
  });
}
