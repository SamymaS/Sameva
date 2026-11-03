import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/router/app_router.dart';

void main() {
  String? r(String chemin, {bool connecte = true, bool accueil = true}) =>
      redirectionPour(chemin: chemin, connecte: connecte, accueilTermine: accueil);

  group('non connecté', () {
    test('toute page mène à la connexion', () {
      expect(r(Routes.quetes, connecte: false), Routes.connexion);
      expect(r(Routes.validerQuete('abc'), connecte: false), Routes.connexion);
    });
    test('connexion et inscription restent accessibles', () {
      expect(r(Routes.connexion, connecte: false), isNull);
      expect(r(Routes.inscription, connecte: false), isNull);
    });
  });

  test('connecté sans accueil terminé : accueil (onboarding) d\'abord', () {
    expect(r(Routes.quetes, accueil: false), Routes.bienvenue);
    expect(r(Routes.bienvenue, accueil: false), isNull);
  });

  group('connecté', () {
    test('jamais renvoyé vers la connexion ni l\'onboarding', () {
      expect(r(Routes.connexion), Routes.accueil);
      expect(r(Routes.bienvenue), Routes.accueil);
      expect(r('/'), Routes.accueil);
    });
    test('les liens profonds passent', () {
      expect(r(Routes.validerQuete('abc')), isNull);
      expect(r(Routes.parametres), isNull);
    });
  });
}
