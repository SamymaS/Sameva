import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/config/ai_credits_labels.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/validation_ai_service.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/ui/pages/quest/quest_validation_page.dart';
import 'package:sameva/ui/widgets/common/ai_credit_counter.dart';

/// Tests de la brique 5 : UI du wallet de jetons IA.
///
/// Pilotage par le VRAI widget (même pattern que quest_validation_gating_widget_test).
/// Aucun helper interne n'est testé directement ; on tape l'UI réelle.

class _MockBox extends Mock implements Box<dynamic> {}

class _MockValidationAI extends Mock implements ValidationAIService {}

const _userId = 'user-brique5-wallet';
const _hiveKey = 'ai_validation_$_userId';

Quest _aiQuest() => Quest(
      userId: _userId,
      title: 'Sport 20 min',
      estimatedDurationMinutes: 20,
      frequency: QuestFrequency.oneOff,
      difficulty: 2,
      category: 'Santé',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
      validationType: ValidationType.ai,
    );

Future<AiValidationCreditsService> _buildCredits(
  _MockBox box,
  AiValidationState initial,
) async {
  when(() => box.get(_hiveKey)).thenReturn(initial.toJson());
  when(() => box.put(any(), any())).thenAnswer((_) async {});
  final service = AiValidationCreditsService(box, testUserId: _userId);
  await service.load(_userId);
  return service;
}

/// Pompe la page de validation avec les providers minimaux requis.
Future<void> _pumpValidationPage(
  WidgetTester tester, {
  required AiValidationCreditsService credits,
  required ValidationAIService ai,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AiValidationCreditsService>.value(
      value: credits,
      child: MaterialApp(
        home: QuestValidationPage(
          quest: _aiQuest(),
          validationService: ai,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Saisit du texte et tape « Faire analyser », puis laisse le cycle async se terminer.
Future<void> _enterTextAndTapAnalyze(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'J\'ai fait du sport 20 minutes.');
  await tester.pump();
  final btn = find.widgetWithText(FilledButton, 'Faire analyser');
  await tester.ensureVisible(btn);
  await tester.tap(btn);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(_aiQuest());
  });

  late _MockBox box;
  late _MockValidationAI ai;

  setUp(() {
    box = _MockBox();
    ai = _MockValidationAI();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 1. AiCreditCounter — widget autonome
  // ──────────────────────────────────────────────────────────────────────────

  group('AiCreditCounter', () {
    /// Helper : pompe le compteur seul dans un Provider.
    Future<void> pumpCounter(
      WidgetTester tester,
      AiValidationCreditsService credits,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AiValidationCreditsService>.value(
          value: credits,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: AiCreditCounter())),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('affiche le solde numérique pour un utilisateur non premium',
        (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(balance: 3, updatedAt: DateTime.now().toUtc()),
      );
      await pumpCounter(tester, credits);

      // Le solde « 3 » doit apparaître dans le compteur.
      expect(find.text('3'), findsOneWidget);

      // Le libellé kAiCreditLabel doit apparaître (via la constante).
      expect(find.text(kAiCreditLabel), findsOneWidget);

      // Le symbole infini et « Premium » ne doivent PAS apparaître.
      expect(find.text('∞'), findsNothing);
      expect(find.text('Premium'), findsNothing);
    });

    testWidgets('affiche "∞" et "Premium" pour un utilisateur premium',
        (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(
          balance: 0,
          isPremium: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await pumpCounter(tester, credits);

      // Premium : symbole infini et libellé Premium.
      expect(find.text('∞'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);

      // Le solde numérique ne doit PAS apparaître.
      expect(find.text('0'), findsNothing);
    });

    testWidgets('le libellé correspond à kAiCreditLabel (pas de hardcode)',
        (tester) async {
      // Ce test vérifie que le widget utilise la constante, pas un libellé en dur.
      final credits = await _buildCredits(
        box,
        AiValidationState(balance: 1, updatedAt: DateTime.now().toUtc()),
      );
      await pumpCounter(tester, credits);

      // On cherche EXACTEMENT le texte produit par la constante.
      expect(find.text(kAiCreditLabel), findsOneWidget);
      // Si quelqu'un hardcode « Jeton IA » ou autre, ce test tombera.
      expect(find.text('Jeton IA'), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Sheet « plus de jetons » — déclenchement depuis la vraie page
  // ──────────────────────────────────────────────────────────────────────────

  group('Sheet "plus de jetons"', () {
    testWidgets(
        'à 0 jeton non premium : "Faire analyser" affiche le sheet '
        '(bouton "Continuer en manuel" visible)', (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(balance: 0, updatedAt: DateTime.now().toUtc()),
      );
      // Le mock IA ne doit jamais être appelé.
      when(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          )).thenAnswer((_) async =>
          const ValidationResult(score: 88, explanation: 'Bien', isValid: true));

      await _pumpValidationPage(tester, credits: credits, ai: ai);
      await _enterTextAndTapAnalyze(tester);

      // Laisse le showModalBottomSheet s'afficher.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Le sheet doit être visible avec le bouton « Continuer en manuel ».
      expect(
        find.byKey(const Key('continuer_en_manuel')),
        findsOneWidget,
      );

      // L'IA ne doit PAS avoir été appelée (gating effectif).
      verifyNever(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          ));
    });

    testWidgets(
        '"Continuer en manuel" ferme le sheet et l\'IA reste non appelée',
        (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(balance: 0, updatedAt: DateTime.now().toUtc()),
      );
      when(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          )).thenAnswer((_) async =>
          const ValidationResult(score: 88, explanation: 'Bien', isValid: true));

      await _pumpValidationPage(tester, credits: credits, ai: ai);
      await _enterTextAndTapAnalyze(tester);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tape le bouton « Continuer en manuel ».
      final btnContinuer = find.byKey(const Key('continuer_en_manuel'));
      expect(btnContinuer, findsOneWidget);
      // ensureVisible fait défiler vers le bouton (le sheet peut déborder en test).
      await tester.ensureVisible(btnContinuer);
      await tester.pump();
      await tester.tap(btnContinuer, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Le sheet doit être fermé.
      expect(find.byKey(const Key('continuer_en_manuel')), findsNothing);

      // L'IA ne doit PAS avoir été appelée.
      verifyNever(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          ));

      // Le solde reste à 0 (aucune consommation).
      expect(credits.balance, 0);
    });

    testWidgets(
        'à 0 jeton PREMIUM : "Faire analyser" appelle l\'IA sans afficher le sheet',
        (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(
          balance: 0,
          isPremium: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      when(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          )).thenAnswer((_) async =>
          const ValidationResult(score: 91, explanation: 'Parfait', isValid: true));

      await _pumpValidationPage(tester, credits: credits, ai: ai);
      await _enterTextAndTapAnalyze(tester);

      // Draine le Timer de la notification éventuelle.
      await tester.pump(const Duration(seconds: 4));

      // Le sheet ne doit PAS apparaître (premium = jetons illimités).
      expect(find.byKey(const Key('continuer_en_manuel')), findsNothing);

      // L'IA DOIT avoir été appelée.
      verify(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          )).called(1);
    });

    testWidgets(
        'le sheet mentionne kAiCreditLabelPlural (pas de libellé hardcodé)',
        (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(balance: 0, updatedAt: DateTime.now().toUtc()),
      );
      when(() => ai.analyzeTextProof(
            quest: any(named: 'quest'),
            text: any(named: 'text'),
          )).thenAnswer((_) async =>
          const ValidationResult(score: 88, explanation: 'Bien', isValid: true));

      await _pumpValidationPage(tester, credits: credits, ai: ai);
      await _enterTextAndTapAnalyze(tester);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Le titre du sheet doit contenir le libellé pluriel.
      expect(
        find.textContaining(kAiCreditLabelPlural),
        findsWidgets,
      );
      // Aucun libellé hardcodé « Jeton IA » ne doit apparaître.
      expect(find.textContaining('Jeton IA'), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Compteur visible dans la page de validation (AppBar)
  // ──────────────────────────────────────────────────────────────────────────

  group('Compteur dans QuestValidationPage', () {
    testWidgets(
        'affiche le compteur dans l\'AppBar pour une quête de type AI',
        (tester) async {
      final credits = await _buildCredits(
        box,
        AiValidationState(balance: 5, updatedAt: DateTime.now().toUtc()),
      );
      await _pumpValidationPage(tester, credits: credits, ai: ai);

      // Le compteur doit être visible dans la page.
      expect(find.byType(AiCreditCounter), findsOneWidget);
      // Le solde « 5 » doit être affiché.
      expect(find.text('5'), findsOneWidget);
    });
  });
}
