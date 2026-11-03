# 0007. Socle client : navigation, état, cache et configuration (Sprint 2)

- **Statut** : Accepté le 2026-10-30 (décision déléguée par Samy : « fais ce qui te semble juste »)
- **Date** : 2026-10-21

---

## Contexte

Depuis le Sprint 1 (ADR 0005), le serveur détient l'économie : le client doit
seulement afficher un état distant, le mettre en cache et envoyer des
intentions. Le socle actuel n'est pas fait pour ça :

- navigation par `Stack` + `AnimatedSwitcher` dans `app.dart` et 13 appels
  `Navigator.push`/`pushNamed` dispersés : pas de liens profonds (notification,
  retour d'achat), pas de pile par onglet du dock, transitions éparpillées ;
- 11 ViewModels `ChangeNotifier` câblés à la main dans `main.dart`, chacun
  réimplémentant chargement, erreur et réinitialisation à la déconnexion ;
- 7 boîtes Hive non typées (JSON) et des `Hive.box('settings')` appelés depuis
  les pages ; Hive 2 n'est plus activement maintenu ;
- `.env` déclaré comme asset (lisible dans l'APK), session Supabase stockée en
  clair ;
- pages de 1 000 à 1 700 lignes (profil, inventaire, quête, invocation).

## Décision

1. **Organisation par fonctionnalité** : `lib/features/<nom>/{data,domain,presentation}`
   et `lib/core/` (réseau, cache, thème, routeur, erreurs). Une page ne dépasse
   pas 400 lignes ; au-delà, elle est découpée en widgets du même dossier.
2. **Navigation : `go_router`** avec routes typées (`go_router_builder`),
   `StatefulShellRoute.indexedStack` pour le dock (une pile par onglet, état
   conservé), redirections d'authentification centralisées, liens profonds
   `sameva://app/quete/<id>` et retour d'achat. Les transitions sont définies une
   seule fois (`CustomTransitionPage` + package `animations`) et déclenchent
   les sons via le GameEventBus (ADR 0003).
3. **État : Riverpod** (`flutter_riverpod`, `riverpod_annotation`).
   `AsyncNotifier` pour l'état serveur ; un `authStateProvider` dont dépendent
   tous les providers d'utilisateur (invalidation automatique à la
   déconnexion, ce qui remplace le mécanisme de l'ADR 0001). Cohabitation
   transitoire avec Provider : `ProviderScope` à la racine, migration
   fonctionnalité par fonctionnalité, suppression de `provider` en fin de S3.
4. **Cache : Drift (SQLite)** à la place de Hive. Schéma typé et versionné,
   requêtes réactives (`watch`). Lecture « cache puis réseau ». Les intentions
   faisables hors ligne (créer, éditer, supprimer une quête active) passent par
   une table `outbox` rejouée au retour du réseau avec une clé d'idempotence ;
   tout ce qui touche à l'économie et à l'Oracle exige le réseau.
5. **Configuration et secrets** : `--dart-define-from-file=config/<env>.json`
   (dev, staging, prod) ; suppression de l'asset `.env` ; session Supabase dans
   `flutter_secure_storage` ; fuseau IANA déclaré au serveur via
   `flutter_timezone` à la première connexion.
6. **Observabilité** : Sentry (`sentry_flutter`) avec le code métier de
   `GameApiException` en étiquette, sans donnée personnelle.

Pilote : la fonctionnalité Quêtes + Oracle est migrée de bout en bout en S2 ;
les autres suivent en S3 (économie) et au fil des sprints.

## Alternatives écartées

- **Garder Provider** : pas d'invalidation déclarative, pas de dépendances
  entre états, beaucoup de code de cycle de vie manuel (ADR 0001).
- **BLoC** : plus verbeux pour un développeur seul, déjà retiré du projet (P1.1).
- **Isar / ObjectBox** : moins de garanties de maintenance qu'SQLite ; pas de
  requêtes relationnelles comme Drift.
- **PowerSync (synchronisation Postgres ↔ SQLite)** : séduisant, mais réplique
  des tables alors que le modèle est désormais « lecture + intentions » ; coût
  et dépendance à un service tiers. À réévaluer si le hors-ligne devient central.
- **auto_route** : équivalent fonctionnel, moins aligné avec l'écosystème
  Flutter officiel que go_router.

## Conséquences

- Positif : liens profonds, état par onglet, invalidation automatique au
  changement de compte, cache typé, plus aucun secret dans l'APK.
- Négatif : deux systèmes d'état cohabitent pendant deux sprints ; génération
  de code (`build_runner`) réintroduite pour Drift, Riverpod et go_router.
- Migration des données locales : les boîtes Hive ne contiennent plus que du
  cache (sauf inventaire jusqu'au S3) ; elles sont abandonnées sans migration
  après le S3, l'inventaire étant alors servi par le serveur.
- Critères de validation du S2 : créer, prouver et valider une quête en mode
  avion puis en ligne sans incohérence ; ouvrir une quête depuis une
  notification ; `flutter analyze` à zéro ; tests d'intégration du parcours.

## Avancement

- 2026-10-30 : configuration compilée (`config/<env>.json`, plus d'asset `.env`),
  session chiffrée sur mobile avec reprise de l'ancienne session, go_router
  (dock à une pile par onglet, redirections, lien profond `sameva://app/quete/<id>`),
  `ProviderScope` et providers de base (`lib/core/providers.dart`).
  Reste : migration Quêtes + Oracle en Riverpod, cache Drift et outbox, Sentry.
