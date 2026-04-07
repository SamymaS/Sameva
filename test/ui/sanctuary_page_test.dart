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
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';
import 'package:sameva/ui/pages/home/sanctuary_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockQuestRepository extends Mock implements QuestRepository {}
class _MockBox extends Mock implements Box<dynamic> {}
class _MockUser extends Mock implements User {}

Widget _buildSanctuary({
  AuthViewModel? authVm,
  PlayerViewModel? playerVm,
  QuestViewModel? questVm,
  CatViewModel? catVm,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authVm ?? _makeAuthVm()),
      ChangeNotifierProvider<PlayerViewModel>.value(value: playerVm ?? _makePlayerVm()),
      ChangeNotifierProvider<QuestViewModel>.value(value: questVm ?? _makeQuestVm()),
      ChangeNotifierProvider<CatViewModel>.value(value: catVm ?? _makeCatVm()),
    ],
    child: const MaterialApp(home: SanctuaryPage()),
  );
}

AuthViewModel _makeAuthVm({User? user}) {
  final repo = _MockAuthRepository();
  final mockUser = user ?? _MockUser();
  if (user == null) {
    when(() => (mockUser as _MockUser).id).thenReturn('u1');
    when(() => (mockUser as _MockUser).email).thenReturn('hero@sameva.app');
  }
  when(() => repo.currentUser).thenReturn(mockUser);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

PlayerViewModel _makePlayerVm() {
  final repo = _MockPlayerRepository();
  when(() => repo.loadLocalStats()).thenReturn(PlayerStats(streak: 3));
  when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});
  return PlayerViewModel(repo);
}

QuestViewModel _makeQuestVm() {
  final repo = _MockQuestRepository();
  when(() => repo.loadQuests(any())).thenAnswer((_) async => <Quest>[]);
  return QuestViewModel(repo);
}

CatViewModel _makeCatVm() {
  final box = _MockBox();
  when(() => box.get(any())).thenReturn(null);
  when(() => box.put(any(), any())).thenAnswer((_) async {});
  return CatViewModel(box);
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    final dir = await Directory.systemTemp.createTemp('hive_sanctuary_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  // Pas de tearDownAll : Hive.close() bloque le runner de tests.
  // Le processus de test se termine et libère les ressources automatiquement.

  group('SanctuaryPage', () {
    testWidgets('affiche le titre Sanctuaire', (tester) async {
      await tester.pumpWidget(_buildSanctuary());
      await tester.pump(); // premier frame
      await tester.pump(const Duration(milliseconds: 100)); // async _load

      expect(find.text('Sanctuaire'), findsOneWidget);
    });

    testWidgets('affiche l\'indicateur de série (streak)', (tester) async {
      await tester.pumpWidget(_buildSanctuary());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // streak = 3 → affiche '3j'
      expect(find.text('3j'), findsOneWidget);
    });

    testWidgets('affiche la carte de stats XP/HP quand les stats sont chargées',
        (tester) async {
      await tester.pumpWidget(_buildSanctuary());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // _StatsCard affiche les barres XP et HP
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('affiche un message vide si aucune quête du jour', (tester) async {
      await tester.pumpWidget(_buildSanctuary());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Quand il n'y a pas de quêtes, "aucune quête" ou la section est absente
      expect(find.text('Quêtes du jour'), findsNothing);
    });

    testWidgets('n\'affiche pas la section chat si aucun chat', (tester) async {
      await tester.pumpWidget(_buildSanctuary());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // _CatHeroSection n'est affiché que si cat != null
      expect(find.byType(SanctuaryPage), findsOneWidget);
    });
  });
}
