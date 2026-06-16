import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/ai_validation_state_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/domain/services/validation_ai_service.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/ui/pages/quest/quest_validation_page.dart';

/// Test du VRAI chemin : on pilote la page de validation (preuve texte) à
/// travers son UI réelle pour prouver que le gating crédits est bien câblé.
/// (Le bug récurrent des briques précédentes : la logique existait mais n'était
/// jamais appelée par la page. Ici on tape réellement le bouton « Faire analyser ».)

class _MockBox extends Mock implements Box<dynamic> {}

class _MockValidationAI extends Mock implements ValidationAIService {}

const _userId = 'user-widget-gating';
const _hiveKey = 'ai_validation_$_userId';

Quest _aiQuest() => Quest(
      userId: _userId,
      title: 'Méditation 10 min',
      estimatedDurationMinutes: 10,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: 'Bien-être',
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

Future<void> _pumpPage(
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

Future<void> _enterTextAndAnalyze(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'J\'ai médité 10 minutes.');
  await tester.pump();
  final btn = find.widgetWithText(FilledButton, 'Faire analyser');
  await tester.ensureVisible(btn);
  await tester.tap(btn);
  // Laisse l'analyse asynchrone (gating + appel IA mocké) se terminer.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // Draine le Timer d'auto-fermeture de la notification (route manuelle :
  // AppNotification s'efface après 3s) pour éviter « Timer still pending ».
  await tester.pump(const Duration(seconds: 4));
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

  testWidgets('balance > 0 non premium : IA appelée + 1 crédit consommé',
      (tester) async {
    final credits = await _buildCredits(
      box,
      AiValidationState(balance: 3, updatedAt: DateTime.now().toUtc()),
    );
    when(() => ai.analyzeTextProof(
          quest: any(named: 'quest'),
          text: any(named: 'text'),
        )).thenAnswer((_) async =>
        const ValidationResult(score: 88, explanation: 'Bien', isValid: true));

    await _pumpPage(tester, credits: credits, ai: ai);
    await _enterTextAndAnalyze(tester);

    verify(() => ai.analyzeTextProof(
          quest: any(named: 'quest'),
          text: any(named: 'text'),
        )).called(1);
    expect(credits.balance, 2); // décrémenté
  });

  testWidgets('balance = 0 non premium : IA PAS appelée (route manuelle)',
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

    await _pumpPage(tester, credits: credits, ai: ai);
    await _enterTextAndAnalyze(tester);

    // Le gating a bloqué l'appel IA : l'utilisateur valide manuellement.
    verifyNever(() => ai.analyzeTextProof(
          quest: any(named: 'quest'),
          text: any(named: 'text'),
        ));
    expect(credits.balance, 0);
  });

  testWidgets('premium à 0 crédit : IA appelée, aucun décrément',
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

    await _pumpPage(tester, credits: credits, ai: ai);
    await _enterTextAndAnalyze(tester);

    verify(() => ai.analyzeTextProof(
          quest: any(named: 'quest'),
          text: any(named: 'text'),
        )).called(1);
    expect(credits.balance, 0); // premium ne consomme jamais
  });
}
