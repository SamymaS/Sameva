---
name: sameva-architecture
description: Applique l'architecture Clean et Provider du projet Sameva. Utiliser lors de l'ajout de fonctionnalités, du refactoring, de la création de pages ou providers, ou quand l'utilisateur demande où placer du code ou comment structurer une feature.
---

# Architecture Sameva

## Structure des couches

```
lib/
├── config/          # Configuration (Supabase, .env)
├── data/            # Implémentations repositories, models, datasources (Supabase + Hive)
├── domain/          # Entités, repositories abstraits, services métier
├── presentation/    # ViewModels ChangeNotifier et use cases
├── ui/
│   ├── pages/       # Écrans par feature (auth/, home/, quest/, etc.)
│   ├── theme/       # AppTheme, AppColors, AppStyles
│   └── widgets/     # minimalist/, magical/, fantasy/, common/
└── utils/           # Helpers (SVG, Figma)
```

**Règles** : Les pages dans `ui/pages/` n'appellent pas directement les couches data. Elles utilisent `Provider.of<T>(context)` ou `context.watch<T>()` / `context.read<T>()`.

## Point d'entrée et navigation

- **main.dart** : initialise dotenv, Supabase, Hive (boxes `quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`), `NotificationService`, enregistre les repositories et ViewModels, lance `SamevaApp`.
- **app.dart** : configure l'application, le thème et la navigation principale.

## ViewModels / Providers (état)

| Provider | Stockage | Rôle |
|----------|----------|------|
| AuthViewModel | Supabase Auth | Connexion email/mdp et anonyme, écoute auth |
| QuestViewModel | Supabase DB | CRUD quêtes, filtres, récompenses |
| PlayerViewModel | Hive + Supabase | Niveau, XP, or, cristaux, HP, moral, streak |
| InventoryViewModel | Hive | 50 emplacements, stack d'items |
| EquipmentViewModel | Hive | Slots d'équipement et items équipés |
| ThemeViewModel | Hive | Thème sombre/clair/système |
| NotificationViewModel | Hive + notifications locales | Préférences et rappels |

Nouveau ViewModel : le créer dans `presentation/view_models/`, l'enregistrer dans `main.dart` avec `MultiProvider`, et utiliser les repositories, use cases, boxes Hive ou Supabase selon le besoin. Appeler `notifyListeners()` après toute mutation d'état.

## Où placer le code

- **Nouvelle entité métier** → `domain/entities/`
- **Règle métier / calcul** → `domain/services/`
- **Repository abstrait** → `domain/` (interface)
- **Implémentation repo + models** → `data/`
- **État partagé (UI)** → `presentation/view_models/`
- **Nouvelle page** → `ui/pages/<feature>/`
- **Widget réutilisable** → `ui/widgets/` (minimalist, magical, fantasy ou common selon le style)

## Commandes utiles

```bash
flutter pub get
flutter run
flutter analyze
dart run build_runner build   # Après modification de modèles @HiveType
```
