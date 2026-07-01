/// Tests unitaires de AuthViewModel.deleteAccount() — logique RGPD.
///
/// Utilise testWidgets + tester.runAsync() pour isoler les écritures Hive
/// de la zone FakeAsync (cf. piège documenté dans sameva-hive SKILL).
///
/// Ce que prouvent ces tests :
/// 1. Succès complet → clés Hive per-user purgées + signOut() appelé.
/// 2. Échec partiel (auth_user_deleted == false) → PAS de purge, PAS de signOut.
/// 3. Réponse réseau indisponible → Exception propagée sans déconnexion.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/domain/services/activity_log_service.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUser extends Mock implements User {}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _userId = 'test-user-rgpd-42';

/// Crée un AuthViewModel avec un utilisateur authentifié (userId = _userId).
AuthViewModel _makeVm(_MockAuthRepository repo) {
  final user = _MockUser();
  when(() => user.id).thenReturn(_userId);
  when(() => user.email).thenReturn('test@sameva.app');
  when(() => repo.currentUser).thenReturn(user);
  when(() => repo.authStateChanges)
      .thenAnswer((_) => const Stream<AuthState>.empty());
  return AuthViewModel(repo);
}

/// Réponse de succès complet (les deux étapes OK).
Map<String, dynamic> _successResponse() => {
      'success': true,
      'steps': {'audit_deleted': true, 'auth_user_deleted': true},
    };

/// Réponse d'échec partiel (audit OK, auth KO).
Map<String, dynamic> _partialFailResponse() => {
      'success': false,
      'steps': {'audit_deleted': true, 'auth_user_deleted': false},
      'error': 'Étape 2 (suppression compte auth) échouée',
    };

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    // Hive réel dans un répertoire temporaire — pas de TypeAdapter, pas de close().
    tmpDir = await Directory.systemTemp
        .createTemp('hive_auth_delete_account_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox('cats');
    await Hive.openBox('aiValidation');
    await Hive.openBox('settings');
    await Hive.openBox('playerStats');
    await Hive.openBox('inventory');
    await Hive.openBox('equipment');
  });

  // Pas de tearDownAll avec Hive.close() : bloque le runner (cf. sameva-hive).

  // _cache est STATIQUE dans ActivityLogService → il fuit entre les tests si on
  // ne le réinitialise pas. setUp() s'exécute avant chaque testWidgets, hors de
  // la zone FakeAsync (qui n'est créée qu'à l'intérieur du callback testWidgets),
  // donc l'await Hive est sûr ici sans tester.runAsync().
  setUp(() async {
    await ActivityLogService.clearLog();
  });

  group('AuthViewModel.deleteAccount — succès complet', () {
    testWidgets(
        'purge les 4 clés Hive per-user et appelle signOut()',
        (tester) async {
      final repo = _MockAuthRepository();
      when(() => repo.signOut()).thenAnswer((_) async {});
      final vm = _makeVm(repo);

      // ── Écriture Hive en zone réelle (piège FakeAsync) ─────────────────
      await tester.runAsync(() async {
        await Hive.box('cats').put('cats_list_$_userId', <dynamic>[]);
        await Hive.box('aiValidation').put('ai_validation_$_userId', <String, dynamic>{});
        await Hive.box('settings').put('has_onboarded_$_userId', true);
        await Hive.box('settings').put('lastFreePullAt', '2026-01-01T00:00:00.000Z');
      });

      // Précondition : les 4 clés existent.
      expect(Hive.box('cats').containsKey('cats_list_$_userId'), isTrue);
      expect(Hive.box('aiValidation').containsKey('ai_validation_$_userId'), isTrue);
      expect(Hive.box('settings').containsKey('has_onboarded_$_userId'), isTrue);
      expect(Hive.box('settings').containsKey('lastFreePullAt'), isTrue);

      // ── Appel deleteAccount avec override de succès ─────────────────────
      await tester.runAsync(() => vm.deleteAccount(
            invokeOverride: () async => _successResponse(),
          ));

      // ── Vérification purge Hive ─────────────────────────────────────────
      expect(Hive.box('cats').containsKey('cats_list_$_userId'), isFalse,
          reason: 'cats_list_\$userId doit être supprimée');
      expect(Hive.box('aiValidation').containsKey('ai_validation_$_userId'), isFalse,
          reason: 'ai_validation_\$userId doit être supprimée');
      expect(Hive.box('settings').containsKey('has_onboarded_$_userId'), isFalse,
          reason: 'has_onboarded_\$userId doit être supprimée');
      expect(Hive.box('settings').containsKey('lastFreePullAt'), isFalse,
          reason: 'lastFreePullAt doit être supprimée');

      // ── Vérification signOut ────────────────────────────────────────────
      verify(() => repo.signOut()).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Réponse non-bool — fail-closed (RGPD)
  // ──────────────────────────────────────────────────────────────────────────
  group('AuthViewModel.deleteAccount — réponse non-bool (fail-closed)', () {
    testWidgets(
        'champ success=1 (int) → Exception propre, aucune purge Hive, aucun signOut',
        (tester) async {
      final repo = _MockAuthRepository();
      when(() => repo.signOut()).thenAnswer((_) async {});
      final vm = _makeVm(repo);

      // Placer une clé Hive per-user pour vérifier qu'elle n'est pas purgée.
      await tester.runAsync(() async {
        await Hive.box('settings')
            .put('has_onboarded_${_userId}_nonbool', true);
      });

      Object? thrown;
      await tester.runAsync(() async {
        try {
          await vm.deleteAccount(
            // Simule un serveur renvoyant des entiers au lieu de booléens.
            // Avant le fix, `as bool?` levait un TypeError (Error, pas Exception)
            // qui échappait au gestionnaire UI → _isLoading bloqué.
            // Après le fix (== true), 1 == true vaut false en Dart → fail-closed.
            invokeOverride: () async => {
              'success': 1,
              'steps': {
                'audit_deleted': 1,
                'auth_user_deleted': 1,
              },
            },
          );
        } catch (e) {
          thrown = e;
        }
      });

      // Doit lever une Exception (pas un TypeError / Error)
      expect(thrown, isA<Exception>(),
          reason:
              'Un champ non-bool (ex. int 1) doit lever une Exception propre, '
              'pas un Error qui échappe au gestionnaire UI');

      // La clé Hive per-user ne doit PAS avoir été supprimée
      expect(
        Hive.box('settings').containsKey('has_onboarded_${_userId}_nonbool'),
        isTrue,
        reason: 'Aucune purge Hive sur réponse malformée',
      );

      // signOut ne doit PAS avoir été appelé
      verifyNever(() => repo.signOut());
    });
  });

  group('AuthViewModel.deleteAccount — échec partiel', () {
    testWidgets(
        'ne purge PAS Hive et ne déconnecte PAS sur auth_user_deleted == false',
        (tester) async {
      final repo = _MockAuthRepository();
      // signOut ne doit PAS être appelé
      when(() => repo.signOut()).thenAnswer((_) async {});
      final vm = _makeVm(repo);

      // Écriture Hive des clés per-user
      await tester.runAsync(() async {
        await Hive.box('cats').put('cats_list_${_userId}_fail', <dynamic>[]);
        await Hive.box('settings').put('has_onboarded_${_userId}_fail', true);
      });

      // Appel deleteAccount avec réponse d'échec partiel
      Object? thrownError;
      await tester.runAsync(() async {
        try {
          await vm.deleteAccount(
            invokeOverride: () async => _partialFailResponse(),
          );
        } on Exception catch (e) {
          thrownError = e;
        }
      });

      // Une exception doit avoir été lancée
      expect(thrownError, isA<Exception>(),
          reason: 'deleteAccount doit lever une Exception sur échec partiel');

      // Les clés Hive NE doivent PAS avoir été supprimées
      expect(Hive.box('cats').containsKey('cats_list_${_userId}_fail'), isTrue,
          reason: 'cats_list ne doit pas être purgée sur échec');
      expect(Hive.box('settings').containsKey('has_onboarded_${_userId}_fail'), isTrue,
          reason: 'has_onboarded ne doit pas être purgée sur échec');

      // signOut ne doit PAS avoir été appelé
      verifyNever(() => repo.signOut());
    });

    testWidgets(
        'ne purge PAS Hive et ne déconnecte PAS sur erreur réseau',
        (tester) async {
      final repo = _MockAuthRepository();
      when(() => repo.signOut()).thenAnswer((_) async {});
      final vm = _makeVm(repo);

      await tester.runAsync(() async {
        await Hive.box('settings').put('has_onboarded_${_userId}_net', true);
      });

      Object? thrownError;
      await tester.runAsync(() async {
        try {
          await vm.deleteAccount(
            // invokeOverride lance une exception → simule une erreur réseau
            invokeOverride: () async =>
                throw Exception('Connexion refusée'),
          );
        } on Exception catch (e) {
          thrownError = e;
        }
      });

      expect(thrownError, isA<Exception>());
      // La clé Hive ne doit pas avoir été supprimée
      expect(Hive.box('settings').containsKey('has_onboarded_${_userId}_net'), isTrue);
      verifyNever(() => repo.signOut());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Historique d'activité — purge RGPD (fuite _cache statique + clé Hive)
  // ──────────────────────────────────────────────────────────────────────────
  group('ActivityLogService — purge RGPD sur deleteAccount', () {
    testWidgets(
        'succès complet → getLog() est vide après suppression',
        (tester) async {
      final repo = _MockAuthRepository();
      when(() => repo.signOut()).thenAnswer((_) async {});
      final vm = _makeVm(repo);

      // Écriture Hive en zone réelle (hors FakeAsync — cf. sameva-hive).
      // addEntry écrit dans la box 'settings' (clé 'activity_log') ET met _cache.
      await tester.runAsync(() async {
        await ActivityLogService.addEntry(ActivityLogEntry(
          type: ActivityType.quest,
          title: 'Quête test RGPD',
          date: DateTime(2026, 1, 1),
        ));
      });

      // Précondition : l'historique contient au moins l'entrée injectée.
      expect(
        ActivityLogService.getLog(),
        isNotEmpty,
        reason:
            "L'historique doit contenir au moins une entrée avant suppression",
      );

      // Appel deleteAccount avec réponse de succès complet.
      await tester.runAsync(() => vm.deleteAccount(
            invokeOverride: () async => _successResponse(),
          ));

      // L'historique doit être vide : _cache = null ET clé Hive supprimée.
      // getLog() relit Hive sur _cache == null → retourne [] si clé absente.
      expect(
        ActivityLogService.getLog(),
        isEmpty,
        reason:
            "L'historique d'activité doit être purgé après suppression RGPD réussie",
      );
    });

    testWidgets(
        'échec partiel (auth_user_deleted == false) → getLog() toujours non vide',
        (tester) async {
      final repo = _MockAuthRepository();
      when(() => repo.signOut()).thenAnswer((_) async {});
      final vm = _makeVm(repo);

      // Injection d'une entrée dans l'historique.
      await tester.runAsync(() async {
        await ActivityLogService.addEntry(ActivityLogEntry(
          type: ActivityType.levelUp,
          title: 'Niveau atteint — test fail partiel',
          date: DateTime(2026, 2, 1),
        ));
      });

      // Précondition : l'historique est non vide.
      expect(ActivityLogService.getLog(), isNotEmpty);

      // Appel deleteAccount avec réponse d'échec partiel.
      Object? thrownError;
      await tester.runAsync(() async {
        try {
          await vm.deleteAccount(
            invokeOverride: () async => _partialFailResponse(),
          );
        } on Exception catch (e) {
          thrownError = e;
        }
      });

      // Une exception doit avoir été levée.
      expect(thrownError, isA<Exception>());

      // L'historique NE doit PAS être purgé : même gate que le reste.
      expect(
        ActivityLogService.getLog(),
        isNotEmpty,
        reason:
            "L'historique d'activité ne doit PAS être purgé sur échec partiel",
      );

      // signOut ne doit PAS avoir été appelé.
      verifyNever(() => repo.signOut());
    });
  });
}
