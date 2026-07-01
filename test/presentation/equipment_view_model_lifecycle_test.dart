/// Tests de lifecycle auth pour EquipmentViewModel — Phase P1.
///
/// Ce que prouvent ces tests :
/// 1. onSignedOut → reset() : tous les slots vidés + clés Hive purgées + _loaded = false.
/// 2. onSignedIn  → loadEquipment() : équipement rechargé automatiquement.
/// 3. Garde [_loaded] : si loadEquipment() a déjà été appelé, onSignedIn est no-op.
/// 4. Cycle complet : reset (_loaded=false) puis onSignedIn → rechargement.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/item_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/presentation/view_models/equipment_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

Item _weapon({String id = 'sw-1'}) => Item(
      id: id,
      name: 'Épée lifecycle',
      description: 'd',
      type: ItemType.weapon,
      rarity: QuestRarity.common,
      iconCodePoint: 1,
      stats: const {'xpBonus': 5},
      goldValue: 50,
    );

void main() {
  late _MockBox equipBox;
  late _MockBox invBox;

  setUp(() {
    equipBox = _MockBox();
    invBox = _MockBox();
    when(() => equipBox.put(any(), any())).thenAnswer((_) async {});
    when(() => equipBox.delete(any())).thenAnswer((_) async {});
    when(() => invBox.put(any(), any())).thenAnswer((_) async {});
    when(() => invBox.get('items')).thenReturn(null);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedOut → reset()
  // ────────────────────────────────────────────────────────────────────────────

  group('EquipmentViewModel.onSignedOut → reset()', () {
    test('vide tous les slots et purge les clés Hive', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);

      // Boîte avec une arme équipée.
      final w = _weapon();
      when(() => equipBox.get('equipment'))
          .thenReturn({'weapon': w.toJson()});
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      final vm = EquipmentViewModel(equipBox, onSignedOut: signedOutCtrl.stream);
      vm.loadEquipment();
      expect(vm.getSlot(EquipmentSlot.weapon), isNotNull,
          reason: 'Précondition : arme équipée');

      signedOutCtrl.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(vm.getSlot(EquipmentSlot.weapon), isNull,
          reason: 'onSignedOut doit vider les slots');
      verify(() => equipBox.delete('equipment')).called(greaterThanOrEqualTo(1));
      verify(() => equipBox.delete('cosmetics')).called(greaterThanOrEqualTo(1));

      await signedOutCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedIn → loadEquipment()
  // ────────────────────────────────────────────────────────────────────────────

  group('EquipmentViewModel.onSignedIn → loadEquipment()', () {
    test('charge l\'équipement depuis Hive après réception du signal', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      final w = _weapon();
      when(() => equipBox.get('equipment'))
          .thenReturn({'weapon': w.toJson()});
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      // VM sans loadEquipment() préalable → _loaded == false.
      final vm = EquipmentViewModel(equipBox, onSignedIn: signedInCtrl.stream);
      expect(vm.getSlot(EquipmentSlot.weapon), isNull,
          reason: 'Précondition : slot vide avant onSignedIn');

      signedInCtrl.add(null);
      // loadEquipment() est synchrone.

      expect(vm.getSlot(EquipmentSlot.weapon), isNotNull,
          reason: 'onSignedIn doit charger l\'équipement depuis Hive');
      expect(vm.getSlot(EquipmentSlot.weapon)?.id, w.id);

      await signedInCtrl.close();
      vm.dispose();
    });

    test('garde _loaded : ne recharge pas si loadEquipment() a déjà été appelé',
        () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      // Boîte vide au départ.
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      final vm = EquipmentViewModel(equipBox, onSignedIn: signedInCtrl.stream);

      // Appel manuel de loadEquipment() → _loaded = true.
      vm.loadEquipment();

      // Réinitialiser le stub pour détecter un éventuel double appel.
      clearInteractions(equipBox);
      when(() => equipBox.get('equipment')).thenReturn(null);
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      // onSignedIn → _loaded == true → no-op.
      signedInCtrl.add(null);

      // box.get ne doit PAS avoir été rappelé.
      verifyNever(() => equipBox.get('equipment'));

      await signedInCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Cycle complet : onSignedOut (_loaded=false) puis onSignedIn (rechargement)
  // ────────────────────────────────────────────────────────────────────────────

  group('EquipmentViewModel — cycle signOut puis signIn', () {
    test('reset() remet _loaded=false, puis onSignedIn recharge', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      final w = _weapon();
      when(() => equipBox.get('equipment'))
          .thenReturn({'weapon': w.toJson()});
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      final vm = EquipmentViewModel(
        equipBox,
        onSignedOut: signedOutCtrl.stream,
        onSignedIn: signedInCtrl.stream,
      );

      // Chargement initial → _loaded = true.
      vm.loadEquipment();
      expect(vm.getSlot(EquipmentSlot.weapon), isNotNull,
          reason: 'Précondition : arme chargée');

      // Logout → reset() → _loaded = false.
      signedOutCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(vm.getSlot(EquipmentSlot.weapon), isNull,
          reason: 'Slots vidés après onSignedOut');

      // Reconnexion → _loaded == false → loadEquipment() déclenché.
      signedInCtrl.add(null);
      expect(vm.getSlot(EquipmentSlot.weapon), isNotNull,
          reason: 'Équipement rechargé après onSignedIn');

      await signedOutCtrl.close();
      await signedInCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Bonus : xpBonusPercent après rechargement via onSignedIn
  // ────────────────────────────────────────────────────────────────────────────

  group('EquipmentViewModel.onSignedIn — stat xpBonusPercent recalculée', () {
    test('xpBonusPercent reflète l\'item chargé via onSignedIn', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      final w = _weapon(); // stats: {'xpBonus': 5}
      when(() => equipBox.get('equipment'))
          .thenReturn({'weapon': w.toJson()});
      when(() => equipBox.get('cosmetics')).thenReturn(null);

      final vm = EquipmentViewModel(equipBox, onSignedIn: signedInCtrl.stream);
      expect(vm.xpBonusPercent, 0, reason: 'Précondition : pas de bonus avant load');

      signedInCtrl.add(null);

      expect(vm.xpBonusPercent, 5,
          reason: 'xpBonusPercent doit refléter l\'item chargé via onSignedIn');

      await signedInCtrl.close();
      vm.dispose();
    });
  });
}
