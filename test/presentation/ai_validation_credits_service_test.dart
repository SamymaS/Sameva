import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';

// ---- Doubles de test ----

class _MockBox extends Mock implements Box<dynamic> {}

// ---- Helpers ----

const _userId = 'test-user-42';
const _hiveKey = 'ai_validation_$_userId';

/// Crée un service avec la boîte mockée et charge immédiatement un état vide.
Future<AiValidationCreditsService> _buildService(
  _MockBox box, {
  AiValidationState? initialState,
}) async {
  // Si un état initial est fourni, on le sérialise dans la box.
  if (initialState != null) {
    when(() => box.get(_hiveKey)).thenReturn(initialState.toJson());
  } else {
    when(() => box.get(_hiveKey)).thenReturn(null);
  }
  when(() => box.put(any(), any())).thenAnswer((_) async {});

  final service = AiValidationCreditsService(box);
  await service.load(_userId);
  return service;
}

void main() {
  late _MockBox box;

  setUp(() {
    box = _MockBox();
  });

  // ==========================================================================
  // grantOnboarding
  // ==========================================================================

  group('grantOnboarding', () {
    test('accorde 5 crédits au premier appel', () async {
      final service = await _buildService(box);

      await service.grantOnboarding();

      expect(service.balance, AiValidationCreditsService.kOnboardingGrant);
      expect(service.onboardingGranted, isTrue);
      verify(() => box.put(_hiveKey, any())).called(greaterThan(0));
    });

    test('no-op au deuxième appel (accordé une seule fois)', () async {
      final service = await _buildService(box);
      await service.grantOnboarding();
      final balanceApresPremiereOctroi = service.balance;

      // Deuxième appel
      await service.grantOnboarding();

      expect(service.balance, balanceApresPremiereOctroi);
    });

    test('no-op si déjà accordé à la création (state chargé depuis Hive)', () async {
      final etatDepart = AiValidationState(
        balance: 3,
        onboardingGranted: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.grantOnboarding();

      expect(service.balance, 3); // inchangé
      expect(service.onboardingGranted, isTrue);
    });

    test('ne dépasse jamais kFreeWalletCap (balance déjà à 8)', () async {
      final etatDepart = AiValidationState(
        balance: 8,
        onboardingGranted: false,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.grantOnboarding();

      // 8 + 5 serait 13, mais le cap est 10 → on accorde 2
      expect(service.balance, AiValidationCreditsService.kFreeWalletCap);
    });
  });

  // ==========================================================================
  // grantDailyIfDue
  // ==========================================================================

  group('grantDailyIfDue', () {
    test('accorde 1 crédit si jamais accordé', () async {
      final service = await _buildService(box);

      await service.grantDailyIfDue(DateTime(2026, 6, 16, 10, 0));

      expect(service.balance, AiValidationCreditsService.kDailyGrant);
    });

    test('idempotent le même jour (même heure différente)', () async {
      final service = await _buildService(box);
      await service.grantDailyIfDue(DateTime(2026, 6, 16, 8, 0));
      final balanceApres = service.balance;

      // Deuxième appel dans la même journée
      await service.grantDailyIfDue(DateTime(2026, 6, 16, 20, 30));

      expect(service.balance, balanceApres);
    });

    test('idempotent le même jour : lastDailyGrant chargé depuis Hive', () async {
      final etatDepart = AiValidationState(
        balance: 3,
        lastDailyGrant: DateTime(2026, 6, 16, 7, 0),
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.grantDailyIfDue(DateTime(2026, 6, 16, 23, 59));

      expect(service.balance, 3); // inchangé
    });

    test('accorde 1 crédit le lendemain', () async {
      final etatDepart = AiValidationState(
        balance: 3,
        lastDailyGrant: DateTime(2026, 6, 15, 22, 0),
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.grantDailyIfDue(DateTime(2026, 6, 16, 0, 1));

      expect(service.balance, 4);
    });

    test('ne dépasse pas kFreeWalletCap même si balance est juste en dessous', () async {
      final etatDepart = AiValidationState(
        balance: AiValidationCreditsService.kFreeWalletCap,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.grantDailyIfDue(DateTime(2026, 6, 16, 10, 0));

      expect(service.balance, AiValidationCreditsService.kFreeWalletCap);
    });
  });

  // ==========================================================================
  // earnFromStreak
  // ==========================================================================

  group('earnFromStreak', () {
    test('récompense le palier 7', () async {
      final service = await _buildService(box);

      await service.earnFromStreak(7);

      expect(service.balance, AiValidationCreditsService.kStreakMilestoneGrant);
      expect(service.lastRewardedStreakMilestone, 7);
    });

    test('récompense le palier 14 après avoir récompensé 7', () async {
      final etatDepart = AiValidationState(
        balance: 2,
        lastRewardedStreakMilestone: 7,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.earnFromStreak(14);

      expect(service.balance, 4); // 2 + 2
      expect(service.lastRewardedStreakMilestone, 14);
    });

    test('ne récompense PAS le palier 5 (pas un multiple de 7)', () async {
      final service = await _buildService(box);

      await service.earnFromStreak(5);

      expect(service.balance, 0);
      expect(service.lastRewardedStreakMilestone, 0);
    });

    test('ne récompense PAS le palier 8 (pas un multiple de 7)', () async {
      final service = await _buildService(box);

      await service.earnFromStreak(8);

      expect(service.balance, 0);
    });

    test('ne récompense PAS le palier 13 (pas un multiple de 7)', () async {
      final service = await _buildService(box);

      await service.earnFromStreak(13);

      expect(service.balance, 0);
    });

    test('ne récompense pas deux fois le même palier (idempotent)', () async {
      final service = await _buildService(box);
      await service.earnFromStreak(7);
      final balanceApres = service.balance;

      await service.earnFromStreak(7);

      expect(service.balance, balanceApres); // inchangé
    });

    test('ne récompense pas un palier inférieur au dernier récompensé', () async {
      final etatDepart = AiValidationState(
        balance: 4,
        lastRewardedStreakMilestone: 14,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      // Tenter de re-récompenser le palier 7 (déjà dépassé)
      await service.earnFromStreak(7);

      expect(service.balance, 4); // inchangé
      expect(service.lastRewardedStreakMilestone, 14); // inchangé
    });

    test('ne récompense pas streakDays <= 0', () async {
      final service = await _buildService(box);

      await service.earnFromStreak(0);
      await service.earnFromStreak(-7);

      expect(service.balance, 0);
    });

    test('cap respecté : balance 9 + gain 2 → plafonné à 10', () async {
      final etatDepart = AiValidationState(
        balance: 9,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.earnFromStreak(7);

      expect(service.balance, AiValidationCreditsService.kFreeWalletCap);
    });
  });

  // ==========================================================================
  // cap global : aucune source ne dépasse kFreeWalletCap
  // ==========================================================================

  group('cap kFreeWalletCap', () {
    test('onboarding + daily + streak ne dépassent jamais le cap', () async {
      final service = await _buildService(box);

      // Onboarding : +5 → balance = 5
      await service.grantOnboarding();
      // Daily : +1 → balance = 6
      await service.grantDailyIfDue(DateTime(2026, 6, 16));
      // Streak 7 : +2 → balance = 8
      await service.earnFromStreak(7);
      // Streak 14 : +2 → balance = 10
      await service.earnFromStreak(14);
      // Daily lendemain : +0 car cap atteint
      await service.grantDailyIfDue(DateTime(2026, 6, 17));

      expect(service.balance, AiValidationCreditsService.kFreeWalletCap);
    });

    test('balance ne dépasse jamais kFreeWalletCap quelle que soit la source', () async {
      final etatDepart = AiValidationState(
        balance: AiValidationCreditsService.kFreeWalletCap,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.grantOnboarding();
      await service.grantDailyIfDue(DateTime(2026, 6, 16));
      await service.earnFromStreak(7);

      expect(service.balance, AiValidationCreditsService.kFreeWalletCap);
    });
  });

  // ==========================================================================
  // consumeForValidation + canValidateWithAI
  // ==========================================================================

  group('consumeForValidation', () {
    test('décrémente de 1 si balance > 0', () async {
      final etatDepart = AiValidationState(
        balance: 3,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      final result = await service.consumeForValidation();

      expect(result, isTrue);
      expect(service.balance, 2);
    });

    test('retourne false et ne décrémente pas si balance == 0', () async {
      final service = await _buildService(box);
      expect(service.balance, 0);

      final result = await service.consumeForValidation();

      expect(result, isFalse);
      expect(service.balance, 0);
    });

    test('décrémente jusqu\'à 0 puis refuse', () async {
      final etatDepart = AiValidationState(
        balance: 2,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      expect(await service.consumeForValidation(), isTrue); // balance = 1
      expect(await service.consumeForValidation(), isTrue); // balance = 0
      expect(await service.consumeForValidation(), isFalse); // refus

      expect(service.balance, 0);
    });
  });

  group('canValidateWithAI', () {
    test('retourne false si balance == 0 et non premium', () async {
      final service = await _buildService(box);

      expect(service.canValidateWithAI(), isFalse);
    });

    test('retourne true si balance > 0', () async {
      final etatDepart = AiValidationState(
        balance: 1,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      expect(service.canValidateWithAI(), isTrue);
    });
  });

  // ==========================================================================
  // Premium
  // ==========================================================================

  group('premium', () {
    test('canValidateWithAI retourne true à 0 crédit si premium', () async {
      final service = await _buildService(box);
      await service.setPremium(true);

      expect(service.balance, 0);
      expect(service.canValidateWithAI(), isTrue);
    });

    test('consumeForValidation ne décrémente pas si premium', () async {
      final etatDepart = AiValidationState(
        balance: 5,
        isPremium: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      final result = await service.consumeForValidation();

      expect(result, isTrue);
      expect(service.balance, 5); // inchangé
    });

    test('consumeForValidation ne décrémente pas même à 0 crédit si premium', () async {
      final service = await _buildService(box);
      await service.setPremium(true);

      final result = await service.consumeForValidation();

      expect(result, isTrue);
      expect(service.balance, 0); // inchangé
    });

    test('setPremium avec date d\'expiration stocke premiumUntil', () async {
      final service = await _buildService(box);
      final expiration = DateTime(2027, 1, 1).toUtc();

      await service.setPremium(true, until: expiration);

      expect(service.isPremium, isTrue);
      expect(service.premiumUntil, expiration);
    });

    test('setPremium false désactive le premium', () async {
      final etatDepart = AiValidationState(
        isPremium: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final service = await _buildService(box, initialState: etatDepart);

      await service.setPremium(false);

      expect(service.isPremium, isFalse);
      expect(service.canValidateWithAI(), isFalse);
    });
  });

  // ==========================================================================
  // Persistance
  // ==========================================================================

  group('persistance Hive', () {
    test('chaque mutation appelle box.put avec la bonne clé', () async {
      final service = await _buildService(box);

      await service.grantOnboarding();

      verify(() => box.put(_hiveKey, any())).called(greaterThan(0));
    });

    test('load avec userId vide ne lit pas Hive', () async {
      final service = AiValidationCreditsService(box);

      await service.load('');

      verifyNever(() => box.get(any()));
    });

    test('reset vide le state en mémoire sans purger Hive', () async {
      final service = await _buildService(box);
      await service.grantOnboarding();

      service.reset();

      expect(service.balance, 0);
      expect(service.onboardingGranted, isFalse);
      verifyNever(() => box.delete(any()));
    });
  });

  // ==========================================================================
  // Sérialisation du modèle AiValidationState
  // ==========================================================================

  group('AiValidationState sérialisation', () {
    test('toJson / fromJson round-trip', () {
      final date = DateTime(2026, 6, 16, 12, 0).toUtc();
      final original = AiValidationState(
        balance: 7,
        lastDailyGrant: date,
        onboardingGranted: true,
        lastRewardedStreakMilestone: 14,
        isPremium: true,
        premiumUntil: DateTime(2027, 1, 1).toUtc(),
        updatedAt: date,
      );

      final json = original.toJson();
      final restaure = AiValidationState.fromJson(json);

      expect(restaure.balance, original.balance);
      expect(restaure.lastDailyGrant, original.lastDailyGrant);
      expect(restaure.onboardingGranted, original.onboardingGranted);
      expect(restaure.lastRewardedStreakMilestone,
          original.lastRewardedStreakMilestone);
      expect(restaure.isPremium, original.isPremium);
      expect(restaure.premiumUntil, original.premiumUntil);
    });

    test('fromJson avec JSON minimal retourne les valeurs par défaut', () {
      final json = <String, dynamic>{
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      final state = AiValidationState.fromJson(json);

      expect(state.balance, 0);
      expect(state.lastDailyGrant, isNull);
      expect(state.onboardingGranted, isFalse);
      expect(state.lastRewardedStreakMilestone, 0);
      expect(state.isPremium, isFalse);
      expect(state.premiumUntil, isNull);
    });

    test('AiValidationState.empty() a des valeurs par défaut cohérentes', () {
      final state = AiValidationState.empty();

      expect(state.balance, 0);
      expect(state.onboardingGranted, isFalse);
      expect(state.lastDailyGrant, isNull);
      expect(state.isPremium, isFalse);
      expect(state.lastRewardedStreakMilestone, 0);
    });
  });
}
