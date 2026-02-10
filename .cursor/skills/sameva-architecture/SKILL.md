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
├── domain/          # Entities, repositories abstraits, services métier
├── presentation/    # Providers (ChangeNotifier)
├── ui/
│   ├── pages/       # Écrans par feature (auth/, home/, quest/, etc.)
│   ├── theme/       # AppTheme, AppColors, AppStyles
│   └── widgets/     # minimalist/, magical/, fantasy/, common/
└── utils/           # Helpers (SVG, Figma)
```

**Règles** : Les pages dans `ui/pages/` n'appellent pas directement les couches data. Elles utilisent `Provider.of<T>(context)` ou `context.watch<T>()` / `context.read<T>()`.

## Point d'entrée et navigation

- **main.dart** : initialise dotenv, Supabase, Hive (boxes `quests`, `playerStats`, `inventory`, `equipment`), enregistre les 6 providers, lance `SamevaApp`.
- **app_new.dart** : Stack + AnimatedSwitcher + barre dock flottante. 8 pages principales (Sanctuaire, Quêtes, Inventaire, Avatar, Marché, Invocation, Minijeux, Profil). FAB flottant pour création de quête.

## Providers (état)

| Provider | Stockage | Rôle |
|----------|----------|------|
| AuthProvider | Supabase Auth | Connexion email/mdp et anonyme, écoute auth |
| QuestProvider | Supabase DB | CRUD quêtes, filtres (actives/terminées/aujourd'hui/ratées), récompenses |
| PlayerProvider | Hive | Niveau, XP, or, cristaux, HP, moral, streak |
| InventoryProvider | Hive | 50 emplacements, stack d'items |
| EquipmentProvider | Hive | Slots d'équipement et items équipés |
| ThemeProvider | Hive | Thème sombre/clair/système |

Nouveau provider : le créer dans `presentation/providers/`, l'enregistrer dans `main.dart` avec `MultiProvider`, et utiliser les boxes Hive ou Supabase selon le besoin.

## Où placer le code

- **Nouvelle entité métier** → `domain/entities/`
- **Règle métier / calcul** → `domain/services/`
- **Repository abstrait** → `domain/` (interface)
- **Implémentation repo + models** → `data/`
- **État partagé (UI)** → `presentation/providers/`
- **Nouvelle page** → `ui/pages/<feature>/`
- **Widget réutilisable** → `ui/widgets/` (minimalist, magical, fantasy ou common selon le style)

## Commandes utiles

```bash
flutter pub get
flutter run
flutter analyze
dart run build_runner build   # Après modification de modèles @HiveType
```
