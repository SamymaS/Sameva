/// Tests de lifecycle auth pour InventoryViewModel — Phase P1.
///
/// Ce que prouvent ces tests :
/// 1. onSignedOut → reset() : l'inventaire est vidé + clé Hive purgée.
/// 2. onSignedIn  → loadInventory() : l'inventaire est rechargé automatiquement.
/// 3. Garde idempotente : si des items sont déjà en mémoire, onSignedIn ne recharge pas.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

Item _item({String id = 'item-1'}) => Item(
      id: id,
      name: 'Objet test lifecycle',
      description: 'd',
      type: ItemType.weapon,
      rarity: QuestRarity.common,
      iconCodePoint: 0,
      goldValue: 10,
    );

void main() {
  late _MockBox box;

  setUp(() {
    box = _MockBox();
    when(() => box.put(any(), any())).thenAnswer((_) async {});
    when(() => box.delete(any())).thenAnswer((_) async {});
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedOut → reset()
  // ────────────────────────────────────────────────────────────────────────────

  group('InventoryViewModel.onSignedOut → reset()', () {
    test('vide les items en mémoire et purge la clé Hive', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);

      // Boîte avec un item stocké.
      when(() => box.get('items')).thenReturn([_item().toJson()]);

      final vm = InventoryViewModel(box, onSignedOut: signedOutCtrl.stream);
      vm.loadInventory();
      expect(vm.items, isNotEmpty, reason: 'Précondition : inventaire chargé');

      // Émettre onSignedOut → reset() (async, mais la notification est synchrone).
      signedOutCtrl.add(null);
      // reset() contient await box.delete(...) → laisser les microtasks s'exécuter.
      await Future<void>.delayed(Duration.zero);

      expect(vm.items, isEmpty,
          reason: 'onSignedOut doit vider l\'inventaire en mémoire');
      verify(() => box.delete('items')).called(greaterThanOrEqualTo(1));

      await signedOutCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedIn → loadInventory()
  // ────────────────────────────────────────────────────────────────────────────

  group('InventoryViewModel.onSignedIn → loadInventory()', () {
    test('recharge l\'inventaire depuis Hive après réception du signal', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      // Boîte vide au départ puis avec un item (simulant un sign-in sur un compte existant).
      when(() => box.get('items')).thenReturn([_item().toJson()]);

      final vm = InventoryViewModel(box, onSignedIn: signedInCtrl.stream);

      // Précondition : inventaire vide (pas de loadInventory() au boot dans ce test).
      expect(vm.items, isEmpty);

      signedInCtrl.add(null);
      // loadInventory() est synchrone (box.get). Pas de delay nécessaire.

      expect(vm.items, isNotEmpty,
          reason: 'onSignedIn doit charger l\'inventaire depuis Hive');

      await signedInCtrl.close();
      vm.dispose();
    });

    test('garde idempotente : ne recharge pas si des items sont déjà en mémoire',
        () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      when(() => box.get('items')).thenReturn([_item().toJson()]);

      final vm = InventoryViewModel(box, onSignedIn: signedInCtrl.stream);

      // Chargement manuel préalable (simule le boot ..loadInventory()).
      vm.loadInventory();
      expect(vm.items, isNotEmpty, reason: 'Précondition : items déjà en mémoire');

      // Réinitialiser les interactions sur la box.
      clearInteractions(box);
      when(() => box.get('items')).thenReturn([_item().toJson()]);

      // onSignedIn → garde _items.isNotEmpty → no-op.
      signedInCtrl.add(null);

      // box.get ne doit PAS avoir été rappelé.
      verifyNever(() => box.get('items'));

      await signedInCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Cycle complet : onSignedOut puis onSignedIn
  // ────────────────────────────────────────────────────────────────────────────

  group('InventoryViewModel — cycle signOut puis signIn', () {
    test('vide puis recharge correctement', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      when(() => box.get('items')).thenReturn([_item().toJson()]);

      final vm = InventoryViewModel(
        box,
        onSignedOut: signedOutCtrl.stream,
        onSignedIn: signedInCtrl.stream,
      );

      vm.loadInventory();
      expect(vm.items, isNotEmpty, reason: 'Chargement initial');

      // Logout.
      signedOutCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(vm.items, isEmpty, reason: 'Inventaire vide après onSignedOut');

      // Reconnexion.
      signedInCtrl.add(null);
      expect(vm.items, isNotEmpty,
          reason: 'Inventaire rechargé après onSignedIn');

      await signedOutCtrl.close();
      await signedInCtrl.close();
      vm.dispose();
    });
  });
}
