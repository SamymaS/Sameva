# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sameva is a gamified task management Flutter app where users complete quests to earn XP, gold, and items. It features RPG mechanics (leveling, inventory, equipment, gacha system, mini-games) built on Clean Architecture with Provider state management.

## Commands

```bash
flutter pub get                    # Install dependencies
flutter run --dart-define-from-file=config/dev.json   # Run app (config: config/README.md)
flutter run -d chrome              # Run on Chrome
flutter run -d windows             # Run on Windows
flutter analyze                    # Run static analysis (flutter_lints)
flutter test                       # Run tests
flutter test test/widget_test.dart # Run single test file
# Note: no build_runner step — Hive uses plain JSON (toJson/fromJson), not TypeAdapters
flutter build apk                  # Build Android release
flutter build web                  # Build web release
```

## Architecture

**Clean Architecture** with 4 layers:

```
lib/
├── config/          # Configuration compilée (dart-define, voir config/README.md)
├── core/            # Socle transverse (auth : session chiffrée, ...)
├── data/            # Repositories impl, models, datasources (Supabase + Hive)
├── domain/          # Entities, abstract repositories, business services
├── presentation/    # Providers (ChangeNotifier state management)
├── ui/
│   ├── pages/       # Screens organized by feature (auth/, home/, quest/, etc.)
│   ├── theme/       # AppTheme, AppColors, AppStyles (Material 3)
│   └── widgets/     # Reusable widgets: minimalist/, magical/, fantasy/, common/
└── utils/           # SVG/Figma asset helpers
```

**Entry point**: `lib/main.dart` initializes Supabase (session chiffrée sur mobile), and Hive boxes (`quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`, `aiValidation`), then runs the app via `lib/app.dart` (`MaterialApp.router`). All Hive boxes are untyped (`Box`) and store models as JSON — no TypeAdapters, no `@HiveType`, no code generation.

**Navigation** (Sprint 2, ADR 0007) : go_router dans `lib/core/router/app_router.dart`. Chemins dans `Routes`
(jamais de chaîne en dur), dock = `StatefulShellRoute` (une pile par onglet : accueil, quêtes, portail, chat,
profil, cadre `AppShell`), redirections connexion / onboarding centralisées (`redirectionPour`, testée), lien
profond `sameva://app/quete/<id>`. Naviguer avec `context.push(Routes.x)` / `context.go(...)` ;
`Navigator.pushNamed` n'existe plus. `ProviderScope` (Riverpod) enveloppe l'app : nouvelles fonctionnalités en
Riverpod (`lib/core/providers.dart`), Provider conservé pour l'existant jusqu'à la fin du S3.

## Règle n°1 : le serveur est l'unique autorité (Sprint 1, ADR 0005)

Le client **lit** et envoie des **intentions** ; il n'écrit jamais une ressource de jeu.

- Toute mutation d'XP, or, cristaux, Sceaux, énergie Oracle, PV, moral, flamme, gacha passe par une RPC
  Postgres (`complete_quest`, `claim_daily`, `invoke`, `spend`, `claim_transitional_reward`,
  `oracle_challenge`, `set_challenge_hands_free`, `get_player_state`, `set_timezone`) via `lib/data/repositories/game_api.dart`.
- La validation photo passe par l'Edge Function `analyze-quest-proof` (`quest_id`, `challenge_id`,
  `image_base64`) : le verdict renvoyé est **déjà appliqué** en base.
- Défi de capture (ADR 0006) : un geste et un nombre manuscrit tirés par le serveur doivent être visibles ;
  MougiBot les décrit sans les connaître et le serveur compare (`oracle_resolve`).
- Chaque mouvement est inscrit dans `economy_ledger` (ajout seul). Réglages d'équilibrage : table
  `game_config` (jamais de constante de gameplay en dur dans le client).
- Le client n'a que SELECT sur `player_stats`, `ai_validation_credits`, `economy_ledger`,
  `gacha_state`, `quest_proofs`. Le statut et les récompenses d'une quête sont protégés par trigger.
- Ne jamais réintroduire de calcul de récompense côté client : `QuestRewardsCalculator` n'est plus
  autoritaire. Afficher ce que renvoie le serveur.
- Transitoire jusqu'au Sprint 3 : inventaire, équipement et objets concrets restent dans Hive (générés
  depuis la rareté renvoyée par le serveur) ; `spend` et `claim_transitional_reward` sont plafonnés.
- Tests : `supabase test db` (pgTAP, `supabase/tests/`), `deno test` dans
  `supabase/functions/analyze-quest-proof/`, `flutter test`. Toute règle nouvelle = un test pgTAP.
- Déploiement : `supabase db push` **avant** le workflow manuel « Deploy backend » (fonctions).
  Procédure complète : `docs/runbooks/sprint0-baseline-et-deploiement-s1.md`.

## Règle n°2 : rien n'est « terminé » sans le banc d'essai

Toute modification se valide avec `tools/banc/tout_tester.sh` (voir `tools/banc/README.md`) : analyse,
tests Flutter, pgTAP, Oracle, test de fumée API, puis l'app web réelle pilotée comme un joueur
(Playwright, captures dans `/tmp/sameva-banc/captures/`). Un nouveau parcours utilisateur = un nouveau
scénario dans `tools/banc/e2e/parcours.mjs`. Regarder les captures avant de conclure. Les constats
d'usage (bugs, UX, accessibilité) vont dans `docs/qa/constats.md`.

## State Management (Provider, Riverpod prévu au Sprint 2 : ADR 0007)

| ViewModel | Source | Rôle |
|----------|---------|---------|
| `AuthViewModel` | Supabase Auth | Connexion e-mail, Google, anonyme ; flux onSignedIn / onSignedOut |
| `QuestViewModel` | Supabase (`quests`) | CRUD du contenu des quêtes actives ; jamais le statut ni les récompenses |
| `PlayerViewModel` | `get_player_state` (Hive = cache) | Stats serveur ; méthodes qui appellent `GameApi` puis rafraîchissent |
| `AiValidationCreditsService` | `ai_validation_credits` (lecture) | Énergie de l'Oracle, premium |
| `InventoryViewModel` / `EquipmentViewModel` | Hive (transitoire S3) | Objets concrets |
| `ThemeViewModel` | Hive | Thème |

## Backend & Persistence

- **Supabase** : Auth, PostgreSQL (migrations `supabase/migrations/`, schéma `private` non exposé pour la
  logique interne), Edge Functions Deno. Config dans `lib/config/supabase_config.dart`.
- **Hive** : cache local et données transitoires (inventaire). Boîtes non typées, JSON.
- **Infra** : production sur Supabase managé ; NAS = staging, sauvegardes chiffrées, supervision
  (`infra/nas/`).

## Design System

- **Material 3** with custom light/dark themes defined in `ui/theme/`
- **Colors**: `AppColors` — turquoise primary (#4FD1C5), violet secondary (#805AD5), gold accent (#F6E05E), night blue dark bg (#0F172A)
- **Fonts**: MedievalSharp (fantasy headings), Press Start 2P (pixel game stats), Quicksand/Poppins (body)
- **Rarity colors**: Common (gray), Uncommon (green), Rare (blue), Epic (violet), Legendary (gold), Mythic (red)
- **Widget categories**: `minimalist/` (clean flat components), `magical/` (animated glow/particles), `fantasy/` (RPG-themed)
- **Pixel art (nov. 2026)** : personnages, animations et objets en pixel art rétro (références Stardew Valley et
  Celeste), **générés dans Figma** (fichier « Sameva · Pixel art », `JPJpwdPnsvXuE5n4D38SIP`, modèle d'image Figma) puis
  convertis en vrais sprites par `python3 tools/pixel/importer_figma.py <dossier des PNG exportés>` (découpe, grille
  fixe, palette commune, fond transparent) vers `assets/sprites/` (chats et MougiBot 96 px + `animations.json`,
  objets 32 px dans `objets/`). Sons chiptune synthétisés par `tools/pixel/sfx.py` vers `assets/sfx/`.
  Affichage : `PixelSprite` (agrandissement entier, sans lissage), `CatWidget` (6 races × 6 humeurs, chapeau),
  `MougiBotSprite` (repos, observe, accepte, refuse), `ItemIcon` (l'ancien chemin `assets/items/x.svg` d'un objet
  désigne `assets/sprites/objets/x.png`). Sons : `Sons.jouer(Son.x)` (`lib/core/audio/sons.dart`), coupables dans les
  réglages, muets sur le web et en test. Ne jamais retoucher les PNG à la main : régénérer depuis Figma.
- **Interface pixel (maquettes Claude Design « Sameva · Écrans pixel art »)** : `lib/ui/widgets/pixel/pixel_ui.dart`
  (`PixelCouleurs`, `PixelTextes` : polices embarquées PressStart2P et PixelifySans, `PixelCadre`, `PixelBouton`,
  `PixelAnneau`, `PixelBarreSeuil`, `PixelJauge`, `PixelChoix`, `pixelChamp`, `pixelBarre` (barre de titre),
  `PixelDialogue` (boîte de dialogue), `parPaliers` pour les animations image par image). Piège : une `ColoredBox` sans
  enfant dans une `Stack` ou une `Row` non étirée a une hauteur nulle (positionner ou étirer). Cadres épais, ombres franches sans flou, aucun
  coin arrondi. Invocation : `SequenceInvocation.afficher` (charge du portail dont la couleur annonce la rareté,
  « Passer », révélation d'un objet ou de dix cartes, meilleure en dernier ; respecte « réduire les animations »).

## Key Domain Rules (serveur)

- Récompense : `R = base(difficulté) × validation (Oracle 1,0 / déclaratif 0,5) × planification × flamme ×
  rendements décroissants du jour × Épuisé`, calculée dans `private.complete_quest` (voir `game_config`).
- Gacha : payé en Sceaux (jamais en monnaie achetable), pity serveur (épique tous les 20, légendaire au 80e).
- `ItemFactory` (client) ne fait plus que matérialiser un objet depuis une rareté décidée par le serveur.

## Language

The app UI, documentation, and commit messages are in **French**.
