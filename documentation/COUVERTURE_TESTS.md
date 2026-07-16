# Couverture des tests

## Synthèse

| Indicateur | Valeur |
| ---------- | ------ |
| Fichiers de test | 64 |
| Groupes (`group`) | 147 |
| Cas de test déclarés (`test` + `testWidgets`) | 469 |
| Analyse statique | `flutter analyze`, 0 erreur |

> Les valeurs ci-dessus sont obtenues par comptage des déclarations dans `test/`. Le décompte affiché par `flutter test` peut différer légèrement si des cas sont générés dynamiquement dans des boucles.

Répartition par couche :

| Couche | Fichiers | Groupes | Cas |
| ------ | -------- | ------- | --- |
| `test/domain/` | 9 | 24 | 71 |
| `test/data/` | 14 | 38 | 74 |
| `test/presentation/` | 23 | 63 | 230 |
| `test/ui/` (+ `widget_test.dart`) | 18 | 22 | 94 |
| **Total** | **64** | **147** | **469** |

---

## Commandes

```bash
flutter test
flutter test --coverage
```

Pour un pourcentage global et un rapport HTML (nécessite `lcov`) :

```bash
lcov --summary coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
```

Sur Windows, utiliser WSL pour ces deux commandes.

---

## Principes

La stratégie suit la pyramide des tests : une base large de tests unitaires rapides et déterministes sur Domain, Data et Presentation, complétée par des tests widget sur les chemins réellement empruntés par l'utilisateur. `flutter_test` est enrichi par `mocktail` (mocks typés, sans génération de code). Chaque test est indépendant, déterministe et sans dépendance réseau.

---

## `test/domain/` — services métier

| Fichier | Cible |
| ------- | ----- |
| `quest_rewards_calculator_test.dart` | `QuestRewardsCalculator` (récompenses, bonus, pénalités) |
| `cat_mood_service_test.dart` | `CatMoodService` |
| `item_factory_test.dart` | `ItemFactory` (gacha, catalogue, rareté) |
| `health_regeneration_service_test.dart` | `HealthRegenerationService` (cas limites, plafond, horodatage) |
| `api_validation_ai_service_test.dart` | `ApiValidationAIService` (`http.Client` injecté) |
| `claude_validation_ai_service_test.dart` | `ClaudeValidationAIService` (parsing Messages API) |
| `mock_validation_ai_service_test.dart` | `MockValidationAIService` (`simulatedDelay: Duration.zero`) |
| `claude_quest_generator_service_test.dart` | `ClaudeQuestGeneratorService` (parsing, erreurs HTTP) |

## `test/data/` — modèles et repositories

Sérialisation aller-retour (`toSupabaseMap` / `fromSupabaseMap`), parsing des enums avec repli, dates ISO, et CRUD des repositories via mocks Supabase et Hive.

## `test/presentation/` — ViewModels

Un fichier de test par ViewModel : authentification, thème, création et liste de quêtes, progression joueur, récompenses, validation IA (succès, échec, seuil 70), inventaire (50 slots), équipement, profil, paramètres, compagnons, notifications, portefeuille de jetons.

## `test/ui/` — widgets

Tests widget sur le chemin réel de validation, c'est-à-dire la page effectivement empruntée par l'utilisateur, afin d'éviter de tester du code jamais instancié en production. `test/widget_test.dart` couvre le rendu de `LoginPage` avec un `AuthRepository` mocké.

## `test/helpers/`

`quest_test_factory.dart` : `buildTestQuest` pour des dates déterministes.

---

## Zones non couvertes

| Zone | Justification |
| ---- | ------------- |
| Repositories concrets (accès réseau réel) | Dépendance Supabase et Hive réelle ; couverts indirectement via mocks depuis les ViewModels |
| `NotificationService` (plugin natif) | Planification réelle hors tests unitaires ; `NotificationViewModel` accepte un callback injectable |
| Edge Functions (Deno) | Non couvertes par `flutter test` ; testées manuellement via `curl` et le cahier de recettes |

---

## Précision sur `QuestValidationViewModel`

Le ViewModel expose `isAnalyzing`, `result` (`ValidationResult` : score, `isValid`, explication) et `proofImage`. Il n'y a pas de champ `errorMessage` : une erreur réseau ou service remonte par exception depuis `analyzeProof` (comportement testé). Le reset passe par `setProof(null)` ou par une nouvelle preuve, qui efface le résultat précédent.
