# Intégration et déploiement continus (Sameva)

## Objectifs qualité (C2.1.1 / C2.1.2)

- **Analyse** : `flutter analyze` sans erreur ni avertissement (règle projet : 0 issue).
- **Tests** : `flutter test` entièrement vert avant fusion sur `main`.
- **Couverture** : générée sur la CI avec `flutter test --coverage` ; le pourcentage de lignes est affiché via `lcov --summary` lorsque l’outil est disponible (installé sur l’image Ubuntu du workflow).

## Pipeline GitHub Actions

Fichier : [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

Déclencheurs :

- **Push** sur les branches `main` et `develop`.
- **Pull request** ciblant `main`.

Étapes :

1. Checkout du dépôt.
2. Installation de Flutter **stable** (`subosito/flutter-action`, cache activé).
3. `flutter pub get`
4. `flutter analyze`
5. `flutter test`
6. `flutter test --coverage` (génère `coverage/lcov.info`, ignoré par Git via `.gitignore`).
7. (Optionnel) `lcov --summary coverage/lcov.info` — en `continue-on-error` si `lcov` échoue.

## Environnement de développement local

- **IDE** : VS Code ou Cursor avec l’extension Flutter / Dart.
- **SDK** : Flutter stable (voir [flutter.dev](https://docs.flutter.dev/get-started/install)).
- **Backend** : projet Supabase (URL + clé anon dans `.env`, non versionné).
- **Stockage local** : Hive (boxes ouvertes au démarrage dans `main.dart`).

## Déploiement des builds (hors CI actuelle)

Les étapes type **release** (non automatisées dans ce workflow minimal) :

- Android : `flutter build apk` ou `appbundle`.
- Web : `flutter build web`.
- Windows : `flutter build windows`.

Les secrets store / signatures (keystore Android, etc.) restent hors dépôt et se configurent sur la machine de build ou sur un service CI dédié aux releases.

## Évolution possible

- Ajouter un job `build` matrix (apk + web) sur tags `v*`.
- Seuil de couverture minimal avec `lcov --fail-under` une fois une baseline fixée.
- Déploiement web automatique (ex. Vercel, Firebase Hosting) après succès des tests sur `main`.
