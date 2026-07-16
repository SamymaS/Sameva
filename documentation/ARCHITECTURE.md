# Architecture Sameva

## Vue d'ensemble

Architecture **MVVM en quatre couches**, avec Provider et ChangeNotifier pour la gestion d'état.

```
lib/
├── config/         # Lecture du .env (URLs, clés)
├── data/           # Modèles + repositories : accès aux données (Supabase + Hive)
├── domain/         # Services : logique métier pure
├── presentation/   # ViewModels (ChangeNotifier) + use cases
└── ui/             # Pages, widgets, thème
```

**Règle de dépendance stricte** : `ui → presentation → domain → data`. Une couche ne connaît jamais celle qui la consomme.

---

## Couche Data

Accès aux données uniquement. Pas de `notifyListeners()`, pas de logique métier. Les repositories reçoivent leurs dépendances par constructeur (`SupabaseClient`, `Box`) et n'accèdent jamais à `Supabase.instance.client` en dur, ce qui les rend mockables.

| Repository | Rôle | Persistance |
| ---------- | ---- | ----------- |
| `auth_repository.dart` | Supabase Auth (signIn, signUp, signOut), expose les changements de session | Supabase |
| `user_repository.dart` | Table `users` (profil) | Supabase |
| `quest_repository.dart` | CRUD quêtes, reset des quêtes récurrentes | Supabase uniquement |
| `player_repository.dart` | Stats joueur | Hive (source de lecture) + `player_stats` en synchronisation |
| `cat_repository.dart` | Compagnons | Hive + `companions` |
| `ai_credits_repository.dart` | Portefeuille de jetons | Hive + `ai_validation_credits` |
| `premium_subscription_repository.dart` | État de l'abonnement | `premium_subscriptions` (lecture seule côté client) |
| `leaderboard_repository.dart` | Classement | `leaderboard_view` |

**Modèles** (`lib/data/models/`) : `Quest`, `PlayerStats`, `Item`, `CatModel`, `CharacterModel`, `CraftRecipeModel`, `LeaderboardEntryModel`, `AiValidationStateModel`.

Les modèles implémentent une double sérialisation : camelCase pour Hive (`toJson` / `fromJson`) et snake_case pour Supabase (`toSupabaseMap` / `fromSupabaseMap`).

> **Note Hive** : la persistance locale utilise du JSON simple, **pas** de `TypeAdapter`. Il n'y a aucune annotation `@HiveType` dans le projet et **aucune étape `build_runner` n'est nécessaire**.

---

## Couche Domain, services

Logique métier sans dépendance à l'UI ni aux repositories.

| Service | Rôle |
| ------- | ---- |
| `quest_rewards_calculator.dart` | XP et or selon difficulté, bonus de ponctualité et de streak |
| `validation_ai_service.dart` | Interface `ValidationAIService` + `MockValidationAIService` |
| `api_validation_ai_service.dart` | Appel HTTP de l'Edge Function de validation |
| `claude_validation_ai_service.dart` | Appel direct de l'API Messages (Claude) |
| `quest_suggestion_service.dart` | Interface de suggestion de quêtes |
| `api_quest_suggestion_service.dart` | Suggestion via Edge Function |
| `claude_quest_generator_service.dart` | Génération de quêtes via Claude |
| `item_factory.dart` | Génération d'items par rareté, catalogue du marché, gacha |
| `craft_service.dart` | Recettes de fabrication |
| `weekly_boss_service.dart` | Boss hebdomadaire |
| `achievement_service.dart` | Succès débloquables |
| `health_regeneration_service.dart` | Régénération passive des HP |
| `cat_mood_service.dart` | Humeur du compagnon |
| `minigame_service.dart` | Logique des mini-jeux |
| `activity_log_service.dart` | Journal d'activité (service statique, boîte `settings`) |
| `notification_service.dart` | Notifications locales |

L'abstraction de `ValidationAIService` permet de remplacer l'implémentation (mock en développement, API en production) sans toucher au reste du code.

---

## Couche Presentation, ViewModels

Chaque ViewModel est un `ChangeNotifier` qui consomme des repositories ou services et expose l'état à la vue.

| ViewModel | Portée |
| --------- | ------ |
| `AuthViewModel` | Global, **source des événements d'authentification** |
| `QuestViewModel` | Global, source de vérité unique des quêtes |
| `PlayerViewModel` | Global, stats joueur |
| `InventoryViewModel` | Global, inventaire |
| `EquipmentViewModel` | Global, équipement et cosmétiques |
| `CatViewModel` | Global, compagnons |
| `AiValidationCreditsService` | Global, portefeuille de jetons |
| `ThemeViewModel` | Global, préférence de thème |
| `NotificationViewModel` | Global, rappels |
| `QuestsListViewModel`, `CreateQuestViewModel`, `QuestValidationViewModel`, `ProfileViewModel`, `RewardsViewModel`, `SettingsViewModel`, `LeaderboardViewModel`, `CraftViewModel` | Locaux à une page |

`QuestViewModel` est l'unique autorité sur les quêtes : les ViewModels de page ne conservent pas de copie en mémoire, ils lisent `questVM.quests` et délèguent leurs mutations. Ce choix corrige un motif de sources de vérité parallèles désynchronisées observé à plusieurs reprises.

---

## Cycle de vie d'authentification

`AuthViewModel` expose deux flux d'événements, `onSignedIn` et `onSignedOut`. Tous les ViewModels et services porteurs d'un état propre à l'utilisateur les reçoivent par constructeur depuis `main.dart` :

```dart
final signedOutStream = authViewModel.onSignedOut;
final signedInStream  = authViewModel.onSignedIn;

final questViewModel  = QuestViewModel(questRepo, onSignedOut: signedOutStream, onSignedIn: signedInStream);
final playerViewModel = PlayerViewModel(playerRepo, onSignedOut: signedOutStream, onSignedIn: signedInStream);
// idem Inventory, Equipment, Cat, AiValidationCredits
```

- **À la connexion** : chaque composant recharge ses données distantes et réconcilie son cache local. Une garde idempotente évite le double chargement lorsqu'une page déclenche aussi un chargement.
- **À la déconnexion** : chaque composant vide son cache (`reset()`).

`ActivityLogService` fait exception : c'est un service statique dont le cache est purgé par `AuthViewModel._purgeHiveData()` lors de la déconnexion, et non par abonnement.

Ce câblage est documenté dans [`docs/adr/0001`](../docs/adr/0001-phase-zero-restructuration.md).

---

## Use cases

| Use case | Rôle |
| -------- | ---- |
| `complete_quest_use_case.dart` | Marque la quête complète, calcule les récompenses, distribue XP/or/cristaux, met à jour streak et succès, annule le rappel, journalise |
| `daily_reset_use_case.dart` | Réinitialisation quotidienne des quêtes récurrentes |

---

## Injection de dépendances

Les repositories sont instanciés une fois dans `main.dart` et exposés via `Provider.value`. Les ViewModels globaux sont enregistrés dans un `MultiProvider`; les ViewModels de page sont créés localement dans `didChangeDependencies()`.

---

## Conventions

- Fichiers : `snake_case` ; classes : `PascalCase` ; variables et méthodes : `camelCase`
- Commentaires `///` en tête de classe, en français
- Pas de `print()` : utiliser `debugPrint()`
- Tout le code, les commentaires et l'interface sont en français
