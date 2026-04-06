import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/ui/widgets/common/quest_detail_sheet.dart';

Quest _makeQuest({bool completed = false, bool hasSubQuests = false}) => Quest(
      id: 'q1',
      userId: 'u1',
      title: 'Quête de test',
      description: 'Une description',
      estimatedDurationMinutes: 30,
      frequency: QuestFrequency.daily,
      difficulty: 3,
      category: 'Sport',
      rarity: QuestRarity.rare,
      status: completed ? QuestStatus.completed : QuestStatus.active,
      subQuests: hasSubQuests ? ['Étape 1', 'Étape 2'] : [],
    );

Widget _buildSheet(
  Quest quest, {
  VoidCallback? onValidate,
  VoidCallback? onDelete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: QuestDetailSheet(
        quest: quest,
        onValidate: onValidate,
        onDelete: onDelete,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('QuestDetailSheet', () {
    testWidgets('affiche le titre de la quête', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest()));
      await tester.pump();

      expect(find.text('Quête de test'), findsOneWidget);
    });

    testWidgets('affiche la description', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest()));
      await tester.pump();

      expect(find.text('Une description'), findsOneWidget);
    });

    testWidgets('affiche le badge de rareté', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest()));
      await tester.pump();

      expect(find.text('Rare'), findsOneWidget);
    });

    testWidgets('affiche les chips de méta-infos', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest()));
      await tester.pump();

      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('affiche le bouton Valider si quête non terminée et onValidate fourni',
        (tester) async {
      await tester.pumpWidget(_buildSheet(
        _makeQuest(),
        onValidate: () {},
      ));
      await tester.pump();

      expect(find.text('Valider la quête'), findsOneWidget);
    });

    testWidgets('n\'affiche pas le bouton Valider si quête terminée', (tester) async {
      await tester.pumpWidget(_buildSheet(
        _makeQuest(completed: true),
        onValidate: () {},
      ));
      await tester.pump();

      expect(find.text('Valider la quête'), findsNothing);
    });

    testWidgets('n\'affiche pas le bouton Valider si onValidate est null', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest()));
      await tester.pump();

      expect(find.text('Valider la quête'), findsNothing);
    });

    testWidgets('affiche le bouton Supprimer si onDelete fourni', (tester) async {
      await tester.pumpWidget(_buildSheet(
        _makeQuest(),
        onDelete: () {},
      ));
      await tester.pump();

      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('n\'affiche pas le bouton Supprimer si onDelete est null', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest()));
      await tester.pump();

      expect(find.text('Supprimer'), findsNothing);
    });

    testWidgets('affiche la pastille "Terminée" si quête complétée', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest(completed: true)));
      await tester.pump();

      expect(find.text('Terminée'), findsOneWidget);
    });

    testWidgets('affiche les sous-tâches cochables si présentes', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest(hasSubQuests: true)));
      await tester.pump();

      expect(find.text('Sous-tâches'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      // Les items peuvent être hors écran dans le sheet — on vérifie sans skipOffstage
      expect(find.text('Étape 1', skipOffstage: false), findsOneWidget);
      expect(find.text('Étape 2', skipOffstage: false), findsOneWidget);
    });

    testWidgets('cocher une sous-tâche met à jour le compteur', (tester) async {
      await tester.pumpWidget(_buildSheet(_makeQuest(hasSubQuests: true)));
      await tester.pump();

      await tester.tap(find.text('Étape 1'));
      await tester.pump();

      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('appuyer sur Valider ferme le sheet et appelle le callback',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => QuestDetailSheet.show(
                ctx,
                quest: _makeQuest(),
                onValidate: () => called = true,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Valider la quête'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
