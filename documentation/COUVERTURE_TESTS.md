# Couverture des tests unitaires (Sameva)

## Synthèse

| Indicateur | Valeur (à jour avec `flutter test`) |
|------------|-------------------------------------|
| **Nombre total de tests** | 145 (`flutter test` sans option) |
| **Analyse statique** | `flutter analyze` — 0 issue |

## Commandes

```bash
flutter test
flutter test --coverage
```

Pour un pourcentage global et un rapport HTML (nécessite [lcov](https://github.com/linux-test-project/lcov) sur le PATH) :

```bash
lcov --summary coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
```

Sur Windows, installer lcov ou utiliser WSL pour ces commandes.

## Dossiers couverts

### `test/domain/` — services métier

| Fichier | Cible dans `lib/domain/` |
|---------|---------------------------|
| `quest_rewards_calculator_test.dart` | `QuestRewardsCalculator` |
| `cat_mood_service_test.dart` | `CatMoodService` |
| `item_factory_test.dart` | `ItemFactory` (gacha, catalogue, génération) |
| `health_regeneration_service_test.dart` | `HealthRegenerationService` (Hive `settings` en répertoire temporaire) |
| `api_validation_ai_service_test.dart` | `ApiValidationAIService` avec `http.Client` injecté (`MockClient`) |
| `claude_validation_ai_service_test.dart` | `ClaudeValidationAIService` (parsing réponse Messages API + `MockClient`) |

### `test/data/` — modèles / enums

| Fichier | Cible |
|---------|--------|
| `player_stats_model_test.dart` | `PlayerStats` JSON |
| `quest_model_enums_test.dart` | Enums quête (parsing Supabase) |
| `character_appearance_test.dart` | `CharacterAppearance` JSON / défauts / `copyWith` |
| `quest_from_supabase_map_test.dart` | `Quest.fromSupabaseMap`, dates ISO ; `CatStats` JSON |
| `quest_to_supabase_roundtrip_test.dart` | `toSupabaseMap` ↔ `fromSupabaseMap`, `is_completed` |
| `item_model_test.dart` | `Item` JSON, `slotForItem`, `cosmeticSlotForItem` |

### `test/presentation/` — ViewModels

| Fichier | ViewModel |
|---------|-----------|
| `auth_view_model_test.dart` | `AuthViewModel` |
| `theme_view_model_test.dart` | `ThemeViewModel` |
| `create_quest_view_model_test.dart` | `CreateQuestViewModel` |
| `quests_list_view_model_test.dart` | `QuestsListViewModel` |
| `player_view_model_test.dart` | `PlayerViewModel` (+ Hive `settings`) |
| `rewards_view_model_test.dart` | `RewardsViewModel` (proxy `PlayerViewModel`) |
| `quest_view_model_test.dart` | `QuestViewModel` |
| `quest_validation_view_model_test.dart` | `QuestValidationViewModel` + `ValidationAIService` mocké |
| `inventory_view_model_test.dart` | `InventoryViewModel` (box mockée) |
| `equipment_view_model_test.dart` | `EquipmentViewModel` + inventaire mocké |
| `profile_view_model_test.dart` | `ProfileViewModel` (auth + repos mockés) |
| `settings_view_model_test.dart` | `SettingsViewModel` (façade thème / notif / joueur / auth) |
| `cat_view_model_test.dart` | `CatViewModel` (box `cats` mockée) |
| `notification_view_model_test.dart` | `NotificationViewModel` (box mockée + `persistAndScheduleReminder` injecté pour éviter le plugin) |

### `test/helpers/`

| Fichier | Rôle |
|---------|------|
| `quest_test_factory.dart` | `buildTestQuest` pour dates déterministes |

### Widget minimal

| Fichier | Rôle |
|---------|------|
| `test/widget_test.dart` | Smoke test Material (pas l’app complète) |

## Dossiers non couverts ou partiellement couverts

| Zone | Justification |
|------|----------------|
| **`lib/ui/`** | Écrans et widgets : coût / rapport pour la certification RNCP moindre que ViewModels + domaine ; possibles tests widget ciblés plus tard. |
| **Repositories concrets** | `AuthRepository`, `QuestRepository`, `PlayerRepository` : dépendance Supabase / Hive réelle ; les tests passent par des **mocks** depuis les ViewModels. |
| **`NotificationService` (plugin)** | Planification réelle des notifications : hors tests unitaires ; `NotificationViewModel` accepte un callback `persistAndScheduleReminder` pour les tests. |
| **ViewModels restants** | Écrans mineurs sans VM dédiée testée. |
| **Modèles** | Autres entités utilisateur / persistance si elles grossissent. |

## Argumentaire RNCP (rappel)

L’architecture MVVM permet de tester **services purs**, **orchestration ViewModel** et **sérialisation** sans lancer Supabase, sans UI ni device. La CI (`.github/workflows/ci.yml`) exécute `flutter analyze` et `flutter test` à chaque push / PR sur les branches configurées.
