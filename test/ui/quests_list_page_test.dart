import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/ui/pages/quest/quests_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockQuestRepository extends Mock implements QuestRepository {}
class _MockUser extends Mock implements User {}

Widget _buildQuestsList({
  AuthViewModel? authVm,
  QuestRepository? questRepo,
  List<Quest> quests = const [],
}) {
  final repo = questRepo ?? _makeQuestRepo(quests);
  final auth = authVm ?? _makeAuthVm();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: auth),
      Provider<QuestRepository>.value(value: repo),
    ],
    child: const MaterialApp(
      home: QuestsListPage(),
      onGenerateRoute: _generateRoute,
    ),
  );
}

Route<dynamic>? _generateRoute(RouteSettings s) =>
    MaterialPageRoute(builder: (_) => Scaffold(body: Text(s.name ?? '')));

AuthViewModel _makeAuthVm({String? userId = 'u1'}) {
  final repo = _MockAuthRepository();
  final user = _MockUser();
  when(() => user.id).thenReturn(userId ?? 'u1');
  when(() => user.email).thenReturn('hero@sameva.app');
  when(() => repo.currentUser).thenReturn(userId != null ? user : null);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

QuestRepository _makeQuestRepo(List<Quest> quests) {
  final repo = _MockQuestRepository();
  when(() => repo.loadQuests(any())).thenAnswer((_) async => quests);
  return repo;
}

Quest _makeQuest({
  required String id,
  String title = 'Quête test',
  QuestStatus status = QuestStatus.active,
}) =>
    Quest(
      id: id,
      userId: 'u1',
      title: title,
      estimatedDurationMinutes: 30,
      frequency: QuestFrequency.daily,
      difficulty: 2,
      category: 'Sport',
      rarity: QuestRarity.common,
      status: status,
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('QuestsListPage', () {
    testWidgets('affiche le titre "Quêtes"', (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quêtes'), findsOneWidget);
    });

    testWidgets('affiche l\'icône de recherche', (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('affiche les onglets À faire et Terminées', (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('À faire'), findsOneWidget);
      expect(find.text('Terminées'), findsOneWidget);
    });

    testWidgets('affiche le FAB pour créer une quête', (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('affiche l\'état vide si aucune quête active', (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Aucune quête en cours'), findsOneWidget);
    });

    testWidgets('affiche les cards de quêtes actives', (tester) async {
      final quests = [
        _makeQuest(id: 'q1', title: 'Courir 5km'),
        _makeQuest(id: 'q2', title: 'Méditer 10 min'),
      ];
      await tester.pumpWidget(_buildQuestsList(quests: quests));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Courir 5km'), findsOneWidget);
      expect(find.text('Méditer 10 min'), findsOneWidget);
    });

    testWidgets('basculer sur l\'onglet Terminées montre l\'état vide',
        (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Terminées'));
      await tester.pump();

      expect(find.text('Aucune quête terminée'), findsOneWidget);
    });

    testWidgets('ouvrir la recherche remplace le titre par un TextField',
        (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('fermer la recherche restaure le titre', (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('Quêtes'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('la barre de filtres est visible sur l\'onglet À faire',
        (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      // _FilterBar contient les chips Unique/Quotidien/Hebdo/Mensuel
      expect(find.text('Quotidien'), findsOneWidget);
    });

    testWidgets('la barre de filtres n\'est pas visible sur l\'onglet Terminées',
        (tester) async {
      await tester.pumpWidget(_buildQuestsList());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Terminées'));
      await tester.pump();

      expect(find.text('Quotidien'), findsNothing);
    });

    testWidgets('userId null → affiche l\'état vide sans erreur', (tester) async {
      await tester.pumpWidget(_buildQuestsList(
        authVm: _makeAuthVm(userId: null),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Aucune quête en cours'), findsOneWidget);
    });
  });
}
