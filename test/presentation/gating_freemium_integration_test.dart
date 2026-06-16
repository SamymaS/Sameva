import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/domain/services/validation_ai_service.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';

// ── Doubles de test ────────────────────────────────────────────────────────────

class _MockBox extends Mock implements Box<dynamic> {}

class _MockValidationAI extends Mock implements ValidationAIService {}

class _MockPlayerRepo extends Mock implements PlayerRepository {}

// ── Helpers ────────────────────────────────────────────────────────────────────

const _userId = 'user-gating-test';
const _hiveKey = 'ai_validation_$_userId';

/// Construit un [AiValidationCreditsService] avec la boîte mockée
/// et un [initialState] optionnel déjà chargé.
Future<AiValidationCreditsService> _buildCredits(
  _MockBox box, {
  AiValidationState? initialState,
}) async {
  if (initialState != null) {
    when(() => box.get(_hiveKey)).thenReturn(initialState.toJson());
  } else {
    when(() => box.get(_hiveKey)).thenReturn(null);
  }
  when(() => box.put(any(), any())).thenAnswer((_) async {});

  final service = AiValidationCreditsService(box, testUserId: _userId);
  await service.load(_userId);
  return service;
}

/// Exécute une analyse image via le gating du wallet — EXACTEMENT comme la page
/// de validation appelle [AiValidationCreditsService.runGatedValidation].
/// Retourne null si l'IA n'a pas été effectuée (route manuelle).
Future<ValidationResult?> _runGatedImage(
  AiValidationCreditsService credits,
  _MockValidationAI ai,
) {
  return credits.runGatedValidation<ValidationResult>(
    () => ai.analyzeProof(quest: _quest(), imageBytes: Uint8List(1)),
  );
}

/// Quête minimale pour les tests de gating.
Quest _quest() => Quest(
      userId: _userId,
      title: 'Méditation 10 min',
      estimatedDurationMinutes: 10,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: 'Bien-être',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
    );

/// Construit un [PlayerViewModel] avec un streak de départ [initialStreak].
/// Les appels réseau (fetchRemoteStats, syncToSupabase, saveLocalStats) sont stubbés.
Future<PlayerViewModel> _buildPlayerVM(
  _MockPlayerRepo repo, {
  required int initialStreak,
}) async {
  final stats = PlayerStats(streak: initialStreak);
  when(() => repo.loadLocalStats()).thenReturn(stats);
  when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});

  final vm = PlayerViewModel(repo);
  await vm.loadPlayerStats(_userId);
  return vm;
}

void main() {
  late _MockBox box;
  late _MockValidationAI ai;
  late _MockPlayerRepo playerRepo;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(_quest());
    registerFallbackValue(PlayerStats());
  });

  setUp(() {
    box = _MockBox();
    ai = _MockValidationAI();
    playerRepo = _MockPlayerRepo();
  });

  // ==========================================================================
  // GATING — runGatedValidation (le point d'entrée réel appelé par la page)
  // ==========================================================================

  void stubScore(int score, {bool isValid = true}) {
    when(
      () => ai.analyzeProof(
        quest: any(named: 'quest'),
        imageBytes: any(named: 'imageBytes'),
      ),
    ).thenAnswer(
      (_) async => ValidationResult(
        score: score,
        explanation: 'score $score',
        isValid: isValid,
      ),
    );
  }

  group('Gating — premium (balance ignorée)', () {
    test('premium : IA appelée, AUCUN décrément même à 0 crédit', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 0,
          isPremium: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      stubScore(90);

      final r = await _runGatedImage(credits, ai);

      verify(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).called(1);
      expect(r?.isValid, isTrue);
      expect(r?.score, 90);
      expect(credits.balance, 0); // aucun décrément pour un premium
    });

    test('premium avec crédits : balance non décrémentée', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 5,
          isPremium: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      stubScore(80);

      await _runGatedImage(credits, ai);

      expect(credits.balance, 5);
    });
  });

  group('Gating — non premium avec balance > 0', () {
    test('IA appelée + décrément de 1 AVANT l\'appel', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 3,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      int? balanceAuMomentAppelIA;
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenAnswer((_) async {
        // Le crédit doit être consommé AVANT que l'IA soit appelée.
        balanceAuMomentAppelIA = credits.balance;
        return const ValidationResult(
            score: 85, explanation: 'Bien', isValid: true);
      });

      final r = await _runGatedImage(credits, ai);

      verify(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).called(1);
      expect(balanceAuMomentAppelIA, 2); // déjà décrémenté avant l'appel
      expect(credits.balance, 2);
      expect(r?.score, 85);
    });

    test('balance 1 → 0 : la validation suivante est refusée (manuelle)', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 1,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      stubScore(75);

      // Première validation : consomme le dernier jeton.
      final r1 = await _runGatedImage(credits, ai);
      expect(r1, isNotNull);
      expect(credits.balance, 0);

      // Deuxième tentative : plus de crédits → null (route manuelle), IA non rappelée.
      final r2 = await _runGatedImage(credits, ai);
      expect(r2, isNull);
      verify(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).called(1); // une seule fois au total
    });
  });

  group('Gating — balance = 0 non premium', () {
    test('IA PAS appelée + route manuelle (null), balance inchangée', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 0,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final r = await _runGatedImage(credits, ai);

      verifyNever(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      );
      expect(r, isNull);
      expect(credits.balance, 0);
    });
  });

  // ==========================================================================
  // REMBOURSEMENT — erreur technique vs score bas
  // ==========================================================================

  group('Remboursement — erreur technique', () {
    test('IA qui throw (réseau) → jeton remboursé + null (manuel)', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 3,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenThrow(Exception('Erreur réseau : connexion perdue'));

      final r = await _runGatedImage(credits, ai);

      expect(r, isNull); // route manuelle
      expect(credits.balance, 3); // consume puis refund → net 0
    });

    test('IA qui throw (timeout) → jeton remboursé', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 2,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenThrow(Exception('TimeoutException : 30s dépassées'));

      final r = await _runGatedImage(credits, ai);

      expect(r, isNull);
      expect(credits.balance, 2); // remboursé
    });

    test('premium + erreur technique : aucun remboursement, pas de crash', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 0,
          isPremium: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      when(
        () => ai.analyzeProof(
          quest: any(named: 'quest'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenThrow(Exception('erreur serveur 529'));

      final r = await _runGatedImage(credits, ai);

      expect(r, isNull);
      expect(credits.balance, 0); // rien consommé/remboursé pour un premium
    });
  });

  group('Remboursement — score bas (<70) : PAS de remboursement', () {
    test('score 50 : résultat retourné, jeton consommé (l\'IA a tourné)', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 3,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      stubScore(50, isValid: false);

      final r = await _runGatedImage(credits, ai);

      // L'IA a retourné un résultat (score bas, pas d'exception) → pas null.
      expect(r?.score, 50);
      expect(r?.isValid, isFalse);
      // Jeton consommé et NON remboursé (3 → 2).
      expect(credits.balance, 2);
    });

    test('score 69 (seuil - 1) : jeton consommé, PAS remboursé', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 5,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      stubScore(69, isValid: false);

      await _runGatedImage(credits, ai);

      expect(credits.balance, 4);
    });

    test('score 70 (seuil exact) : jeton consommé, résultat valid', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 2,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      stubScore(70);

      final r = await _runGatedImage(credits, ai);

      expect(r?.isValid, isTrue);
      expect(r?.score, 70);
      expect(credits.balance, 1);
    });
  });

  // ==========================================================================
  // STREAK → gain de jetons via le vrai incrément
  // ==========================================================================

  group('Streak → gain de jetons via PlayerViewModel.updateStreak', () {
    test('atteindre 7 via updateStreak → +2 jetons (earnFromStreak)', () async {
      // Streak de départ = 6. Un jour de plus → streak = 7 → palier atteint.
      final player = await _buildPlayerVM(
        playerRepo,
        initialStreak: 6,
      );
      // On force lastActiveDate à hier pour simuler un jour de différence.
      final hier = DateTime.now().subtract(const Duration(days: 1));
      player.stats?.lastActiveDate; // lecture seule pour confirmer init
      // Mutation directe via le repo est impossible ici ; on simule avec
      // un rechargement forcé sur stats avec lastActiveDate = hier.
      // Approche : on crée un PlayerViewModel frais avec streak=6 et lastActiveDate=hier.
      final statsAvecHier = PlayerStats(
        streak: 6,
        lastActiveDate: DateTime(hier.year, hier.month, hier.day),
      );
      when(() => playerRepo.loadLocalStats()).thenReturn(statsAvecHier);
      when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      final playerAvecHier = PlayerViewModel(playerRepo);
      await playerAvecHier.loadPlayerStats(_userId);

      final credits = await _buildCredits(box);
      expect(credits.balance, 0);

      // Appel du vrai incrément de streak avec injection du service de crédits.
      await playerAvecHier.updateStreak(_userId, creditsService: credits);

      // Le streak doit être passé à 7.
      expect(playerAvecHier.stats?.streak, 7);

      // earnFromStreak(7) doit avoir accordé +2 jetons.
      expect(
        credits.balance,
        AiValidationCreditsService.kStreakMilestoneGrant,
      );
      expect(credits.lastRewardedStreakMilestone, 7);
    });

    test('re-déclencher streak = 7 → rien (idempotent)', () async {
      // Palier 7 déjà récompensé.
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 2,
          lastRewardedStreakMilestone: 7,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      // Appel direct de earnFromStreak (pilote le comportement attendu).
      await credits.earnFromStreak(7);

      // Aucun changement.
      expect(credits.balance, 2);
      expect(credits.lastRewardedStreakMilestone, 7);
    });

    test('atteindre 14 via updateStreak → +2 jetons supplémentaires', () async {
      // Streak de départ = 13 + lastActiveDate = hier.
      final hier = DateTime.now().subtract(const Duration(days: 1));
      final stats13 = PlayerStats(
        streak: 13,
        lastActiveDate: DateTime(hier.year, hier.month, hier.day),
      );
      when(() => playerRepo.loadLocalStats()).thenReturn(stats13);
      when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      final playerVM = PlayerViewModel(playerRepo);
      await playerVM.loadPlayerStats(_userId);

      // Palier 7 déjà récompensé mais pas 14.
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 2,
          lastRewardedStreakMilestone: 7,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await playerVM.updateStreak(_userId, creditsService: credits);

      // Streak passe à 14.
      expect(playerVM.stats?.streak, 14);

      // Palier 14 → +2 jetons.
      expect(credits.balance, 4); // 2 + 2
      expect(credits.lastRewardedStreakMilestone, 14);
    });

    test('streak = 6 (non multiple de 7) : aucun gain', () async {
      final hier = DateTime.now().subtract(const Duration(days: 1));
      final stats5 = PlayerStats(
        streak: 5,
        lastActiveDate: DateTime(hier.year, hier.month, hier.day),
      );
      when(() => playerRepo.loadLocalStats()).thenReturn(stats5);
      when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      final playerVM = PlayerViewModel(playerRepo);
      await playerVM.loadPlayerStats(_userId);

      final credits = await _buildCredits(box);
      expect(credits.balance, 0);

      await playerVM.updateStreak(_userId, creditsService: credits);

      // Streak passe à 6 (pas un palier).
      expect(playerVM.stats?.streak, 6);

      // Aucun gain de jeton.
      expect(credits.balance, 0);
    });

    test('updateStreak sans creditsService : aucun crash, comportement legacy intact',
        () async {
      final hier = DateTime.now().subtract(const Duration(days: 1));
      final stats = PlayerStats(
        streak: 6,
        lastActiveDate: DateTime(hier.year, hier.month, hier.day),
      );
      when(() => playerRepo.loadLocalStats()).thenReturn(stats);
      when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
      when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
      when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});

      final playerVM = PlayerViewModel(playerRepo);
      await playerVM.loadPlayerStats(_userId);

      // Sans service de crédits : aucun crash, le streak s'incrémente normalement.
      await expectLater(
        () => playerVM.updateStreak(_userId),
        returnsNormally,
      );

      expect(playerVM.stats?.streak, 7);
    });
  });

  // ==========================================================================
  // refundValidation — API publique du wallet
  // ==========================================================================

  group('refundValidation — remboursement', () {
    test('recrédite 1 jeton si balance < cap', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 2,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await credits.refundValidation();

      expect(credits.balance, 3);
    });

    test('no-op si premium (jamais consommé → pas à rembourser)', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 0,
          isPremium: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await credits.refundValidation();

      expect(credits.balance, 0); // inchangé
    });

    test('respecte le cap : balance déjà à 10 → no-op', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: AiValidationCreditsService.kFreeWalletCap,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await credits.refundValidation();

      expect(credits.balance, AiValidationCreditsService.kFreeWalletCap);
    });

    test('consume → refund : net = 0 (balance inchangée)', () async {
      final credits = await _buildCredits(
        box,
        initialState: AiValidationState(
          balance: 3,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await credits.consumeForValidation(); // balance = 2
      await credits.refundValidation();     // balance = 3

      expect(credits.balance, 3);
    });
  });
}
