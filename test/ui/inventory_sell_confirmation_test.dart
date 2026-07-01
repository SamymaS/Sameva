/// Tests : vente unitaire avec confirmation (Correction 2)
///
/// Prouve que :
/// 1. Taper « Vendre » sur la fiche item ouvre d'abord un AlertDialog.
/// 2. removeItem/addGold NE sont PAS appelés si l'utilisateur tape « Annuler ».
/// 3. removeItem/addGold SONT appelés après confirmation (tap « Vendre » dans le dialog).
import 'dart:io';

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

// ── Mocks ─────────────────────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockBox extends Mock implements Box<dynamic> {}
class _MockUser extends Mock implements User {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Item de test non verrouillé, goldValue = 100 → prix de vente = 50 or.
Item _makeUnlockedItem() => Item(
      id: 'item-sell-test',
      name: 'Épée de confirmation',
      description: 'Arme utilisée pour tester la confirmation de vente',
      type: ItemType.weapon,
      rarity: QuestRarity.rare,
      iconCodePoint: Icons.abc.codePoint,
      goldValue: 100,
      isLocked: false,
    );

/// Construit la page Inventaire en injectant des VMs pré-configurés
/// afin que les tests puissent inspecter leur état après action.
Widget _buildPage({
  required InventoryViewModel invVm,
  required PlayerViewModel playerVm,
  required EquipmentViewModel eqVm,
  required CatViewModel catVm,
  required AuthViewModel authVm,
}) {
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

/// Fabrique les VMs nécessaires avec des dépendances mockées.
/// Retourne les instances pour permettre les assertions d'état.
({
  InventoryViewModel invVm,
  PlayerViewModel playerVm,
  EquipmentViewModel eqVm,
  CatViewModel catVm,
  AuthViewModel authVm,
}) _makeVms() {
  // Auth
  final authRepo = _MockAuthRepository();
  final mockUser = _MockUser();
  when(() => mockUser.id).thenReturn('u1');
  when(() => mockUser.email).thenReturn('test@sameva.app');
  when(() => authRepo.currentUser).thenReturn(mockUser);
  when(() => authRepo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  final authVm = AuthViewModel(authRepo);

  // Player
  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats(gold: 0));
  when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});
  final playerVm = PlayerViewModel(playerRepo);

  // Inventory — box mockée : les puts sont fire-and-forget, pas de vrai I/O Hive
  final invBox = _MockBox();
  when(() => invBox.get(any())).thenReturn(null);
  when(() => invBox.put(any(), any())).thenAnswer((_) async {});
  when(() => invBox.delete(any())).thenAnswer((_) async {});
  final invVm = InventoryViewModel(invBox);

  // Equipment
  final eqBox = _MockBox();
  when(() => eqBox.get(any())).thenReturn(null);
  when(() => eqBox.put(any(), any())).thenAnswer((_) async {});
  final eqVm = EquipmentViewModel(eqBox);

  // Cat
  final catBox = _MockBox();
  when(() => catBox.get(any())).thenReturn(null);
  when(() => catBox.put(any(), any())).thenAnswer((_) async {});
  final catVm = CatViewModel(catBox);

  return (
    invVm: invVm,
    playerVm: playerVm,
    eqVm: eqVm,
    catVm: catVm,
    authVm: authVm,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    // Hive requis par HealthRegenerationService (accès à 'settings')
    final dir = await Directory.systemTemp
        .createTemp('hive_sell_confirmation_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
    await Hive.openBox('inventory');
  });

  // Pas de tearDownAll : Hive.close() bloque le runner de tests.

  group('InventoryPage — vente unitaire avec confirmation', () {
    testWidgets(
        'tapper Vendre ouvre un dialog de confirmation (AlertDialog visible)',
        (tester) async {
      final vms = _makeVms();
      final item = _makeUnlockedItem();
      vms.invVm.addItem(item);

      await tester.pumpWidget(_buildPage(
        invVm: vms.invVm,
        playerVm: vms.playerVm,
        eqVm: vms.eqVm,
        catVm: vms.catVm,
        authVm: vms.authVm,
      ));
      await tester.pump();

      // Ouvre la fiche détail de l'item
      await tester.tap(find.text('Épée de confirmation'));
      await tester.pumpAndSettle();

      // Tape le bouton « Vendre » de la fiche
      await tester.tap(find.text('Vendre'));
      await tester.pump();
      await tester.pump();

      // Le dialog de confirmation doit être visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Vendre cet objet'), findsOneWidget);
      // Le prix affiché dans le dialog doit être 50 or (50% de goldValue=100)
      // Note : "50 or" apparaît aussi dans la fiche — on cible le dialog précisément.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('50 or'),
        ),
        findsOneWidget,
      );

      // L'item est TOUJOURS dans l'inventaire (removeItem pas encore appelé)
      expect(vms.invVm.items.length, 1);

      // Dispose — le dialog est encore ouvert, on ferme proprement
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'tapper Annuler ferme le dialog sans retirer l\'item de l\'inventaire',
        (tester) async {
      final vms = _makeVms();
      final item = _makeUnlockedItem();
      vms.invVm.addItem(item);

      await tester.pumpWidget(_buildPage(
        invVm: vms.invVm,
        playerVm: vms.playerVm,
        eqVm: vms.eqVm,
        catVm: vms.catVm,
        authVm: vms.authVm,
      ));
      await tester.pump();

      // Ouvre la fiche
      await tester.tap(find.text('Épée de confirmation'));
      await tester.pumpAndSettle();

      // Ouvre le dialog de confirmation
      await tester.tap(find.text('Vendre'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tape « Annuler »
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle(); // le dialog se ferme, aucune notification

      // Le dialog est fermé
      expect(find.byType(AlertDialog), findsNothing);
      // L'item est TOUJOURS présent : removeItem n'a PAS été appelé
      expect(vms.invVm.items.length, 1);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'confirmer Vendre retire l\'item et ajoute l\'or au joueur',
        (tester) async {
      final vms = _makeVms();
      final item = _makeUnlockedItem(); // goldValue=100, prix de vente=50
      vms.invVm.addItem(item);

      // Initialise les stats joueur (gold = 0) dans la zone réelle pour éviter
      // le deadlock FakeAsync+Hive (HealthRegenerationService.computeRegen
      // fait un box.put fire-and-forget via _updateTimestamp).
      await tester.runAsync(() => vms.playerVm.loadPlayerStats('u1'));
      expect(vms.playerVm.stats?.gold, 0); // précondition

      await tester.pumpWidget(_buildPage(
        invVm: vms.invVm,
        playerVm: vms.playerVm,
        eqVm: vms.eqVm,
        catVm: vms.catVm,
        authVm: vms.authVm,
      ));
      await tester.pump();

      // Ouvre la fiche
      await tester.tap(find.text('Épée de confirmation'));
      await tester.pumpAndSettle();

      // Ouvre le dialog de confirmation
      await tester.tap(find.text('Vendre'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(vms.invVm.items.length, 1); // item encore présent

      // Confirme la vente via le bouton « Vendre » du dialog
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Vendre'),
      ));
      // pump x2 : frame 1 = le dialog ferme ; frame 2 = la continuation async
      // s'exécute (removeItem, addGold, Navigator.pop, AppNotification.show)
      await tester.pump();
      await tester.pump();

      // removeItem a été appelé : inventaire vide
      expect(vms.invVm.items.isEmpty, isTrue);

      // addGold a été appelé : les 50 premiers synchrones sont déjà appliqués
      // (addGold modifie _stats synchronement avant le premier await interne)
      expect(vms.playerVm.stats?.gold, 50);

      // Avance l'horloge pour consommer le timer de la notification (3 s)
      // et laisser l'animation de sortie se terminer (300 ms).
      // Évite le warning « timer still active » en fin de test.
      await tester.pump(const Duration(seconds: 4));

      // Dispose
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets(
        'l\'item verrouillé n\'a pas de bouton Vendre (bouton désactivé)',
        (tester) async {
      // Régression : s'assure que l'ajout du dialog ne casse pas la logique de verrouillage.
      final vms = _makeVms();
      final lockedItem = Item(
        id: 'item-locked',
        name: 'Épée de confirmation',
        description: 'Verrouillée',
        type: ItemType.weapon,
        rarity: QuestRarity.rare,
        iconCodePoint: Icons.abc.codePoint,
        goldValue: 100,
        isLocked: true,
      );
      vms.invVm.addItem(lockedItem);

      await tester.pumpWidget(_buildPage(
        invVm: vms.invVm,
        playerVm: vms.playerVm,
        eqVm: vms.eqVm,
        catVm: vms.catVm,
        authVm: vms.authVm,
      ));
      await tester.pump();

      await tester.tap(find.text('Épée de confirmation'));
      await tester.pumpAndSettle();

      // Le libellé doit être « Verrouillé » (onTap null → pas d'interaction)
      expect(find.text('Verrouillé'), findsOneWidget);
      expect(find.text('Vendre'), findsNothing);

      // Taper sur « Verrouillé » ne déclenche aucune action ni dialog
      await tester.tap(find.text('Verrouillé'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(vms.invVm.items.length, 1); // item toujours présent

      await tester.pumpWidget(const SizedBox());
    });
  });
}
