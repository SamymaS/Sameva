/// Tests de lifecycle auth pour QuestViewModel — Phase P1.
///
/// Ce que prouvent ces tests :
/// 1. onSignedOut → clearCache() : les quêtes sont vidées automatiquement.
/// 2. onSignedIn  → loadQuests(uid) : les quêtes sont rechargées automatiquement.
/// 3. Garde idempotente : si les quêtes sont déjà en mémoire, onSignedIn ne recharge pas.
///
/// Pattern : StreamController<void>.broadcast(sync: true) — delivery synchrone,
/// aucun pump/delay nécessaire pour les assertions qui suivent add(null).
/// Pour les handlers async (loadQuests), un await Future<void>.delayed(Duration.zero)
/// suffit à laisser les microtasks s'exécuter.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';

class _MockQuestRepo extends Mock implements QuestRepository {}

const _testUserId = 'uid-lifecycle-quest-1';

Quest _quest({String id = 'q1'}) => Quest(
      id: id,
      userId: _testUserId,
      title: 'Quête lifecycle',
      estimatedDurationMinutes: 30,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: 'sante',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
      createdAt: DateTime(2026, 1, 1),
      // deadline: null → NotificationService non déclenché
    );

void main() {
  late _MockQuestRepo repo;

  setUpAll(() {
    registerFallbackValue(_quest());
  });

  setUp(() {
    repo = _MockQuestRepo();
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedOut → clearCache()
  // ────────────────────────────────────────────────────────────────────────────

  group('QuestViewModel.onSignedOut → clearCache()', () {
    test('vide les quêtes en mémoire à la réception du signal', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);
      when(() => repo.loadQuests(_testUserId)).thenAnswer((_) async => [_quest()]);

      final vm = QuestViewModel(
        repo,
        onSignedOut: signedOutCtrl.stream,
        testUserId: _testUserId,
      );

      // Charger des quêtes pour avoir un cache non vide.
      await vm.loadQuests(_testUserId);
      expect(vm.quests, isNotEmpty, reason: 'Précondition : cache non vide');

      // Émettre onSignedOut — delivery synchrone → clearCache() s'exécute immédiatement.
      signedOutCtrl.add(null);

      expect(vm.quests, isEmpty,
          reason: 'onSignedOut doit vider le cache des quêtes');

      await signedOutCtrl.close();
      vm.dispose();
    });

    test('état isLoading reste false après clearCache', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);
      when(() => repo.loadQuests(_testUserId)).thenAnswer((_) async => [_quest()]);

      final vm = QuestViewModel(
        repo,
        onSignedOut: signedOutCtrl.stream,
        testUserId: _testUserId,
      );
      await vm.loadQuests(_testUserId);

      signedOutCtrl.add(null);

      expect(vm.isLoading, isFalse);

      await signedOutCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // onSignedIn → loadQuests(uid)
  // ────────────────────────────────────────────────────────────────────────────

  group('QuestViewModel.onSignedIn → loadQuests(uid)', () {
    test('recharge les quêtes après réception du signal', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);
      when(() => repo.loadQuests(_testUserId))
          .thenAnswer((_) async => [_quest()]);

      final vm = QuestViewModel(
        repo,
        onSignedIn: signedInCtrl.stream,
        testUserId: _testUserId,
      );

      // Précondition : cache vide au départ.
      expect(vm.quests, isEmpty);

      signedInCtrl.add(null);
      // Laisser le handler async (loadQuests) s'exécuter.
      await Future<void>.delayed(Duration.zero);

      expect(vm.quests, isNotEmpty,
          reason: 'onSignedIn doit déclencher loadQuests et remplir le cache');
      verify(() => repo.loadQuests(_testUserId)).called(1);

      await signedInCtrl.close();
      vm.dispose();
    });

    test('garde idempotente : ne recharge pas si le cache est déjà non vide', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);
      when(() => repo.loadQuests(_testUserId))
          .thenAnswer((_) async => [_quest()]);

      final vm = QuestViewModel(
        repo,
        onSignedIn: signedInCtrl.stream,
        testUserId: _testUserId,
      );

      // Charger manuellement (simule SanctuaryPage._load()).
      await vm.loadQuests(_testUserId);
      expect(vm.quests, isNotEmpty, reason: 'Précondition : cache non vide');

      // Émettre onSignedIn : la garde _quests.isNotEmpty doit bloquer le rechargement.
      signedInCtrl.add(null);
      await Future<void>.delayed(Duration.zero);

      // loadQuests doit avoir été appelé UNE seule fois (le premier appel manuel).
      verify(() => repo.loadQuests(_testUserId)).called(1);

      await signedInCtrl.close();
      vm.dispose();
    });

    test('uid null dans testUserId → onSignedIn ne charge rien', () async {
      final signedInCtrl = StreamController<void>.broadcast(sync: true);

      // Pas de testUserId → _currentUserId retourne null (Supabase non initialisé).
      final vm = QuestViewModel(
        repo,
        onSignedIn: signedInCtrl.stream,
        // testUserId: null → Supabase.instance tentative → null en test
      );

      signedInCtrl.add(null);
      await Future<void>.delayed(Duration.zero);

      // Aucun chargement ne doit avoir eu lieu.
      verifyNever(() => repo.loadQuests(any()));

      await signedInCtrl.close();
      vm.dispose();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Cycle complet : onSignedOut puis onSignedIn
  // ────────────────────────────────────────────────────────────────────────────

  group('QuestViewModel — cycle signOut puis signIn', () {
    test('vide puis recharge correctement', () async {
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);
      final signedInCtrl = StreamController<void>.broadcast(sync: true);
      when(() => repo.loadQuests(_testUserId))
          .thenAnswer((_) async => [_quest()]);

      final vm = QuestViewModel(
        repo,
        onSignedOut: signedOutCtrl.stream,
        onSignedIn: signedInCtrl.stream,
        testUserId: _testUserId,
      );

      // 1. Chargement initial.
      await vm.loadQuests(_testUserId);
      expect(vm.quests, isNotEmpty);

      // 2. Logout → clearCache().
      signedOutCtrl.add(null);
      expect(vm.quests, isEmpty, reason: 'onSignedOut doit vider le cache');

      // 3. Reconnexion → loadQuests().
      signedInCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(vm.quests, isNotEmpty,
          reason: 'onSignedIn doit recharger le cache après logout');

      await signedOutCtrl.close();
      await signedInCtrl.close();
      vm.dispose();
    });
  });
}
