# Couverture des tests unitaires (Sameva)

## Commandes

```bash
flutter test --coverage
```

Pour un pourcentage global et un rapport HTML (nécessite [lcov](https://github.com/linux-test-project/lcov) sur le PATH) :

```bash
lcov --summary coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
```

Sur Windows, installer lcov ou utiliser WSL pour ces commandes.

## Périmètre actuel (tests unitaires)

| Zone | Fichiers de test | Cible |
|------|------------------|--------|
| `domain/services` | `test/domain/quest_rewards_calculator_test.dart`, `test/domain/cat_mood_service_test.dart` | Logique pure (récompenses, humeur chat) |
| `data/models` | `test/data/player_stats_model_test.dart`, `test/data/quest_model_enums_test.dart` | Sérialisation et enums |
| `presentation/view_models` | `test/presentation/theme_view_model_test.dart`, `test/presentation/create_quest_view_model_test.dart` | Orchestration avec dépendances mockées (`mocktail`) |
| Widget | `test/widget_test.dart` | Démarrage minimal de l’app |

## Zones volontairement hors tests unitaires

- **Écrans et widgets** (`lib/ui/`) : rendu et navigation ; couverts plutôt par tests widget ciblés ou manuellement.
- **Repositories concrets** (`AuthRepository`, `QuestRepository`, etc.) : dépendent de Supabase ; à mocker côté ViewModel (comme pour `CreateQuestViewModel`).
- **Services liés à Hive non injecté** : ex. `HealthRegenerationService` lit directement `Hive.box('settings')` ; tests unitaires nécessiteraient une abstraction ou une initialisation Hive de test.
- **IA / notifications** : services réseau ou plateforme ; tests dédiés possibles avec clients HTTP mockés si besoin.

## Objectif RNCP (C2.2.2)

La base de tests ci-dessus couvre la logique métier critique et des ViewModels représentatifs. Pour augmenter la couverture : étendre les tests des autres ViewModels (même schéma mock repository / `AuthViewModel`) et ajouter des tests sur les services domaine restants qui restent purs et injectables.
