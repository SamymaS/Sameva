import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';
import 'package:sameva/presentation/view_models/equipment_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';
import 'package:sameva/ui/pages/home/sanctuary_page.dart';
import 'package:sameva/ui/widgets/common/quest_detail_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockQuestRepository extends Mock implements QuestRepository {}
class _MockBox extends Mock implements Box<dynamic> {}
class _MockUser extends Mock implements User {}

/// Crée une quête quotidienne (visible sur l'Accueil dans todayQuests).
Quest _makeDailyQuest({String title = 'Courir 30 minutes'}) => Quest(
      id: 'q-sanctuary-test',
      userId: 'u1',
      title: title,
      estimatedDurationMinutes: 30,
      frequency: QuestFrequency.daily,
      difficulty: 2,
      category: 'Sport',
      rarity: QuestRarity.rare,
      status: QuestStatus.active,
      validationType: ValidationType.manual,
    );

Widget _buildSanctuaryWithQuest(Quest quest) {
  final authRepo = _MockAuthRepository();
  final mockUser = _MockUser();
  when(() => mockUser.id).thenReturn('u1');
  when(() => mockUser.email).thenReturn('hero@sameva.app');
  when(() => authRepo.currentUser).thenReturn(mockUser);
  when(() => authRepo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  final authVm = AuthViewModel(authRepo);

  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats(streak: 3));
  when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => playerRepo.syncToSupabase(any(), any())).thenAnswer((_) async {});
  final playerVm = PlayerViewModel(playerRepo);

  final questRepo = _MockQuestRepository();
  when(() => questRepo.loadQuests(any())).thenAnswer((_) async => [quest]);
  when(() => questRepo.updateQuest(any())).thenAnswer((_) async => quest);
  final questVm = QuestViewModel(questRepo);

  final eqBox = _MockBox();
  when(() => eqBox.get(any())).thenReturn(null);
  when(() => eqBox.put(any(), any())).thenAnswer((_) async {});
  final eqVm = EquipmentViewModel(eqBox);

  final catBox = _MockBox();
  when(() => catBox.get(any())).thenReturn(null);
  when(() => catBox.put(any(), any())).thenAnswer((_) async {});
  final catVm = CatViewModel(catBox);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ChangeNotifierProvider<PlayerViewModel>.value(value: playerVm),
      ChangeNotifierProvider<QuestViewModel>.value(value: questVm),
      ChangeNotifierProvider<EquipmentViewModel>.value(value: eqVm),
      ChangeNotifierProvider<CatViewModel>.value(value: catVm),
    ],
    child: const MaterialApp(home: SanctuaryPage()),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
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
        await Directory.systemTemp.createTemp('hive_sanctuary_quest_tap_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
    await Hive.openBox('quests');
  });

  group('SanctuaryPage — cartes de quêtes cliquables', () {
    testWidgets(
        'tapper une quête du jour affiche le QuestDetailSheet avec l\'objet Quest complet',
        (tester) async {
      final quest = _makeDailyQuest(title: 'Courir 30 minutes');
      await tester.pumpWidget(_buildSanctuaryWithQuest(quest));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // La tuile de quête doit être visible
      expect(find.text('Courir 30 minutes'), findsOneWidget);

      // Tap sur la tuile
      await tester.tap(find.text('Courir 30 minutes'));
      await tester.pumpAndSettle();

      // Le QuestDetailSheet doit être affiché — il contient le titre de la quête
      // (au moins une occurrence dans le sheet)
      expect(find.text('Courir 30 minutes'), findsWidgets);

      // Le sheet lui-même est instancié
      expect(find.byType(QuestDetailSheet), findsOneWidget);
    });

    testWidgets(
        'le QuestDetailSheet reçoit l\'objet Quest complet (titre correct)',
        (tester) async {
      final quest = _makeDailyQuest(title: 'Méditer 10 minutes');
      await tester.pumpWidget(_buildSanctuaryWithQuest(quest));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Méditer 10 minutes'));
      await tester.pumpAndSettle();

      // Le sheet affiche le titre exact de la quête transmise
      expect(find.text('Méditer 10 minutes'), findsWidgets);
      // Vérification supplémentaire : la catégorie est bien affichée
      expect(find.text('Sport'), findsWidgets);
    });
  });
}
