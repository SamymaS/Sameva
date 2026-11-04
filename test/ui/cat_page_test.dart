import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/cat_model.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/ui/pages/cat/cat_page.dart';

class _MockBox extends Mock implements Box<dynamic> {}
class _MockPlayerRepository extends Mock implements PlayerRepository {}

Box<dynamic> _boiteVide() {
  final box = _MockBox();
  when(() => box.get(any())).thenReturn(null);
  when(() => box.get(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(null);
  when(() => box.put(any(), any())).thenAnswer((_) async {});
  return box;
}

Widget _app(CatViewModel catVm) {
  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
  when(() => playerRepo.fetchServerState()).thenAnswer((_) async => throw Exception('hors-ligne'));
  when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CatViewModel>.value(value: catVm),
      ChangeNotifierProvider<InventoryViewModel>.value(value: InventoryViewModel(_boiteVide())),
      ChangeNotifierProvider<PlayerViewModel>.value(value: PlayerViewModel(playerRepo)),
    ],
    child: const MaterialApp(home: CatPage()),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    final dir = await Directory.systemTemp.createTemp('hive_cat_page_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  testWidgets('sans chat : état vide pixel', (tester) async {
    await tester.pumpWidget(_app(CatViewModel(_boiteVide(), testUserId: 'u1')));
    await tester.pump();
    expect(find.text('Pas encore de chat compagnon'), findsOneWidget);
  });

  testWidgets('chat principal : socle, caresse, emplacements et renommage', (tester) async {
    final box = _MockBox();
    final chat = CatStats(id: 'c1', name: 'Mochi', race: 'lune', rarity: 'rare', isMain: true, obtainedAt: DateTime(2026, 11, 1));
    when(() => box.get('cats_list_u1')).thenReturn([chat.toJson()]);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
    final vm = CatViewModel(box, testUserId: 'u1');
    await vm.loadCats();

    await tester.binding.setSurfaceSize(const Size(412, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    expect(find.text('Mon chat'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
    expect(find.text('Lune · Mystérieux'), findsOneWidget);
    expect(find.text('Rare'), findsOneWidget);
    expect(find.bySemanticsLabel('Caresser (+5 % de moral)'), findsOneWidget);
    expect(find.bySemanticsLabel('Chapeau : vide'), findsOneWidget);
    expect(find.bySemanticsLabel('Tenue : vide'), findsOneWidget);
    expect(find.bySemanticsLabel('Aura : vide'), findsOneWidget);

    // Emplacement sans objet : la feuille invite à en obtenir.
    await tester.tap(find.bySemanticsLabel('Chapeau : vide'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun cosmétique disponible'), findsOneWidget);
    Navigator.of(tester.element(find.textContaining('Aucun cosmétique'))).pop();
    await tester.pumpAndSettle();

    // Renommer.
    await tester.tap(find.byTooltip('Renommer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pixel');
    await tester.tap(find.bySemanticsLabel('Renommer').last);
    await tester.pumpAndSettle();
    expect(find.text('Pixel'), findsOneWidget);
  });
}
