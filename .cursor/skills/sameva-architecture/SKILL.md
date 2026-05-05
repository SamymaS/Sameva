---
name: sameva-architecture
description: Applique l'architecture MVVM/Clean et Provider du projet Sameva. Utiliser lors de l'ajout de fonctionnalités, du refactoring, de la création de pages ou ViewModels, ou quand l'utilisateur demande où placer du code ou comment structurer une feature.
---

# Architecture Sameva

## Structure des couches

```
lib/
├── config/          # Configuration Supabase, constantes et .env
├── data/            # Modèles et repositories (Supabase + Hive)
├── domain/          # Services métier purs
├── presentation/    # ViewModels ChangeNotifier et use cases
├── ui/
│   ├── pages/       # Écrans par feature (auth/, home/, quest, etc.)
│   ├── theme/       # AppTheme, AppColors, AppStyles
│   └── widgets/     # common/, minimalist/, magical/, fantasy/
└── utils/           # Helpers SVG/Figma
```

**Règle** : les pages dans `ui/pages/` n'appellent jamais directement Supabase, Hive ou les repositories. Elles consomment les ViewModels avec `context.watch<T>()` pour l'affichage et `context.read<T>()` pour les actions.

## Point d'entrée et navigation

- **main.dart** : initialise dotenv, Supabase, Hive (boxes `quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`), repositories, ViewModels globaux et `MultiProvider`.
- **app.dart** : Stack + AnimatedSwitcher + barre dock flottante. Pages principales (Sanctuaire, Quêtes, Inventaire, Avatar, Marché, Invocation, Minijeux, Profil, etc.). FAB flottant pour création de quête.

## ViewModels (état)

Provider reste le mécanisme d'injection et d'écoute. Ne pas introduire BLoC ni Riverpod.

| ViewModel | Stockage / dépendances | Rôle |
|----------|----------|------|
| AuthViewModel | AuthRepository / Supabase Auth | Connexion, inscription, session |
| QuestViewModel | QuestRepository / Supabase | CRUD quêtes et état partagé |
| PlayerViewModel | PlayerRepository / Hive + Supabase | Niveau, XP, or, cristaux, HP, streak |
| InventoryViewModel | Hive `inventory` | Inventaire, stacks, objets |
| EquipmentViewModel | Hive `equipment` | Slots d'équipement et items équipés |
| CatViewModel | Hive `cats` | Chats compagnons |
| ThemeViewModel | Hive `settings` | Thème sombre/clair/système |
| NotificationViewModel | Hive `settings` | Préférences et rappels |

Nouveau ViewModel partagé : le créer dans `presentation/view_models/`, l'enregistrer dans `main.dart` avec `MultiProvider`, et injecter repositories ou boxes selon le besoin. Toujours appeler `notifyListeners()` après une mutation d'état observable et exposer les erreurs à l'UI.

## Où placer le code

- **Nouvelle entité métier** → `domain/entities/` si elle est pure métier, sinon modèle dans `data/models/`
- **Règle métier / calcul** → `domain/services/`
- **Repository / datasource / modèle sérialisé** → `data/`
- **État partagé (UI)** → `presentation/view_models/`
- **Orchestration d'un cas UI complexe** → `presentation/use_cases/`
- **Nouvelle page** → `ui/pages/<feature>/`
- **Widget réutilisable** → `ui/widgets/` (minimalist, magical, fantasy ou common selon le style)

## Commandes utiles

```bash
flutter pub get
flutter run
flutter analyze
dart run build_runner build   # Après modification de modèles @HiveType
```
