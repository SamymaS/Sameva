import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/repositories/ai_credits_repository.dart';
import 'package:sameva/data/repositories/premium_subscription_repository.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';

// ---- Doubles de test ----

class _MockBox extends Mock implements Box<dynamic> {}

class _MockAiCreditsRepo extends Mock implements AiCreditsRepository {}

class _MockPremiumRepo extends Mock implements PremiumSubscriptionRepository {}

/// Fake nécessaire pour `any<AiValidationState>()` dans mocktail.
class _FakeAiValidationState extends Fake implements AiValidationState {}

// ---- Constantes de test ----

const _userId = 'user-premium-entitlement';
const _hiveKey = 'ai_validation_$_userId';

// ---- Helpers ----

/// Crée un service avec repo crédits + repo premium mockés.
AiValidationCreditsService _buildService({
  required _MockBox box,
  _MockAiCreditsRepo? creditsRepo,
  _MockPremiumRepo? premiumRepo,
  AiValidationState? initialHiveState,
}) {
  if (initialHiveState != null) {
    when(() => box.get(_hiveKey)).thenReturn(initialHiveState.toJson());
  } else {
    when(() => box.get(_hiveKey)).thenReturn(null);
  }
  when(() => box.put(any(), any())).thenAnswer((_) async {});

  return AiValidationCreditsService(
    box,
    repository: creditsRepo,
    premiumRepository: premiumRepo,
    testUserId: _userId,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAiValidationState());
  });

  late _MockBox box;
  late _MockAiCreditsRepo creditsRepo;
  late _MockPremiumRepo premiumRepo;

  setUp(() {
    box = _MockBox();
    creditsRepo = _MockAiCreditsRepo();
    premiumRepo = _MockPremiumRepo();
  });

  // ==========================================================================
  // Règle critique : is_premium=true + premium_until=null → isPremium reste true
  // ==========================================================================

  group('Entitlement — règle is_premium indépendant de premium_until', () {
    test(
        'load : is_premium=true + premium_until=null → isPremium=true après load',
        () async {
      // Scénario : webhook Stripe a posé is_premium=true, premium_until non encore reçu.
      when(() => creditsRepo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(
          isPremium: true,
          premiumUntil: null, // délai webhook
        ),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);

      // isPremium doit être true — premium_until null ne le force pas à false.
      expect(service.isPremium, isTrue);
      expect(service.premiumUntil, isNull);
    });

    test('pas de ligne → isPremium=false (PremiumEntitlement.libre())', () async {
      when(() => creditsRepo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement.libre(),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);

      expect(service.isPremium, isFalse);
      expect(service.premiumUntil, isNull);
    });
  });

  // ==========================================================================
  // load → entitlement reflété dans canValidateWithAI et consumeForValidation
  // ==========================================================================

  group('load → entitlement piloté par le serveur', () {
    test('après load : canValidateWithAI()=true à 0 jeton si premium', () async {
      when(() => creditsRepo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(isPremium: true),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);

      // 0 jeton mais premium → validation autorisée.
      expect(service.balance, 0);
      expect(service.canValidateWithAI(), isTrue);
    });

    test('consumeForValidation ne décrémente pas en premium (0 jeton)', () async {
      when(() => creditsRepo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(isPremium: true),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);

      final result = await service.consumeForValidation();

      expect(result, isTrue);
      expect(service.balance, 0); // premium ne consomme jamais
    });

    test('setPremium appelé : isPremium reflété dans l\'état', () async {
      // Vérifie que _fetchAndApplyPremiumEntitlement met bien à jour l'état.
      when(() => creditsRepo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});

      final until = DateTime.utc(2027, 1, 1);
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => PremiumEntitlement(isPremium: true, premiumUntil: until),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);

      expect(service.isPremium, isTrue);
      expect(service.premiumUntil, until);
    });
  });

  // ==========================================================================
  // Erreur réseau au fetch entitlement → pas de crash, état conservé
  // ==========================================================================

  group('Erreur réseau fetch entitlement', () {
    test('fetch entitlement qui throw → pas de crash, état local conservé', () async {
      // État local Hive : balance=3, non premium.
      final localState = AiValidationState(
        balance: 3,
        onboardingGranted: true,
        updatedAt: DateTime.utc(2026, 6, 16, 10, 0),
      );

      when(() => creditsRepo.fetchForUser(_userId))
          .thenAnswer((_) async => localState);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      // Fetch premium qui lève une exception (hors-ligne).
      when(() => premiumRepo.fetchForUser(_userId))
          .thenThrow(Exception('connexion impossible'));

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
        initialHiveState: localState,
      );

      // Ne doit PAS lancer d'exception.
      await expectLater(
        () async => service.load(_userId),
        returnsNormally,
      );

      // L'état local est conservé après l'erreur réseau.
      expect(service.balance, 3);
      expect(service.onboardingGranted, isTrue);
      // isPremium reste à sa valeur locale (false par défaut).
      expect(service.isPremium, isFalse);
    });

    test(
        'fetch CRÉDITS qui throw → entitlement premium quand même lu et appliqué '
        '(indépendance crédits/entitlement)', () async {
      // Régression : auparavant, un échec du fetch crédits faisait un return
      // anticipé dans load() AVANT le fetch d'entitlement → premium jamais lu.
      when(() => creditsRepo.fetchForUser(_userId))
          .thenThrow(Exception('crédits hors-ligne'));
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      // L'entitlement, lui, est joignable et renvoie premium=true.
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(isPremium: true),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);

      // Le fetch crédits a échoué mais l'entitlement a bien été lu et appliqué.
      verify(() => premiumRepo.fetchForUser(_userId)).called(1);
      expect(service.isPremium, isTrue);
    });

    test('refreshEntitlement hors-ligne → pas de crash, état inchangé', () async {
      when(() => creditsRepo.fetchForUser(_userId)).thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      // Premier load : premium ok.
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(isPremium: true),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
      );
      await service.load(_userId);
      expect(service.isPremium, isTrue);

      // Refresh : hors-ligne.
      when(() => premiumRepo.fetchForUser(_userId))
          .thenThrow(Exception('timeout'));

      await expectLater(
        () async => service.refreshEntitlement(),
        returnsNormally,
      );

      // L'état premium reste tel qu'il était avant le refresh raté.
      expect(service.isPremium, isTrue);
    });
  });

  // ==========================================================================
  // refreshEntitlement — no-op si pas de user
  // ==========================================================================

  group('refreshEntitlement', () {
    test('no-op si pas de userId (service non chargé)', () async {
      final service = AiValidationCreditsService(
        box,
        premiumRepository: premiumRepo,
        testUserId: _userId,
        // Pas de load() → _userId interne est null
      );

      // Pas de load → _userId est null → no-op (pas d'appel au repo).
      await expectLater(
        () async => service.refreshEntitlement(),
        returnsNormally,
      );

      verifyNever(() => premiumRepo.fetchForUser(any()));
    });
  });

  // ==========================================================================
  // Réconciliation LWW des crédits non perturbée par le fetch entitlement
  // ==========================================================================

  group('LWW crédits non perturbé par l\'entitlement', () {
    test(
        'load : entitlement premium ne modifie pas updatedAt des crédits '
        '(le LWW reste intact pour les crédits)', () async {
      // État local récent.
      final dateLocale = DateTime.utc(2026, 6, 16, 12, 0);
      final localState = AiValidationState(
        balance: 5,
        onboardingGranted: true,
        updatedAt: dateLocale,
      );

      // Remote crédits : plus ancien.
      final dateRemote = DateTime.utc(2026, 6, 16, 8, 0);
      final remoteCredits = AiValidationState(
        balance: 2,
        onboardingGranted: false,
        updatedAt: dateRemote,
      );

      when(() => creditsRepo.fetchForUser(_userId))
          .thenAnswer((_) async => remoteCredits);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(isPremium: true),
      );

      final service = _buildService(
        box: box,
        creditsRepo: creditsRepo,
        premiumRepo: premiumRepo,
        initialHiveState: localState,
      );
      await service.load(_userId);

      // LWW : local plus récent → balance locale conservée (5, pas 2).
      expect(service.balance, 5);
      expect(service.onboardingGranted, isTrue);
      // Entitlement appliqué correctement en plus.
      expect(service.isPremium, isTrue);
    });
  });

  // ==========================================================================
  // startPremiumCheckout — vérifie l'invoke (via checkoutUrlProvider en test)
  // ==========================================================================

  group('startPremiumCheckout', () {
    test(
        'startPremiumCheckout appelle le checkoutUrlProvider injecté '
        '(pilote le vrai code path sans Supabase.instance)', () async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      final service = AiValidationCreditsService(
        box,
        testUserId: _userId,
      );

      var invoked = false;
      // On injecte un fournisseur d'URL qui simule la réponse de l'Edge Function.
      // L'URL est intentionnellement invalide en test (pas de vrai navigateur).
      await service.startPremiumCheckout(
        checkoutUrlProvider: () async {
          invoked = true;
          // Retourner null : on vérifie juste que le provider est appelé.
          // Pas de launchUrl en test (aucun navigateur disponible).
          return null;
        },
      );

      expect(invoked, isTrue);
    });

    test('startPremiumCheckout : url null → pas de crash', () async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      final service = AiValidationCreditsService(
        box,
        testUserId: _userId,
      );

      await expectLater(
        () async => service.startPremiumCheckout(
          checkoutUrlProvider: () async => null,
        ),
        returnsNormally,
      );
    });

    test('startPremiumCheckout : exception dans le provider → pas de crash', () async {
      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      final service = AiValidationCreditsService(
        box,
        testUserId: _userId,
      );

      await expectLater(
        () async => service.startPremiumCheckout(
          checkoutUrlProvider: () async {
            throw Exception('Edge Function indisponible');
          },
        ),
        returnsNormally,
      );
    });
  });

  // ==========================================================================
  // onSignedIn → entitlement fetché
  // ==========================================================================

  group('onSignedIn → entitlement chargé', () {
    test('signIn déclenche load → entitlement appliqué', () async {
      final signedIn = StreamController<void>.broadcast();
      addTearDown(signedIn.close);

      when(() => box.get(_hiveKey)).thenReturn(null);
      when(() => box.put(any(), any())).thenAnswer((_) async {});
      when(() => creditsRepo.fetchForUser(_userId))
          .thenAnswer((_) async => null);
      when(() => creditsRepo.upsertForUser(any(), any())).thenAnswer((_) async {});
      when(() => premiumRepo.fetchForUser(_userId)).thenAnswer(
        (_) async => const PremiumEntitlement(isPremium: true),
      );

      final service = AiValidationCreditsService(
        box,
        repository: creditsRepo,
        premiumRepository: premiumRepo,
        onSignedIn: signedIn.stream,
        testUserId: _userId,
      );

      signedIn.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.isPremium, isTrue);
    });
  });
}
