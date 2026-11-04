import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';
import 'package:sameva/ui/pages/quest/quest_calendar_page.dart';

class _MockQuestRepository extends Mock implements QuestRepository {}

void main() {
  testWidgets('calendrier pixel : semaine, quête du jour, navigation', (tester) async {
    final now = DateTime.now();
    final repo = _MockQuestRepository();
    when(() => repo.loadQuests(any())).thenAnswer((_) async => [
          Quest(
            id: 'q1',
            userId: 'u1',
            title: 'Arroser les plantes',
            difficulty: 3,
            category: 'Maison',
            rarity: QuestRarity.common,
            frequency: QuestFrequency.oneOff,
            status: QuestStatus.active,
            validationType: ValidationType.manual,
            estimatedDurationMinutes: 10,
            deadline: DateTime(now.year, now.month, now.day, 18, 30),
          ),
        ]);
    final vm = QuestViewModel(repo);
    await vm.loadQuests('u1');

    await tester.binding.setSurfaceSize(const Size(412, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider<QuestViewModel>.value(
      value: vm,
      child: const MaterialApp(home: QuestCalendarPage()),
    ));
    await tester.pump();

    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Arroser les plantes'), findsOneWidget);
    expect(find.text('Avant 18:30'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Difficulté 3 sur 4')), findsOneWidget);
    // Six autres jours vides.
    expect(find.text('Aucune quête'), findsNWidgets(6));

    await tester.tap(find.bySemanticsLabel('Semaine suivante'));
    await tester.pump();
    expect(find.text('Cette semaine'), findsNothing);
    expect(find.textContaining(' au '), findsOneWidget);
    expect(find.text('Aucune quête'), findsNWidgets(7));

    await tester.tap(find.bySemanticsLabel('Semaine précédente'));
    await tester.pump();
    expect(find.text('Cette semaine'), findsOneWidget);
  });
}
