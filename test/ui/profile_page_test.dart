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
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';
import 'package:sameva/presentation/view_models/equipment_view_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';
import 'package:sameva/ui/pages/profile/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBox extends Mock implements Box<dynamic> {}
class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockQuestRepository extends Mock implements QuestRepository {}
class _MockUser extends Mock implements User {}

Box<dynamic> _boiteVide() {
  final box = _MockBox();
  when(() => box.get(any())).thenReturn(null);
  when(() => box.get(any(), defaultValue: any(named: 'defaultValue')))
      .thenAnswer((i) => i.namedArguments[#defaultValue]);
  when(() => box.put(any(), any())).thenAnswer((_) async {});
  return box;
}

Widget _app({required bool invite}) {
  final user = _MockUser();
  when(() => user.id).thenReturn('u1');
  when(() => user.email).thenReturn(invite ? null : 'heros@sameva.app');
  when(() => user.isAnonymous).thenReturn(invite);
  final authRepo = _MockAuthRepository();
  when(() => authRepo.currentUser).thenReturn(user);
  when(() => authRepo.authStateChanges).thenAnswer((_) => const Stream<AuthState>.empty());

  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats(level: 3, experience: 120, gold: 250, streak: 8));
  when(() => playerRepo.fetchServerState()).thenAnswer((_) async => throw Exception('hors-ligne'));
  when(() => playerRepo.saveLocalStats(any())).thenAnswer((_) async {});

  final questRepo = _MockQuestRepository();
  when(() => questRepo.loadQuests(any())).thenAnswer((_) async => <Quest>[]);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: AuthViewModel(authRepo)),
      Provider<PlayerRepository>.value(value: playerRepo),
      ChangeNotifierProvider<QuestViewModel>.value(value: QuestViewModel(questRepo)),
      ChangeNotifierProvider<PlayerViewModel>.value(value: PlayerViewModel(playerRepo)),
      ChangeNotifierProvider<InventoryViewModel>.value(value: InventoryViewModel(_boiteVide())),
      ChangeNotifierProvider<EquipmentViewModel>.value(value: EquipmentViewModel(_boiteVide())),
      ChangeNotifierProvider<CatViewModel>.value(value: CatViewModel(_boiteVide())),
      ChangeNotifierProvider<AiValidationCreditsService>.value(value: AiValidationCreditsService(_boiteVide())),
    ],
    child: const MaterialApp(home: ProfilePage()),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    final dir = await Directory.systemTemp.createTemp('hive_profile_page_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  Future<void> afficher(WidgetTester tester, {required bool invite}) async {
    await tester.binding.setSurfaceSize(const Size(412, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(invite: invite));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('profil pixel : tête, soldes, sections et actions', (tester) async {
    await afficher(tester, invite: false);

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('heros@sameva.app'), findsOneWidget);
    expect(find.text('Niv. 3'), findsOneWidget);
    expect(find.text('8 j'), findsOneWidget);
    expect(find.bySemanticsLabel('Expérience 120 sur 450'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
    expect(find.text('PV'), findsOneWidget);
    for (final titre in ['Équipement', 'Inventaire', 'Statistiques', 'Succès', 'XP sur 14 jours']) {
      expect(find.text(titre), findsOneWidget, reason: titre);
    }
    expect(find.text('Mode invité'), findsNothing);
    expect(find.byKey(const Key('cta_premium_profil')), findsOneWidget);
    expect(find.bySemanticsLabel('Se déconnecter'), findsOneWidget);
    expect(find.byKey(const Key('btn_delete_account')), findsOneWidget);

    // La déconnexion demande confirmation dans un dialogue pixel.
    await tester.tap(find.bySemanticsLabel('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Veux-tu vraiment te déconnecter ?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Veux-tu vraiment te déconnecter ?'), findsNothing);
  });

  testWidgets('profil invité : bandeau de sauvegarde', (tester) async {
    await afficher(tester, invite: true);
    expect(find.text('Mode invité'), findsOneWidget);
    expect(find.byKey(const Key('btn_sauvegarder_progression')), findsOneWidget);
  });
}
