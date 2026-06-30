import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/repositories/premium_subscription_repository.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/ui/widgets/common/ai_credit_counter.dart';
import 'package:sameva/ui/widgets/common/no_ai_credits_sheet.dart';

/// Tests widget du hot-refresh entitlement premium Stripe (côté client Flutter).
///
/// Test 1 — Poll backoff : après retour de checkout, le poll avec backoff
/// propage `isPremium=true` à l'UI (AiCreditCounter) SANS redémarrage de l'app.
/// Simule la latence du webhook (repo qui renvoie false puis true).
///
/// Test 2 — Garde paywall : quand le service est déjà premium, le CTA
/// « Passer à Premium » ne déclenche PAS [startPremiumCheckout] (double guard
/// UI + service empêche le double-checkout).
///
/// NOTE technique : les appels à [onAppResumedAfterCheckout] sont enveloppés dans
/// [tester.runAsync] car cette méthode utilise [Future.delayed] en interne.
/// [Future.delayed] crée des timers qui ne s'exécutent pas dans la zone FakeAsync
/// de [testWidgets] sans avancement explicite du temps. [tester.runAsync] suspend
/// la zone fake-async et laisse les vrais timers se déclencher.

// ── Doubles de test ──────────────────────────────────────────────────────────

class _MockBox extends Mock implements Box<dynamic> {}

class _MockPremiumRepo extends Mock implements PremiumSubscriptionRepository {}

/// Sous-classe testable qui intercepte [startPremiumCheckout] sans ouvrir le
/// navigateur externe, et enregistre si l'appel a eu lieu.
class _FakeCreditsService extends AiValidationCreditsService {
  _FakeCreditsService(super.box) : super(testUserId: _userId);

  var checkoutCalled = false;

  @override
  Future<void> startPremiumCheckout({
    // ignore: avoid_unused_constructor_parameters
    dynamic supabaseClient,
    Future<String?> Function()? checkoutUrlProvider,
  }) async {
    checkoutCalled = true;
  }
}

// ── Constantes de test ───────────────────────────────────────────────────────

const _userId = 'user-hot-refresh-test';
const _hiveKey = 'ai_validation_$_userId';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Prépare les stubs de box (get + put) pour [_hiveKey].
void _stubBox(_MockBox box, {AiValidationState? initialState}) {
  if (initialState != null) {
    when(() => box.get(_hiveKey)).thenReturn(initialState.toJson());
  } else {
    when(() => box.get(_hiveKey)).thenReturn(null);
  }
  when(() => box.put(any(), any())).thenAnswer((_) async {});
}

/// Construit un [AiValidationCreditsService] réel (sans fake checkout) avec
/// un repo premium mocké, pour tester le poll backoff jusqu'à la couche widget.
///
/// DOIT être appelé dans [tester.runAsync] car [load] est asynchrone.
Future<AiValidationCreditsService> _buildRealService(
  _MockBox box, {
  required _MockPremiumRepo premiumRepo,
}) async {
  _stubBox(box);
  final service = AiValidationCreditsService(
    box,
    premiumRepository: premiumRepo,
    testUserId: _userId,
  );
  await service.load(_userId);
  return service;
}

/// Construit un [_FakeCreditsService] avec l'état initial fourni en Hive.
///
/// DOIT être appelé dans [tester.runAsync] car [load] est asynchrone.
Future<_FakeCreditsService> _buildFakeService(
  _MockBox box,
  AiValidationState initialState,
) async {
  _stubBox(box, initialState: initialState);
  final service = _FakeCreditsService(box);
  await service.load(_userId);
  return service;
}

/// Pompe l'[AiCreditCounter] dans un arbre minimal avec le service en Provider.
Future<void> _pumpCounter(
  WidgetTester tester,
  AiValidationCreditsService service,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AiValidationCreditsService>.value(
      value: service,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: AiCreditCounter())),
      ),
    ),
  );
  await tester.pump();
}

/// Pompe le sheet « plus de jetons » via un bouton déclencheur.
Future<void> _pumpAndOpenSheet(
  WidgetTester tester,
  AiValidationCreditsService service,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AiValidationCreditsService>.value(
      value: service,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('ouvrir_sheet'),
                onPressed: () => showNoAiCreditsSheet(context),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.byKey(const Key('ouvrir_sheet')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _MockBox box;
  late _MockPremiumRepo premiumRepo;

  setUp(() {
    box = _MockBox();
    premiumRepo = _MockPremiumRepo();
  });

  // ==========================================================================
  // Test 1 — Poll backoff : l'UI se reconstruit en premium sans redémarrage
  // ==========================================================================

  group('Poll backoff — entitlement premium propagé à l\'UI', () {
    testWidgets(
      'après retour de checkout, quand le repo bascule isPremium=true, '
      'AiCreditCounter affiche "∞ Premium" sans redémarrage',
      (tester) async {
        // Le repo renvoie false les 3 premières invocations (1 = load + 2 = poll),
        // puis true à la 4ème (poll attempt 2).
        // Séquence : load(1)→false | poll0(2)→false | poll1(3)→false | poll2(4)→true
        var callCount = 0;
        when(() => premiumRepo.fetchForUser(_userId)).thenAnswer((_) async {
          callCount++;
          return callCount >= 4
              ? const PremiumEntitlement(isPremium: true)
              : const PremiumEntitlement.libre();
        });

        // tester.runAsync : suspend le FakeAsync de testWidgets pour autoriser
        // le code asynchrone réel (load appelle des mocks async).
        final service = await tester.runAsync(
          () => _buildRealService(box, premiumRepo: premiumRepo),
        );

        // Vérification préalable : non premium après load (call 1 = false).
        expect(service!.isPremium, isFalse);
        expect(callCount, 1);

        // Pompe le widget — affiche le solde freemium (0 jeton).
        await _pumpCounter(tester, service);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('Premium'), findsNothing);
        expect(find.text('∞'), findsNothing);

        // Positionne _checkoutInitiated = true via le helper de test.
        // (startPremiumCheckout avec vraie URL ferait pendre le test car
        // launchUrl n'est pas disponible en environnement de test sur Windows.)
        service.markCheckoutInitiatedForTest();

        // Lance le poll avec délais zéro (court-circuite les vrais backoffs).
        // Enveloppé dans tester.runAsync car Future.delayed(Duration.zero) crée
        // un vrai timer qui ne s'exécute pas dans la zone FakeAsync par défaut.
        await tester.runAsync(() async {
          await service.onAppResumedAfterCheckout(
            delayProvider: (_) => Duration.zero,
          );
        });

        // Le poll a réussi à la 4ème invocation du repo.
        expect(service.isPremium, isTrue,
            reason: 'isPremium doit basculer true après la 4ème réponse du repo');
        expect(callCount, greaterThanOrEqualTo(4));

        // Laisse Flutter reconstruire le widget suite au notifyListeners.
        await tester.pump();

        // AiCreditCounter doit afficher le statut Premium.
        expect(
          find.text('∞'),
          findsOneWidget,
          reason:
              'AiCreditCounter doit afficher "∞" immédiatement après '
              'confirmation premium, SANS redémarrage de l\'app',
        );
        expect(
          find.text('Premium'),
          findsOneWidget,
          reason: 'AiCreditCounter doit afficher "Premium" après confirmation',
        );
        expect(
          find.text('0'),
          findsNothing,
          reason:
              'Le solde numérique ne doit plus être affiché en mode premium',
        );
      },
    );

    testWidgets(
      'poll épuisé sans succès : isPremium reste false, '
      'un second resume ne relance PAS de poll (_checkoutInitiated remis à false)',
      (tester) async {
        // Le repo renvoie toujours false (webhook jamais arrivé).
        when(() => premiumRepo.fetchForUser(_userId))
            .thenAnswer((_) async => const PremiumEntitlement.libre());

        final service = await tester.runAsync(() async {
          _stubBox(box);
          final svc = AiValidationCreditsService(
            box,
            premiumRepository: premiumRepo,
            testUserId: _userId,
          );
          await svc.load(_userId);
          return svc;
        });

        expect(service!.isPremium, isFalse);

        // Positionne _checkoutInitiated = true.
        service.markCheckoutInitiatedForTest();

        // Poll avec délais zéro → 8 tentatives → épuisement sans succès.
        await tester.runAsync(() async {
          await service.onAppResumedAfterCheckout(
            delayProvider: (_) => Duration.zero,
          );
        });

        expect(service.isPremium, isFalse,
            reason: 'isPremium reste false si le webhook n\'est jamais arrivé');

        // Après épuisement, _checkoutInitiated est remis à false.
        // Un second resume ne doit déclencher AUCUN appel supplémentaire au repo.
        var callsApresEpuisement = 0;
        when(() => premiumRepo.fetchForUser(_userId)).thenAnswer((_) async {
          callsApresEpuisement++;
          return const PremiumEntitlement.libre();
        });

        await tester.runAsync(() async {
          await service.onAppResumedAfterCheckout(
            delayProvider: (_) => Duration.zero,
          );
        });

        expect(callsApresEpuisement, 0,
            reason:
                '_checkoutInitiated est false après épuisement → aucun poll '
                'supplémentaire ne doit être lancé au resume suivant');
      },
    );
  });

  // ==========================================================================
  // Test 2 — Garde paywall : CTA Premium inaccessible quand déjà premium
  // ==========================================================================

  group('Garde paywall — checkout bloqué si déjà premium', () {
    testWidgets(
      'CTA Premium ne déclenche PAS startPremiumCheckout si isPremium=true '
      '(garde UI défensive dans no_ai_credits_sheet.dart)',
      (tester) async {
        // Service premium (isPremium = true via Hive).
        final service = await tester.runAsync(
          () => _buildFakeService(
            box,
            AiValidationState(
              balance: 0,
              isPremium: true,
              updatedAt: DateTime.now().toUtc(),
            ),
          ),
        );

        expect(service!.isPremium, isTrue);
        expect(service.checkoutCalled, isFalse);

        // Ouvre le sheet « plus de jetons » (edge case : ouvert avant que le
        // poll confirme le premium — la garde doit protéger même dans ce cas).
        await _pumpAndOpenSheet(tester, service);

        // Le CTA doit être visible dans le sheet.
        final ctaBtn = find.byKey(const Key('cta_premium'));
        expect(ctaBtn, findsOneWidget);

        // Tape le CTA et laisse l'animation de fermeture du sheet se terminer.
        await tester.ensureVisible(ctaBtn);
        await tester.tap(ctaBtn);
        await tester.pumpAndSettle(); // idem au test « taper le CTA Premium ferme le sheet »

        // La garde UI `if (svc.isPremium)` doit avoir bloqué l'appel.
        expect(
          service.checkoutCalled,
          isFalse,
          reason:
              'startPremiumCheckout ne doit PAS être appelé quand isPremium=true '
              '— risque financier de double-checkout',
        );

        // La garde ferme le sheet proprement (UX cohérente).
        expect(
          find.byKey(const Key('cta_premium')),
          findsNothing,
          reason: 'Le sheet doit être fermé même quand la garde bloque le checkout',
        );
      },
    );

    testWidgets(
      'CTA Premium DÉCLENCHE startPremiumCheckout quand isPremium=false '
      '(contrôle positif — la garde ne bloque pas à tort)',
      (tester) async {
        // Service non premium.
        final service = await tester.runAsync(
          () => _buildFakeService(
            box,
            AiValidationState(
              balance: 0,
              isPremium: false,
              updatedAt: DateTime.now().toUtc(),
            ),
          ),
        );

        expect(service!.isPremium, isFalse);
        expect(service.checkoutCalled, isFalse);

        // Ouvre le sheet.
        await _pumpAndOpenSheet(tester, service);

        // Tape le CTA Premium.
        final ctaBtn = find.byKey(const Key('cta_premium'));
        await tester.ensureVisible(ctaBtn);
        await tester.tap(ctaBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Pas premium → la garde ne s'active pas → startPremiumCheckout est appelé.
        expect(
          service.checkoutCalled,
          isTrue,
          reason:
              'startPremiumCheckout DOIT être appelé quand isPremium=false et '
              'que le CTA est tapé',
        );
      },
    );
  });
}
