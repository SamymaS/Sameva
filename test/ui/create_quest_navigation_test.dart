import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';
import 'package:sameva/ui/pages/quest/create_quest_choice_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockQuestRepository extends Mock implements QuestRepository {}
class _MockUser extends Mock implements User {}

/// Construit une app avec une page racine "ListePage" qui pousse
/// CreateQuestChoicePage. Après création, on doit revenir sur "ListePage".
Widget _buildApp() {
  final authRepo = _MockAuthRepository();
  final mockUser = _MockUser();
  when(() => mockUser.id).thenReturn('u1');
  when(() => mockUser.email).thenReturn('test@sameva.app');
  when(() => authRepo.currentUser).thenReturn(mockUser);
  when(() => authRepo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  final authVm = AuthViewModel(authRepo);

  final questRepo = _MockQuestRepository();
  when(() => questRepo.addQuest(any())).thenAnswer((_) async => Quest(
        userId: 'u1',
        title: 'Sport sprint',
        difficulty: 1,
        category: 'Sport',
        rarity: QuestRarity.common,
        frequency: QuestFrequency.oneOff,
        status: QuestStatus.active,
        validationType: ValidationType.manual,
        estimatedDurationMinutes: 15,
      ));
  when(() => questRepo.loadQuests(any())).thenAnswer((_) async => []);
  final questVm = QuestViewModel(questRepo);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ChangeNotifierProvider<QuestViewModel>.value(value: questVm),
    ],
    child: MaterialApp(
      home: _ListePageRoot(),
    ),
  );
}

/// Page racine simulant la QuestsListPage — affiche "ListePage" en titre.
class _ListePageRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListePage')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                  builder: (_) => const CreateQuestChoicePage()),
            );
          },
          child: const Text('Créer une quête'),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(Quest(
      userId: '',
      title: '',
      difficulty: 1,
      category: '',
      rarity: QuestRarity.common,
      frequency: QuestFrequency.oneOff,
      status: QuestStatus.active,
      validationType: ValidationType.manual,
      estimatedDurationMinutes: 30,
    ));
    final dir =
        await Directory.systemTemp.createTemp('hive_create_quest_nav_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  group('Navigation CreateQuestByThemePage → retour robuste', () {
    testWidgets(
        'créer une quête par thème retourne à la ListePage (pas sur CreateQuestChoicePage)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      // On est sur ListePage
      expect(find.text('ListePage'), findsOneWidget);

      // Navigue vers CreateQuestChoicePage
      await tester.tap(find.text('Créer une quête'));
      await tester.pumpAndSettle();

      // On est sur CreateQuestChoicePage
      expect(find.text('Créer une quête'), findsWidgets); // titre AppBar
      expect(find.text('ListePage'), findsNothing);

      // Tape "Par thème"
      await tester.tap(find.text('Par thème (Sport, Loisir, Maison)'));
      await tester.pumpAndSettle();

      // On est sur CreateQuestByThemePage — sélectionne le thème "Sport"
      expect(find.text('Choisir un thème'), findsOneWidget);
      await tester.tap(find.text('Sport'));
      await tester.pumpAndSettle();

      // La liste des templates Sport s'affiche — tape le premier item
      final premierTemplate = find.byType(ListTile).first;
      expect(premierTemplate, findsOneWidget);
      await tester.tap(premierTemplate);
      await tester.pumpAndSettle();

      // La dialog de confirmation s'affiche — confirme la création
      expect(find.text('Créer la quête'), findsOneWidget);
      await tester.tap(find.text('Créer la quête'));
      await tester.pumpAndSettle();

      // Après création, on doit être revenu sur ListePage
      // (les deux routes intermédiaires ont été dépilées)
      expect(find.text('ListePage'), findsOneWidget);
      // CreateQuestChoicePage et CreateQuestByThemePage ne sont plus visibles
      expect(find.text('Choisir un thème'), findsNothing);

      // AppNotification.show crée un Timer non-périodique de 3s pour
      // l'auto-dismiss. Pomper 4s le fait expirer proprement afin d'éviter
      // l'assertion "Timer still pending" du framework de test.
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
