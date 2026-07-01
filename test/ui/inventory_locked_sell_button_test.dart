import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';
import 'package:sameva/presentation/view_models/equipment_view_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/ui/pages/inventory/inventory_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockBox extends Mock implements Box<dynamic> {}
class _MockUser extends Mock implements User {}

/// Construit la page Inventaire avec un item verrouillé dans la grille.
Widget _buildInventoryPage({required Item item}) {
  final authRepo = _MockAuthRepository();
  final mockUser = _MockUser();
  when(() => mockUser.id).thenReturn('u1');
  when(() => mockUser.email).thenReturn('test@sameva.app');
  when(() => authRepo.currentUser).thenReturn(mockUser);
  when(() => authRepo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  final authVm = AuthViewModel(authRepo);

  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
  when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});
  final playerVm = PlayerViewModel(playerRepo);

  final invBox = _MockBox();
  when(() => invBox.get(any())).thenReturn(null);
  when(() => invBox.put(any(), any())).thenAnswer((_) async {});
  final invVm = InventoryViewModel(invBox);
  invVm.addItem(item);

  final eqBox = _MockBox();
  when(() => eqBox.get(any())).thenReturn(null);
  when(() => eqBox.put(any(), any())).thenAnswer((_) async {});
  final eqVm = EquipmentViewModel(eqBox);

  final catBox = _MockBox();
  when(() => catBox.get(any())).thenReturn(null);
  when(() => catBox.put(any(), any())).thenAnswer((_) async {});
  final catVm = CatViewModel(catBox);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ChangeNotifierProvider<PlayerViewModel>.value(value: playerVm),
      ChangeNotifierProvider<InventoryViewModel>.value(value: invVm),
      ChangeNotifierProvider<EquipmentViewModel>.value(value: eqVm),
      ChangeNotifierProvider<CatViewModel>.value(value: catVm),
    ],
    child: const MaterialApp(home: InventoryPage()),
  );
}

Item _makeItem({bool isLocked = false}) => Item(
      id: 'item-test-1',
      name: 'Épée de test',
      description: 'Une épée pour les tests',
      type: ItemType.weapon,
      rarity: QuestRarity.rare,
      iconCodePoint: Icons.abc.codePoint,
      goldValue: 100,
      isLocked: isLocked,
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    final dir =
        await Directory.systemTemp.createTemp('hive_inventory_locked_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
    await Hive.openBox('inventory');
  });

  group('InventoryPage — bouton Vendre verrouillé', () {
    testWidgets(
        'le bouton Vendre est absent/désactivé quand l\'item est verrouillé',
        (tester) async {
      final lockedItem = _makeItem(isLocked: true);
      await tester.pumpWidget(_buildInventoryPage(item: lockedItem));
      await tester.pump();

      // Tap sur la carte de l'item pour ouvrir le bottom sheet
      await tester.tap(find.text('Épée de test'));
      await tester.pumpAndSettle();

      // Le libellé du bouton vente doit indiquer "Verrouillé"
      expect(find.text('Verrouillé'), findsOneWidget);
      // Le libellé "Vendre" ne doit PAS apparaître quand verrouillé
      expect(find.text('Vendre'), findsNothing);
    });

    testWidgets(
        'taper le bouton Verrouille ne declenche aucune action de vente',
        (tester) async {
      final lockedItem = _makeItem(isLocked: true);

      await tester.pumpWidget(_buildInventoryPage(item: lockedItem));
      await tester.pump();

      // Ouvre le bottom sheet
      await tester.tap(find.text('Épée de test'));
      await tester.pumpAndSettle();

      // S'assure que le bouton "Verrouillé" est présent
      final boutonVerrouille = find.text('Verrouillé');
      expect(boutonVerrouille, findsOneWidget);

      // Tap sur le bouton — il est désactivé (onTap = null sur GestureDetector)
      await tester.tap(boutonVerrouille, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Le sheet est toujours ouvert (aucune action de fermeture déclenchée)
      // La notification "Vendu pour" ne doit pas apparaître
      expect(find.textContaining('Vendu pour'), findsNothing);
    });

    testWidgets('le bouton Vendre est actif quand l\'item n\'est pas verrouillé',
        (tester) async {
      final unlockedItem = _makeItem(isLocked: false);
      await tester.pumpWidget(_buildInventoryPage(item: unlockedItem));
      await tester.pump();

      await tester.tap(find.text('Épée de test'));
      await tester.pumpAndSettle();

      // Le libellé "Vendre" doit apparaître pour un item non verrouillé
      expect(find.text('Vendre'), findsOneWidget);
      expect(find.text('Verrouillé'), findsNothing);
    });
  });
}
