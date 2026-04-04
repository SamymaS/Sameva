# Architecture Sameva

## Vue d'ensemble

Architecture **MVVM** en 3 couches strictes, avec Provider/ChangeNotifier comme gestion d'état.

```
lib/
├── data/           # Repositories — accès aux données (Supabase + Hive)
├── domain/         # Services — logique métier pure
├── presentation/   # ViewModels — état UI (ChangeNotifier)
└── ui/             # Pages + Widgets
```

**Règle absolue** : les dépendances ne vont que vers l'intérieur.
`ui` → `presentation` → `domain` ← `data`

---

## Couche Data — Repositories

Accès aux données uniquement. Pas de `notifyListeners()`, pas de logique métier.

| Fichier | Rôle |
|---|---|
| `auth_repository.dart` | Supabase Auth (signIn, signUp, signOut) |
| `user_repository.dart` | Table `users` Supabase (création/lecture profil) |
| `quest_repository.dart` | CRUD quêtes Supabase + reset daily |
| `player_repository.dart` | Stats joueur (Hive offline-first + sync Supabase) |

**Convention** : les repositories reçoivent leurs dépendances par constructeur (`SupabaseClient`, `Box`), retournent des modèles ou lancent des exceptions. Jamais d'accès global `Supabase.instance.client` en dur.

---

## Couche Domain — Services

Logique métier sans dépendances UI ni repositories.

| Fichier | Rôle |
|---|---|
| `quest_rewards_calculator.dart` | XP = 10 × difficulté, bonus timing/streak |
| `validation_ai_service.dart` | Interface + mock validation par preuve photo |
| `claude_validation_ai_service.dart` | Implémentation Claude API |
| `item_factory.dart` | Génération d'items par rareté, catalogue marché |
| `health_regeneration_service.dart` | Récupération HP nocturne |
| `cat_mood_service.dart` | Humeur des chats compagnons |
| `notification_service.dart` | Notifications locales |

---

## Couche Presentation — ViewModels

Chaque ViewModel est un `ChangeNotifier`. Il consomme des Repositories ou Services et expose l'état à la vue.

| ViewModel | Dépendances | Pages |
|---|---|---|
| `ThemeViewModel` | Hive `settings` | `app.dart`, `settings_page.dart` |
| `AuthViewModel` | `AuthRepository` | `login_page.dart`, `register_page.dart` |
| `QuestViewModel` | `QuestRepository` | toutes les pages quêtes |
| `PlayerViewModel` | `PlayerRepository` | sanctuary, profil, récompenses |
| `InventoryViewModel` | Hive `inventory` | `inventory_page.dart`, `market_page.dart` |
| `EquipmentViewModel` | Hive `equipment` | `inventory_page.dart` |
| `CatViewModel` | Hive `cats` | `cat_page.dart`, `sanctuary_page.dart` |
| `NotificationViewModel` | Hive `settings` | `settings_page.dart` |
| `ProfileViewModel` | `PlayerRepository`, `QuestRepository` | `profile_page.dart` |
| `QuestsListViewModel` | `QuestRepository` | `quests_list_page.dart` |
| `CreateQuestViewModel` | `QuestRepository` | `create_quest_page.dart` |
| `QuestValidationViewModel` | `QuestRepository` | `quest_validation_page.dart` |

### ViewModels globaux vs locaux

Les ViewModels à état partagé entre plusieurs pages sont enregistrés dans `main.dart` via `MultiProvider` :

```dart
ChangeNotifierProvider(create: (_) => ThemeViewModel(settingsBox))
ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo))
ChangeNotifierProvider.value(value: questViewModel)
ChangeNotifierProvider.value(value: playerViewModel)
ChangeNotifierProvider.value(value: inventoryViewModel)
ChangeNotifierProvider.value(value: equipmentViewModel)
ChangeNotifierProvider.value(value: catViewModel)
ChangeNotifierProvider(create: (_) => NotificationViewModel(settingsBox))
```

Les ViewModels spécifiques à une seule page sont créés localement dans `didChangeDependencies()` :

```dart
_vm ??= QuestsListViewModel(
  context.read<QuestRepository>(),
  context.read<AuthViewModel>(),
);
```

---

## Use Cases

`lib/presentation/use_cases/complete_quest_use_case.dart` orchestre la complétion d'une quête :
1. Marquer la quête complète (`QuestViewModel`)
2. Calculer les récompenses (`QuestRewardsCalculator`)
3. Distribuer XP, or, cristaux (`PlayerViewModel`)
4. Mettre à jour le streak et les achievements
5. Annuler le rappel de notification

---

## Injection de dépendances (main.dart)

Les repositories sont instanciés une fois dans `main.dart` et exposés via `Provider.value` pour permettre l'injection dans les ViewModels de page :

```dart
Provider<QuestRepository>.value(value: questRepo)
Provider<PlayerRepository>.value(value: playerRepo)
```

---

## Conventions

- Fichiers : `snake_case`
- Classes : `PascalCase`
- Variables/méthodes : `camelCase`
- Commentaires : `///` en tête de classe (1–2 lignes)
- Imports : relatifs (pas de `package:sameva/...`)
- Pas de `print()` : utiliser `debugPrint()` si nécessaire
