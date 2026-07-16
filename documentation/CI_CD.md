# Intégration continue et déploiement

## Objectifs qualité

- **Analyse statique** : `flutter analyze` sans erreur.
- **Tests** : `flutter test` entièrement vert avant toute fusion sur `main`.
- **Couverture** : générée à chaque exécution via `flutter test --coverage`.

---

## Pipeline d'intégration continue

Fichier : [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). Workflow `Sameva CI`, job unique `analyze-and-test` sur `ubuntu-latest`.

**Déclencheurs** : push sur `main` et `develop`, pull request ciblant `main`.

**Étapes réellement exécutées** :

1. Checkout du dépôt (`actions/checkout@v4`).
2. Installation de Flutter, canal **stable**, avec cache (`subosito/flutter-action@v2`).
3. Génération du `.env` depuis les GitHub Secrets (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). `VALIDATION_AI_URL` est laissée **vide**, ce qui force le `MockValidationAIService` : la CI ne consomme donc aucun crédit Anthropic et ne dépend pas du réseau IA.
4. `flutter pub get`
5. `flutter analyze --no-fatal-warnings`
6. `flutter test --coverage`
7. Résumé de couverture : comptage des lignes instrumentées et des fichiers couverts depuis `coverage/lcov.info`.

> **Portée réelle du pipeline** : la CI **analyse et teste**. Elle ne compile pas d'artefact et ne déploie rien. La compilation et le déploiement sont réalisés hors CI (voir plus bas).

> **Note sur `--no-fatal-warnings`** : les avertissements sont affichés mais ne font pas échouer le job. Seules les erreurs bloquent. Retirer ce drapeau rendrait la porte de qualité strictement bloquante sur les avertissements.

### Secrets d'intégration continue

| Secret | Où le trouver |
| ------ | ------------- |
| `SUPABASE_URL` | Dashboard Supabase, Settings, API |
| `SUPABASE_ANON_KEY` | Dashboard Supabase, Settings, API |

---

## Déploiement (hors CI)

Le déploiement n'est pas automatisé par le workflow actuel. Il s'effectue à la demande :

**Application cliente**

```bash
flutter build apk --release      # Android
flutter build web                # Web
```

**Backend (Edge Functions)**

```bash
supabase functions deploy                       # les cinq fonctions
supabase secrets set ANTHROPIC_API_KEY=sk-ant-... 
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

**Base de données**

```bash
supabase db push                 # applique les migrations de supabase/migrations/
```

Les secrets de signature (keystore Android) restent hors du dépôt et sur la machine de build.

→ Détail complet : [SUPABASE_EDGE_FUNCTION_IA.md](SUPABASE_EDGE_FUNCTION_IA.md)

---

## Environnement de développement local

- **IDE** : Visual Studio Code avec les extensions Flutter et Dart.
- **SDK** : Flutter canal stable.
- **Backend** : projet Supabase (URL et clé anon dans `.env`, non versionné).
- **Stockage local** : Hive, boîtes ouvertes au démarrage dans `main.dart`.

---

## Évolutions envisagées

- Workflow `release.yml` déclenché sur tag `v*` qui compile l'APK et l'attache à une GitHub Release.
- Seuil de couverture minimal bloquant une fois une baseline établie.
- Retrait de `--no-fatal-warnings` pour rendre la porte de qualité stricte.
- Déploiement automatique des Edge Functions après succès des tests sur `main`.
