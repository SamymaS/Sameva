/// Tests widget de DeleteAccountConfirmDialog — comportement UI RGPD.
///
/// Ce que prouvent ces tests :
/// 1. Bouton de suppression inactif tant que la case n'est pas cochée.
/// 2. Sur succès : dialog fermé + QuestViewModel vidé via le stream onSignedOut
///    (plus d'appel explicite clearCache() dans le dialog — prouve l'abonnement).
/// 3. Sur échec partiel : PAS de fermeture, message d'erreur affiché,
///    bouton réactivé pour permettre une nouvelle tentative.
/// 4. Bouton non re-cliquable pendant l'appel réseau (un seul invoke même
///    sur double-tap).
///
/// Pattern de test : on rend directement DeleteAccountConfirmDialog (widget
/// public) plutôt que de traverser ProfilePage entière. Les dépendances sont
/// injectées via MultiProvider avec des mocks mocktail.
///
/// Piège FakeAsync+Hive : aucun box.put/delete dans ces tests car
/// AuthViewModel.deleteAccount() est entièrement mocké → pas de vraie I/O Hive.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/player_stats_model.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/player_repository.dart';
import 'package:sameva/data/repositories/quest_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/profile_view_model.dart';
import 'package:sameva/presentation/view_models/quest_view_model.dart';
import 'package:sameva/ui/pages/profile/delete_account_confirm_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class _MockAuthViewModel extends Mock implements AuthViewModel {}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockQuestRepository extends Mock implements QuestRepository {}

class _MockUser extends Mock implements User {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Construit le widget de test : dialog encapsulé dans un MaterialApp
/// minimal avec les providers nécessaires.
///
/// [questVm] est partagé entre le Provider et le ProfileViewModel pour que
/// [DeleteAccountConfirmDialog._onConfirmDelete] lise le même objet via
/// context.read<QuestViewModel>().
Widget _buildTest({
  required _MockAuthViewModel authVm,
  required QuestViewModel questVm,
  required ProfileViewModel profileVm,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ChangeNotifierProvider<QuestViewModel>.value(value: questVm),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showDialog<void>(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => MultiProvider(
                providers: [
                  // Le dialog a son propre context (nouveau scope Navigator),
                  // on réinjecte QuestViewModel pour context.read<QuestViewModel>().
                  ChangeNotifierProvider<QuestViewModel>.value(value: questVm),
                ],
                child: DeleteAccountConfirmDialog(vm: profileVm),
              ),
            ),
            child: const Text('Ouvrir dialog'),
          ),
        ),
      ),
    ),
  );
}

/// Ouvre le dialog de confirmation via le bouton de test.
Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Ouvrir dialog'));
  await tester.pumpAndSettle();
}

/// Coche la case de confirmation.
Future<void> _checkConfirmBox(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('chk_confirm_delete')));
  await tester.pump();
}

/// Crée un jeu de VMs avec un mock AuthViewModel configurable.
({
  _MockAuthViewModel authVm,
  QuestViewModel questVm,
  ProfileViewModel profileVm,
}) _makeVms() {
  final authVm = _MockAuthViewModel();
  final mockUser = _MockUser();
  when(() => mockUser.id).thenReturn('uid-test');
  when(() => mockUser.email).thenReturn('hero@sameva.app');
  when(() => authVm.user).thenReturn(mockUser);
  when(() => authVm.userId).thenReturn('uid-test');
  when(() => authVm.isAuthenticated).thenReturn(true);
  when(() => authVm.isLoading).thenReturn(false);
  when(() => authVm.errorMessage).thenReturn(null);
  when(() => authVm.onSignedOut)
      .thenAnswer((_) => const Stream<void>.empty());
  when(() => authVm.onSignedIn)
      .thenAnswer((_) => const Stream<void>.empty());

  final questRepo = _MockQuestRepository();
  when(() => questRepo.loadQuests(any())).thenAnswer((_) async => []);
  final questVm = QuestViewModel(questRepo);

  final playerRepo = _MockPlayerRepository();
  when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
  when(() => playerRepo.fetchRemoteStats(any())).thenAnswer((_) async => null);

  final profileVm = ProfileViewModel(authVm, playerRepo, questVm);

  return (authVm: authVm, questVm: questVm, profileVm: profileVm);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PlayerStats());
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Test 1 : confirmation requise avant tout appel réseau
  // ────────────────────────────────────────────────────────────────────────────
  group('DeleteAccountConfirmDialog — confirmation requise', () {
    testWidgets(
        'bouton désactivé si la case n\'est pas cochée',
        (tester) async {
      final vms = _makeVms();
      await tester.pumpWidget(_buildTest(
        authVm: vms.authVm,
        questVm: vms.questVm,
        profileVm: vms.profileVm,
      ));
      await _openDialog(tester);

      // Le bouton de suppression doit être désactivé (onPressed == null)
      final btn = tester.widget<FilledButton>(
        find.byKey(const Key('btn_confirm_delete')),
      );
      expect(btn.onPressed, isNull,
          reason:
              'Le bouton doit être désactivé tant que la case n\'est pas cochée');

      // Tenter de taper le bouton désactivé n'appelle rien
      await tester.tap(
        find.byKey(const Key('btn_confirm_delete')),
        warnIfMissed: false,
      );
      await tester.pump();

      // Aucun appel réseau ne doit avoir eu lieu
      verifyNever(() => vms.authVm.deleteAccount());

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'bouton activé après avoir coché la case',
        (tester) async {
      final vms = _makeVms();
      await tester.pumpWidget(_buildTest(
        authVm: vms.authVm,
        questVm: vms.questVm,
        profileVm: vms.profileVm,
      ));
      await _openDialog(tester);

      // Avant : bouton désactivé
      var btn = tester.widget<FilledButton>(
        find.byKey(const Key('btn_confirm_delete')),
      );
      expect(btn.onPressed, isNull);

      // Coche la case
      await _checkConfirmBox(tester);

      // Après : bouton activé
      btn = tester.widget<FilledButton>(
        find.byKey(const Key('btn_confirm_delete')),
      );
      expect(btn.onPressed, isNotNull,
          reason: 'Le bouton doit être actif après avoir coché la case');

      await tester.pumpWidget(const SizedBox());
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Test 2 : succès complet
  // ────────────────────────────────────────────────────────────────────────────
  group('DeleteAccountConfirmDialog — succès', () {
    testWidgets(
        'ferme le dialog et vide le cache quêtes via onSignedOut sur succès',
        (tester) async {
      // ── Stream onSignedOut contrôlé par le test ──────────────────────────
      // Simule ce que produirait deleteAccount → signOut → _signedOutController.add(null).
      // sync: true : delivery synchrone → clearCache() s'exécute pendant le stub,
      // garantissant que le cache est vide quand _onConfirmDelete continue.
      final signedOutCtrl = StreamController<void>.broadcast(sync: true);

      // ── VMs construits à la main pour contrôler les quêtes pré-chargées ──
      final authVm = _MockAuthViewModel();
      final mockUser = _MockUser();
      when(() => mockUser.id).thenReturn('uid-test');
      when(() => mockUser.email).thenReturn('hero@sameva.app');
      when(() => authVm.user).thenReturn(mockUser);
      when(() => authVm.userId).thenReturn('uid-test');
      when(() => authVm.isAuthenticated).thenReturn(true);
      when(() => authVm.isLoading).thenReturn(false);
      when(() => authVm.errorMessage).thenReturn(null);
      when(() => authVm.onSignedOut)
          .thenAnswer((_) => signedOutCtrl.stream);
      when(() => authVm.onSignedIn)
          .thenAnswer((_) => const Stream<void>.empty());
      // Le stub émet sur le stream (simule le onSignedOut que signOut() déclencherait).
      // Prouve que c'est l'ABONNEMENT (pas un clearCache() explicite dans le dialog)
      // qui vide le cache des quêtes.
      when(() => authVm.deleteAccount()).thenAnswer((_) async {
        signedOutCtrl.add(null);
      });

      // QuestViewModel abonné au stream — reçoit onSignedOut → clearCache().
      final questRepo = _MockQuestRepository();
      final fakeQuest = Quest(
        id: 'q-rgpd-clear-1',
        userId: 'uid-test',
        title: 'Quête de test RGPD',
        estimatedDurationMinutes: 30,
        frequency: QuestFrequency.oneOff,
        difficulty: 1,
        category: 'sante',
        rarity: QuestRarity.common,
        status: QuestStatus.active,
        createdAt: DateTime(2026, 1, 1),
        // deadline non fourni → null → NotificationService non déclenché
      );
      when(() => questRepo.loadQuests('uid-test'))
          .thenAnswer((_) async => [fakeQuest]);
      // QuestViewModel connecté au stream — c'est ce câblage qui garantit
      // le nettoyage sans appel explicite depuis le dialog.
      final questVm = QuestViewModel(questRepo, onSignedOut: signedOutCtrl.stream);

      // Charger les quêtes : QuestViewModel n'écrit pas Hive, pas besoin de
      // runAsync. Le mock repo résout immédiatement le Future.
      await questVm.loadQuests('uid-test');

      // Précondition : le cache doit être non vide avant suppression.
      // Sans cette assertion, le test passerait trivialement même si
      // clearCache() n'était jamais appelé.
      expect(questVm.quests, isNotEmpty,
          reason:
              'Précondition : le cache quêtes doit contenir des entrées avant suppression');

      final playerRepo = _MockPlayerRepository();
      when(() => playerRepo.loadLocalStats()).thenReturn(PlayerStats());
      when(() => playerRepo.fetchRemoteStats(any()))
          .thenAnswer((_) async => null);
      final profileVm = ProfileViewModel(authVm, playerRepo, questVm);

      await tester.pumpWidget(_buildTest(
        authVm: authVm,
        questVm: questVm,
        profileVm: profileVm,
      ));
      await _openDialog(tester);

      // Le dialog est visible
      expect(find.byType(AlertDialog), findsOneWidget);

      // Coche la case puis confirme
      await _checkConfirmBox(tester);
      await tester.tap(find.byKey(const Key('btn_confirm_delete')));
      await tester.pump(); // frame 1 : _isLoading = true + lancement de l'appel
      await tester.pump(); // frame 2 : mock deleteAccount + signedOutCtrl.add(null) + clearCache() + Navigator.pop()
      // Animation de fermeture du dialog (fade-out ~300 ms)
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Le dialog doit être fermé
      expect(find.byType(AlertDialog), findsNothing,
          reason: 'Le dialog doit se fermer après un succès');

      // deleteAccount a été appelé exactement une fois
      verify(() => authVm.deleteAccount()).called(1);

      // ── Assertion principale : le stream onSignedOut a vidé la liste ──────
      // Ce test ÉCHOUE si QuestViewModel n'est pas abonné à onSignedOut.
      // Il ne dépend plus d'un clearCache() explicite dans le dialog.
      expect(questVm.quests, isEmpty,
          reason:
              'L\'abonnement onSignedOut doit avoir vidé le cache des quêtes '
              'sans appel explicite dans le dialog (rustine supprimée en P1)');

      await tester.pumpWidget(const SizedBox());
      await signedOutCtrl.close();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Test 3 : échec partiel
  // ────────────────────────────────────────────────────────────────────────────
  group('DeleteAccountConfirmDialog — échec partiel', () {
    testWidgets(
        'affiche le message d\'erreur sans fermer le dialog',
        (tester) async {
      final vms = _makeVms();

      // Mock deleteAccount pour échouer
      when(() => vms.authVm.deleteAccount())
          .thenThrow(Exception('Étape 2 (suppression compte auth) échouée'));

      await tester.pumpWidget(_buildTest(
        authVm: vms.authVm,
        questVm: vms.questVm,
        profileVm: vms.profileVm,
      ));
      await _openDialog(tester);

      await _checkConfirmBox(tester);
      await tester.tap(find.byKey(const Key('btn_confirm_delete')));
      await tester.pump();
      await tester.pump();

      // Le dialog RESTE ouvert
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'Le dialog doit rester ouvert sur un échec');

      // Le message d'erreur doit être visible
      expect(
        find.textContaining('Étape 2 (suppression compte auth) échouée'),
        findsOneWidget,
        reason: 'Le message d\'erreur doit être affiché',
      );

      // Le bouton doit être réactivé (l'utilisateur peut réessayer)
      final btn = tester.widget<FilledButton>(
        find.byKey(const Key('btn_confirm_delete')),
      );
      expect(btn.onPressed, isNotNull,
          reason: 'Le bouton doit être réactivé après un échec pour permettre une nouvelle tentative');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'ne déconnecte pas l\'utilisateur sur un échec',
        (tester) async {
      final vms = _makeVms();

      when(() => vms.authVm.deleteAccount())
          .thenThrow(Exception('Erreur réseau'));

      await tester.pumpWidget(_buildTest(
        authVm: vms.authVm,
        questVm: vms.questVm,
        profileVm: vms.profileVm,
      ));
      await _openDialog(tester);
      await _checkConfirmBox(tester);
      await tester.tap(find.byKey(const Key('btn_confirm_delete')));
      await tester.pump();
      await tester.pump();

      // signOut ne doit PAS avoir été appelé
      verifyNever(() => vms.authVm.signOut());

      await tester.pumpWidget(const SizedBox());
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Test 4 : double-tap bloqué pendant l'appel
  // ────────────────────────────────────────────────────────────────────────────
  group('DeleteAccountConfirmDialog — double-tap bloqué', () {
    testWidgets(
        'un seul appel même sur double-tap rapide',
        (tester) async {
      final vms = _makeVms();

      // Completer non résolu → simule un appel réseau en cours
      final completer = Completer<void>();
      when(() => vms.authVm.deleteAccount())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildTest(
        authVm: vms.authVm,
        questVm: vms.questVm,
        profileVm: vms.profileVm,
      ));
      await _openDialog(tester);
      await _checkConfirmBox(tester);

      // Premier tap — déclenche l'appel, passe _isLoading = true
      await tester.tap(find.byKey(const Key('btn_confirm_delete')));
      await tester.pump(); // traite le setState(_isLoading = true)

      // Le bouton doit maintenant être désactivé
      final btn = tester.widget<FilledButton>(
        find.byKey(const Key('btn_confirm_delete')),
      );
      expect(btn.onPressed, isNull,
          reason:
              'Le bouton doit être désactivé pendant l\'appel réseau');

      // Second tap sur le bouton désactivé → aucun effet
      await tester.tap(
        find.byKey(const Key('btn_confirm_delete')),
        warnIfMissed: false,
      );
      await tester.pump();

      // deleteAccount doit avoir été appelé UNE SEULE FOIS
      verify(() => vms.authVm.deleteAccount()).called(1);

      // Résoudre le completer pour nettoyer
      completer.complete();
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
    });
  });
}
