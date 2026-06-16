import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/repositories/ai_credits_repository.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';

// ---- Doubles de test ----

class _MockBox extends Mock implements Box<dynamic> {}

class _MockAiCreditsRepo extends Mock implements AiCreditsRepository {}

/// Fake utilisé comme fallback pour `any<AiValidationState>()` dans mocktail.
class _FakeAiValidationState extends Fake implements AiValidationState {}

// ---- Constantes de test ----

const _userId = 'user-sync-test';
const _hiveKey = 'ai_validation_$_userId';

// ---- Helpers ----

/// Crée un service avec boîte et repository mockés.
AiValidationCreditsService _buildService({
  required _MockBox box,
  _MockAiCreditsRepo? repo,
  AiValidationState? initialHiveState,
}) {
  if (initialHiveState != null) {
    when(() => box.get(_hiveKey)).thenReturn(initialHiveState.toJson());
  } else {
    when(() => box.get(_hiveKey)).thenReturn(null);
  }
  when(() => box.put(any(), any())).thenAnswer((_) async {});

  return AiValidationCreditsService(box, repository: repo);
}

void main() {
  setUpAll(() {
    // mocktail exige un fallback pour tout type non-primitif passé via any().
    registerFallbackValue(_FakeAiValidationState());
  });

  late _MockBox box;
  late _MockAiCreditsRepo repo;

  setUp(() {
    box = _MockBox();
    repo = _MockAiCreditsRepo();
  });

  // ==========================================================================
  // Réconciliation LWW (load)
  // ==========================================================================

  group('load — réconciliation LWW', () {
    test('remote plus récent → adopte remote + écrit Hive', () async {
      final dateLocale = DateTime.utc(2026, 6, 16, 8, 0);
      final dateRemote = DateTime.utc(2026, 6, 16, 12, 0); // plus récent

      final localState = AiValidationState(
        balance: 2,
        onboardingGranted: false,
        updatedAt: dateLocale,
      );
      final remoteState = AiValidationState(
        balance: 7,
        onboardingGranted: true,
        lastRewardedStreakMilestone: 7,
        updatedAt: dateRemote,
      );

      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => remoteState);
      // upsertForUser ne doit PAS être appelé quand on adopte remote.
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = _buildService(
        box: box,
        repo: repo,
        initialHiveState: localState,
      );
      await service.load(_userId);

      // L'état en mémoire est celui du remote.
      expect(service.balance, 7);
      expect(service.onboardingGranted, isTrue);
      expect(service.lastRewardedStreakMilestone, 7);

      // Hive doit avoir été mis à jour avec le remote.
      verify(() => box.put(_hiveKey, any())).called(greaterThan(0));

      // upsert ne doit PAS avoir été appelé (on a adopté remote, pas de conflit).
      verifyNever(() => repo.upsertForUser(any(), any()));
    });

    test('local plus récent → garde local + upsert Supabase appelé', () async {
      final dateRemote = DateTime.utc(2026, 6, 16, 8, 0);
      final dateLocale = DateTime.utc(2026, 6, 16, 12, 0); // plus récent

      final localState = AiValidationState(
        balance: 5,
        onboardingGranted: true,
        updatedAt: dateLocale,
      );
      final remoteState = AiValidationState(
        balance: 2,
        onboardingGranted: false,
        updatedAt: dateRemote,
      );

      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => remoteState);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = _buildService(
        box: box,
        repo: repo,
        initialHiveState: localState,
      );
      await service.load(_userId);

      // L'état en mémoire reste le local.
      expect(service.balance, 5);
      expect(service.onboardingGranted, isTrue);

      // upsert doit avoir été déclenché (fire-and-forget).
      // On attend un tick pour laisser les futures non-attendues se résoudre.
      await Future<void>.delayed(Duration.zero);
      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });

    test('pas de remote → upsert du local appelé (crée la ligne)', () async {
      final localState = AiValidationState(
        balance: 3,
        onboardingGranted: true,
        updatedAt: DateTime.utc(2026, 6, 16, 10, 0),
      );

      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => null); // aucune ligne
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = _buildService(
        box: box,
        repo: repo,
        initialHiveState: localState,
      );
      await service.load(_userId);

      // État inchangé.
      expect(service.balance, 3);

      // upsert doit être appelé pour créer la ligne.
      await Future<void>.delayed(Duration.zero);
      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });

    test('fetch qui throw → garde local sans crash', () async {
      final localState = AiValidationState(
        balance: 4,
        onboardingGranted: true,
        updatedAt: DateTime.utc(2026, 6, 16, 10, 0),
      );

      when(() => repo.fetchForUser(_userId))
          .thenThrow(Exception('hors ligne'));
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = _buildService(
        box: box,
        repo: repo,
        initialHiveState: localState,
      );

      // Ne doit PAS lancer d'exception.
      await expectLater(
        () async => service.load(_userId),
        returnsNormally,
      );

      // État local préservé.
      expect(service.balance, 4);
      expect(service.onboardingGranted, isTrue);

      // upsert ne doit PAS être appelé si le fetch a échoué.
      verifyNever(() => repo.upsertForUser(any(), any()));
    });

    test('ni local ni remote → état neuf (empty)', () async {
      // Hive vide + remote null.
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => null);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = AiValidationCreditsService(box, repository: repo);
      await service.load(_userId);

      expect(service.balance, 0);
      expect(service.onboardingGranted, isFalse);

      // upsert appelé pour créer la ligne avec l'état neuf.
      await Future<void>.delayed(Duration.zero);
      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });
  });

  // ==========================================================================
  // grantOnboarding no-op après réconciliation
  // ==========================================================================

  group('grantOnboarding — anti re-don après réconciliation', () {
    test('no-op si onboardingGranted=true vient du serveur après réconciliation',
        () async {
      // Scénario : réinstallation. Hive local est vide, le serveur a
      // onboardingGranted=true → après réconciliation, grantOnboarding est no-op.
      final dateLocale = DateTime.utc(2026, 6, 16, 6, 0);
      final dateRemote = DateTime.utc(2026, 6, 16, 12, 0); // plus récent

      final localState = AiValidationState(
        balance: 0,
        onboardingGranted: false, // Hive vide = état frais
        updatedAt: dateLocale,
      );
      final remoteState = AiValidationState(
        balance: 3, // déjà consommé 2 jetons
        onboardingGranted: true, // accordé lors de la première install
        updatedAt: dateRemote,
      );

      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => remoteState);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = _buildService(
        box: box,
        repo: repo,
        initialHiveState: localState,
      );
      await service.load(_userId);

      // Après réconciliation, onboardingGranted doit être true (venu du serveur).
      expect(service.onboardingGranted, isTrue);
      expect(service.balance, 3);

      // grantOnboarding est un no-op.
      await service.grantOnboarding();

      expect(service.balance, 3); // inchangé, pas de re-don des 5 jetons
      expect(service.onboardingGranted, isTrue);
    });

    test('accorde les 5 jetons si onboardingGranted=false après réconciliation',
        () async {
      // Nouveau joueur : ni Hive ni serveur n'ont l'onboarding accordé.
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => null);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = AiValidationCreditsService(box, repository: repo);
      await service.load(_userId);

      expect(service.onboardingGranted, isFalse);
      expect(service.balance, 0);

      await service.grantOnboarding();

      expect(service.balance, AiValidationCreditsService.kOnboardingGrant);
      expect(service.onboardingGranted, isTrue);
    });
  });

  // ==========================================================================
  // Mutations → upsert fire-and-forget déclenché
  // ==========================================================================

  group('mutations → upsert fire-and-forget', () {
    /// Crée et charge un service avec état vide (balance=0, onboarding non accordé).
    /// N'efface PAS les stubs du repo (clearInteractions effacerait les stubs
    /// dont les mutations suivantes ont besoin).
    Future<AiValidationCreditsService> buildLoadedService() async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => null);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = AiValidationCreditsService(box, repository: repo);
      await service.load(_userId);
      return service;
    }

    test('grantOnboarding déclenche upsert', () async {
      final service = await buildLoadedService();

      // Réinitialise les interactions APRÈS le load pour ne compter que ceux
      // déclenchés par la mutation testée.
      resetMocktailState();
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      await service.grantOnboarding();
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });

    test('grantDailyIfDue déclenche upsert', () async {
      final service = await buildLoadedService();

      resetMocktailState();
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      await service.grantDailyIfDue(DateTime.now());
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });

    test('earnFromStreak déclenche upsert', () async {
      final service = await buildLoadedService();

      resetMocktailState();
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      await service.earnFromStreak(7);
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });

    test('consumeForValidation déclenche upsert', () async {
      // Prépare une balance > 0.
      final initialState = AiValidationState(
        balance: 3,
        onboardingGranted: true,
        updatedAt: DateTime.utc(2026, 6, 16, 8, 0),
      );
      when(() => box.get(_hiveKey)).thenReturn(initialState.toJson());
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => null);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = AiValidationCreditsService(box, repository: repo);
      await service.load(_userId);

      resetMocktailState();
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      final result = await service.consumeForValidation();
      await Future<void>.delayed(Duration.zero);

      expect(result, isTrue);
      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });
  });

  // ==========================================================================
  // reset()
  // ==========================================================================

  group('reset', () {
    test('vide l\'état mémoire sans purger Hive', () async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => repo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => repo.upsertForUser(any(), any())).thenAnswer((_) async {});

      final service = AiValidationCreditsService(box, repository: repo);
      await service.load(_userId);
      await service.grantOnboarding();

      // Compte les appels put AVANT le reset.
      final putAvantReset =
          verify(() => box.put(_hiveKey, any())).callCount;
      expect(putAvantReset, greaterThan(0));

      // Réinitialise les compteurs de verify sur box.
      clearInteractions(box);
      // Redéfinit le stub après clearInteractions.
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      service.reset();

      // Après reset() : état mémoire vidé.
      expect(service.balance, 0);
      expect(service.onboardingGranted, isFalse);

      // Aucun accès Hive (ni put ni delete) depuis le reset().
      verifyNever(() => box.delete(any<String>()));
      verifyNever(() => box.put(any(), any()));
    });
  });

  // ==========================================================================
  // Sans repository (mode local-only, tests de compatibilité)
  // ==========================================================================

  group('sans repository — mode local-only', () {
    test('load fonctionne sans repo (pas de crash)', () async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      final service = AiValidationCreditsService(box);
      await expectLater(
        () async => service.load(_userId),
        returnsNormally,
      );
      expect(service.balance, 0);
    });

    test('grantOnboarding fonctionne sans repo', () async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      final service = AiValidationCreditsService(box);
      await service.load(_userId);
      await service.grantOnboarding();

      expect(service.balance, AiValidationCreditsService.kOnboardingGrant);
    });
  });

  // ==========================================================================
  // Déclencheur auth : le stream onSignedIn pilote tout le flux de démarrage.
  // Régression : auparavant _onSignedIn lisait _userId (null au signIn) et
  // sortait immédiatement → load/grantOnboarding/grantDailyIfDue ne tournaient
  // jamais dans l'app réelle. Le uid doit être résolu via _currentUserId.
  // ==========================================================================

  group('onSignedIn — déclencheur de démarrage', () {
    test('le signIn déclenche load → grantOnboarding → grantDailyIfDue',
        () async {
      final signedIn = StreamController<void>.broadcast();
      addTearDown(signedIn.close);

      when(() => box.get(_hiveKey)).thenReturn(null); // Hive vide
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => null); // aucune ligne serveur
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      // testUserId résout le uid sans Supabase.instance (non initialisé en test).
      final service = AiValidationCreditsService(
        box,
        repository: repo,
        onSignedIn: signedIn.stream,
        testUserId: _userId,
      );

      // Avant tout signIn : état neuf, rien ne s'est produit.
      expect(service.balance, 0);
      expect(service.onboardingGranted, isFalse);

      // Émission du signIn (le stream ne transporte pas d'identifiant).
      signedIn.add(null);
      // Laisse le pipeline asynchrone (load + 2 grants + fire-and-forget) finir.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // onboarding (+5) puis daily (+1) appliqués via le seul signal du stream.
      expect(service.onboardingGranted, isTrue);
      expect(
        service.balance,
        AiValidationCreditsService.kOnboardingGrant +
            AiValidationCreditsService.kDailyGrant,
      );
      verify(() => repo.upsertForUser(_userId, any())).called(greaterThan(0));
    });

    test('signIn anti re-don : onboarding serveur=true → pas de +5', () async {
      final signedIn = StreamController<void>.broadcast();
      addTearDown(signedIn.close);

      // Réinstallation : Hive vide, mais le serveur a déjà onboardingGranted=true.
      final remoteState = AiValidationState(
        balance: 3,
        onboardingGranted: true,
        updatedAt: DateTime.utc(2026, 6, 16, 12, 0),
      );
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => repo.fetchForUser(_userId))
          .thenAnswer((_) async => remoteState);
      when(() => repo.upsertForUser(any(), any()))
          .thenAnswer((_) async {});

      final service = AiValidationCreditsService(
        box,
        repository: repo,
        onSignedIn: signedIn.stream,
        testUserId: _userId,
      );

      signedIn.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Onboarding non re-donné : balance = remote (3) + daily (1), pas +5.
      expect(service.onboardingGranted, isTrue);
      expect(
        service.balance,
        3 + AiValidationCreditsService.kDailyGrant,
      );
    });
  });
}
