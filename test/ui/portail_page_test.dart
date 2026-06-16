import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/cat_view_model.dart';
import 'package:sameva/presentation/view_models/inventory_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/ui/pages/market/market_page.dart';
import 'package:sameva/ui/widgets/common/dock_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockUser extends Mock implements User {}

AuthViewModel _makeAuthVm() {
  final repo = _MockAuthRepository();
  final user = _MockUser();
  when(() => user.id).thenReturn('u1');
  when(() => user.email).thenReturn('hero@sameva.app');
  when(() => repo.currentUser).thenReturn(user);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

PlayerViewModel _makePlayerVm() {
  final repo = _MockPlayerRepository();
  when(() => repo.loadLocalStats())
      .thenReturn(PlayerStats(gold: 120, crystals: 50));
  when(() => repo.fetchRemoteStats(any())).thenAnswer((_) async => null);
  when(() => repo.saveLocalStats(any())).thenAnswer((_) async {});
  when(() => repo.syncToSupabase(any(), any())).thenAnswer((_) async {});
  return PlayerViewModel(repo);
}

Widget _buildPortail() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: _makeAuthVm()),
      ChangeNotifierProvider<PlayerViewModel>.value(value: _makePlayerVm()),
      ChangeNotifierProvider<InventoryViewModel>.value(
          value: InventoryViewModel(Hive.box('inventory'))..loadInventory()),
      ChangeNotifierProvider<CatViewModel>.value(
          value: CatViewModel(Hive.box('cats'))),
      // Requis par le compteur AiCreditCounter affiché dans l'AppBar du Portail.
      ChangeNotifierProvider<AiValidationCreditsService>.value(
        value: AiValidationCreditsService(
          Hive.box('aiValidation'),
          testUserId: 'test-portail',
        ),
      ),
    ],
    child: const MaterialApp(home: PortailPage()),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
    final dir = await Directory.systemTemp.createTemp('hive_portail_test');
    Hive.init(dir.path);
    await Hive.openBox('settings');
    await Hive.openBox('inventory');
    await Hive.openBox('cats');
    await Hive.openBox('aiValidation');
  });

  // Pas de tearDownAll : Hive.close() bloque le runner (cf. sanctuary_page_test).

  group('PortailPage (fusion Invocation + Marché)', () {
    testWidgets('construit les 3 onglets MVP sans exception', (tester) async {
      await tester.pumpWidget(_buildPortail());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Portail'), findsOneWidget);
      // Onglets de la TabBar du Portail
      expect(find.text('Invocation'), findsWidgets);
      expect(find.text('Boutique'), findsOneWidget);
      expect(find.text('Vendre'), findsOneWidget);
      // Premium masqué par feature flag
      expect(find.text('Premium'), findsNothing);
      // L'onglet Invocation (InvocationTab embarqué) expose son sous-TabBar
      // Objets/Chats : preuve que le DefaultTabController imbriqué tient.
      expect(find.textContaining('Objets'), findsOneWidget);
      expect(find.textContaining('Chats'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('DockBar', () {
    testWidgets('affiche exactement les 5 onglets MVP', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DockBar(currentIndex: 0, onTap: (_) {}),
        ),
      ));
      await tester.pump();

      for (final label in const [
        'Accueil',
        'Quêtes',
        'Portail',
        'Chat',
        'Profil'
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      // Onglets retirés du périmètre MVP
      expect(find.text('Stock'), findsNothing);
      expect(find.text('Marché'), findsNothing);
      expect(find.text('Jeux'), findsNothing);
    });
  });
}
