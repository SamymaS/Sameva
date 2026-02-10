# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sameva is a gamified task management Flutter app where users complete quests to earn XP, gold, and items. It features RPG mechanics (leveling, inventory, equipment, gacha system, mini-games) built on Clean Architecture with Provider state management.

## Commands

```bash
flutter pub get                    # Install dependencies
flutter run                        # Run app (auto-detects device)
flutter run -d chrome              # Run on Chrome
flutter run -d windows             # Run on Windows
flutter analyze                    # Run static analysis (flutter_lints)
flutter test                       # Run tests
flutter test test/widget_test.dart # Run single test file
dart run build_runner build        # Generate Hive adapters (after modifying @HiveType models)
flutter build apk                  # Build Android release
flutter build web                  # Build web release
```

## Architecture

**Clean Architecture** with 4 layers:

```
lib/
├── config/          # Supabase configuration (reads from .env)
├── data/            # Repositories impl, models, datasources (Supabase + Hive)
├── domain/          # Entities, abstract repositories, business services
├── presentation/    # Providers (ChangeNotifier state management)
├── ui/
│   ├── pages/       # Screens organized by feature (auth/, home/, quest/, etc.)
│   ├── theme/       # AppTheme, AppColors, AppStyles (Material 3)
│   └── widgets/     # Reusable widgets: minimalist/, magical/, fantasy/, common/
└── utils/           # SVG/Figma asset helpers
```

**Entry point**: `lib/main.dart` initializes dotenv, Supabase, and Hive boxes (`quests`, `playerStats`, `inventory`, `equipment`), then runs the app via `lib/app_new.dart`.

**Navigation**: `app_new.dart` uses a Stack with AnimatedSwitcher and a floating dock bar. 8 main pages: Sanctuary (home), Quests, Inventory, Avatar, Market, Invocation, Minigames, Profile. A floating FAB opens quest creation.

## State Management (Provider)

6 providers registered via MultiProvider in `main.dart`:

| Provider | Storage | Purpose |
|----------|---------|---------|
| `AuthProvider` | Supabase Auth | Email/password & anonymous login, auth state listener |
| `QuestProvider` | Supabase DB | Quest CRUD, filtering (active/completed/today/missed), reward calculation |
| `PlayerProvider` | Hive | Level, XP, gold, crystals, HP, moral, streak |
| `InventoryProvider` | Hive | 50-slot item management with stacking |
| `EquipmentProvider` | Hive | Equipment slots and equipped items |
| `ThemeProvider` | Hive | Dark/light/system theme persistence |

## Backend & Persistence

- **Supabase**: Authentication + PostgreSQL for quests, user profiles, equipment. Config in `lib/config/supabase_config.dart`, credentials via `.env` (not committed).
- **Hive**: Local persistence for player stats, inventory, settings. Boxes opened at startup in `main.dart`.
- `.env` must contain `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

## Design System

- **Material 3** with custom light/dark themes defined in `ui/theme/`
- **Colors**: `AppColors` — turquoise primary (#4FD1C5), violet secondary (#805AD5), gold accent (#F6E05E), night blue dark bg (#0F172A)
- **Fonts**: MedievalSharp (fantasy headings), Press Start 2P (pixel game stats), Quicksand/Poppins (body)
- **Rarity colors**: Common (gray), Uncommon (green), Rare (blue), Epic (violet), Legendary (gold), Mythic (red)
- **Widget categories**: `minimalist/` (clean flat components), `magical/` (animated glow/particles), `fantasy/` (RPG-themed)

## Key Domain Services

- `QuestRewardsCalculator`: XP = 10 × difficulty, Gold = 25 × difficulty, with timing bonuses (+25% early, -20% late) and streak bonus (+10% at 7+ days)
- `BonusMalusService`: Quest modifier system
- `HealthRegenerationService`: HP recovery mechanics
- `ItemFactory`: Creates items with rarity levels

## Language

The app UI, documentation, and commit messages are in **French**.
