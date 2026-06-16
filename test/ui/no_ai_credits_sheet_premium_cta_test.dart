import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/ui/widgets/common/no_ai_credits_sheet.dart';

/// Test du VRAI chemin : le bouton Premium du sheet déclenche réellement
/// [AiValidationCreditsService.startPremiumCheckout].
///
/// Anti-régression critique (leçon briques 3/4) :
/// on tape le bouton et on vérifie que le provider est appelé — pas juste
/// que le widget est présent.

// ---- Doubles de test ----

class _MockBox extends Mock implements Box<dynamic> {}

/// Sous-classe testable d'AiValidationCreditsService qui intercepte
/// [startPremiumCheckout] sans contacter Supabase ni le navigateur externe.
class _FakeCreditsService extends AiValidationCreditsService {
  _FakeCreditsService(_MockBox box) : super(box, testUserId: _userId);

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

// ---- Constantes de test ----

const _userId = 'user-sheet-cta';
const _hiveKey = 'ai_validation_$_userId';

// ---- Helpers ----

Future<_FakeCreditsService> _buildService(_MockBox box) async {
  when(() => box.get(_hiveKey)).thenReturn(
    AiValidationState(balance: 0, updatedAt: DateTime.now().toUtc()).toJson(),
  );
  when(() => box.put(any(), any())).thenAnswer((_) async {});

  final service = _FakeCreditsService(box);
  await service.load(_userId);
  return service;
}

/// Pompe le sheet dans un MaterialApp avec le provider.
Future<void> _pumpSheet(
  WidgetTester tester,
  _FakeCreditsService service,
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

  // Ouvre le sheet.
  await tester.tap(find.byKey(const Key('ouvrir_sheet')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _MockBox box;

  setUp(() {
    box = _MockBox();
  });

  // ==========================================================================
  // 1. Le bouton Premium est visible dans le sheet
  // ==========================================================================

  testWidgets('le CTA Premium est visible dans le sheet', (tester) async {
    final service = await _buildService(box);
    await _pumpSheet(tester, service);

    // Le bouton « Passer à Premium » doit être visible.
    expect(
      find.byKey(const Key('cta_premium')),
      findsOneWidget,
    );
  });

  // ==========================================================================
  // 2. Taper le CTA Premium appelle startPremiumCheckout — VRAI chemin
  // ==========================================================================

  testWidgets(
      'taper le CTA Premium appelle réellement startPremiumCheckout',
      (tester) async {
    final service = await _buildService(box);
    await _pumpSheet(tester, service);

    // Vérification préalable : pas encore appelé.
    expect(service.checkoutCalled, isFalse);

    // Tape le bouton Premium.
    final ctaBtn = find.byKey(const Key('cta_premium'));
    expect(ctaBtn, findsOneWidget);
    await tester.ensureVisible(ctaBtn);
    await tester.tap(ctaBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // startPremiumCheckout a été réellement appelé.
    expect(service.checkoutCalled, isTrue,
        reason:
            'startPremiumCheckout doit être appelé quand on tape le CTA Premium.');
  });

  // ==========================================================================
  // 3. Le sheet se ferme après avoir tapé le CTA Premium
  // ==========================================================================

  testWidgets('taper le CTA Premium ferme le sheet', (tester) async {
    final service = await _buildService(box);
    await _pumpSheet(tester, service);

    // Tape le CTA.
    final ctaBtn = find.byKey(const Key('cta_premium'));
    await tester.ensureVisible(ctaBtn);
    await tester.tap(ctaBtn);
    await tester.pumpAndSettle();

    // Le sheet doit être fermé (bouton CTA plus visible).
    expect(find.byKey(const Key('cta_premium')), findsNothing);
  });

  // ==========================================================================
  // 4. Le bouton « Continuer en manuel » est toujours présent
  // ==========================================================================

  testWidgets('le bouton "Continuer en manuel" coexiste avec le CTA Premium',
      (tester) async {
    final service = await _buildService(box);
    await _pumpSheet(tester, service);

    expect(find.byKey(const Key('continuer_en_manuel')), findsOneWidget);
    expect(find.byKey(const Key('cta_premium')), findsOneWidget);
  });

  // ==========================================================================
  // 5. AiCreditCounter : réactivité après refreshEntitlement
  // ==========================================================================

  testWidgets(
      'isPremium → true après setPremium : le service notifie les listeners',
      (tester) async {
    final service = await _buildService(box);

    var notified = false;
    service.addListener(() => notified = true);

    // Simule un refresh entitlement (premium activé).
    await service.setPremium(true);

    expect(notified, isTrue);
    expect(service.isPremium, isTrue);
  });
}
