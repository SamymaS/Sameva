# Architecture Sameva

## Vue d'ensemble

Architecture MVVM en 3 couches :

```
lib/
├── data/           # Repositories — accès aux données (Supabase + Hive)
├── domain/         # Services — logique métier pure
├── presentation/   # ViewModels — état UI (ChangeNotifier)
└── ui/             # Pages + Widgets
```

---

## Couche Data — Repositories

Accès aux données uniquement. Pas de `notifyListeners()`, pas de logique métier.

| Fichier | Rôle |
|---|---|
| `auth_repository.dart` | Supabase Auth (signIn, signUp, signOut) |
| `user_repository.dart` | Table `users` Supabase (création profil) |
| `quest_repository.dart` | CRUD quêtes Supabase + reset daily |
| `player_repository.dart` | Stats joueur (Hive offline-first + sync Supabase) |

**Règle** : les repositories prennent leurs dépendances par constructeur (`SupabaseClient`, `Box`), retournent des modèles ou lancent des exceptions.

---

## Couche Domain — Services

Logique métier sans dépendances UI.

| Fichier | Rôle |
|---|---|
| `quest_rewards_calculator.dart` | XP = 10 × difficulté, bonus timing/streak |
| `validation_ai_service.dart` | Interface + mock validation par preuve photo |
| `claude_validation_ai_service.dart` | Implémentation Claude API |
| `health_regeneration_service.dart` | Récupération HP nocturne |
| `item_factory.dart` | Génération d'items par rareté |
| `notification_service.dart` | Notifications locales |
| `cat_mood_service.dart` | Humeur des chats compagnons |

---

## Couche Presentation — ViewModels migrés

Chaque ViewModel est un `ChangeNotifier`. Il consomme des Repositories et expose l'état à la vue.

| ViewModel | Repositories | Pages |
|---|---|---|
| `ThemeViewModel` | Hive `settings` box | `app.dart`, `settings_page.dart` |
| `AuthViewModel` | `AuthRepository` | `app.dart`, `login_page.dart`, `register_page.dart` |
| `ProfileViewModel` | `PlayerRepository`, `QuestRepository` | `profile_page.dart` |
| `QuestsListViewModel` | `QuestRepository` | `quests_list_page.dart` |
| `CreateQuestViewModel` | `QuestRepository` | `create_quest_page.dart` |
| `QuestValidationViewModel` | `QuestRepository` | *(prêt — migration page à faire)* |

---

## Providers en cours de migration

Ces providers existent encore dans `lib/presentation/providers/` et sont utilisés directement par des pages non encore migrées.

| Provider | Pages qui l'utilisent encore |
|---|---|
| `PlayerProvider` | sanctuary, inventory, invocation, market, rewards, minigames, quest_validation |
| `QuestProvider` | sanctuary, create_quest_by_theme, generate_quests, quest_validation |
| `InventoryProvider` | inventory, invocation, cat, quest_validation |
| `EquipmentProvider` | inventory, quest_validation |
| `CatProvider` | cat, sanctuary, invocation, market |
| `NotificationProvider` | settings |

**Prochain chantier** : créer des ViewModels pour chacune de ces pages et supprimer `providers/`.

---

## Violation architecturale connue

`domain/use_cases/complete_quest_use_case.dart` dépend de providers de la couche présentation.
À corriger en extrayant la logique joueur (XP, streak, achievements) dans un `PlayerService` de domaine.

---

## Injection de dépendances (main.dart)

Les repositories sont instanciés une fois dans `main.dart` et exposés via `Provider.value` :

```dart
// Repositories globaux
Provider<QuestRepository>.value(value: questRepo)
Provider<PlayerRepository>.value(value: playerRepo)

// ViewModels globaux (état partagé entre pages)
ChangeNotifierProvider(create: (_) => ThemeViewModel(settingsBox))
ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo))
```

Les ViewModels de page sont créés localement dans `didChangeDependencies()` :

```dart
_vm ??= QuestsListViewModel(
  context.read<QuestRepository>(),
  context.read<AuthViewModel>(),
);
```
