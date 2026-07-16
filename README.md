# Sameva

[![CI](https://github.com/SamymaS/Sameva/actions/workflows/ci.yml/badge.svg)](https://github.com/SamymaS/Sameva/actions/workflows/ci.yml)

> Application mobile de gestion d'habitudes gamifiée. Les quêtes du quotidien deviennent des aventures RPG.

**Sameva** pousse l'utilisateur à réaliser des **actions réelles** en rendant la validation des tâches crédible, vérifiable et gratifiante. L'utilisateur crée des quêtes, soumet une preuve photo, et un validateur IA (MougiBot, propulsé par Claude Haiku Vision) analyse l'image pour produire un score sur 100. Au-dessus de 70, la récompense est complète (XP, gold, items). En dessous, une validation manuelle reste toujours disponible à demi-récompense : **l'application ne bloque jamais l'utilisateur**.

Tout le reste (avatar, loot, compagnons, animations, gacha) existe pour servir cette boucle.

---

## Démarrage rapide

```bash
git clone https://github.com/SamymaS/Sameva.git
cd Sameva
cp .env.example .env          # Renseigner SUPABASE_URL et SUPABASE_ANON_KEY
flutter pub get
flutter run
```

> **Prérequis** : Flutter (canal stable, testé sur 3.41 / Dart 3.11) · Dart >= 3.3 · un projet [Supabase](https://supabase.com) configuré (voir plus bas).

Tu veux juste essayer l'application sans rien installer ? Un APK prêt à l'emploi est disponible dans la section [Releases](https://github.com/SamymaS/Sameva/releases).

---

## Stack technique

| Couche       | Technologie                                     | Rôle                                                  |
| ------------ | ----------------------------------------------- | ----------------------------------------------------- |
| Client       | Flutter (Material Design 3)                     | Application cross-platform iOS / Android              |
| Architecture | MVVM, Provider / ChangeNotifier                 | Séparation UI / logique / données                     |
| Backend      | Supabase (PostgreSQL + Auth JWT + RLS)          | Base de données, authentification, sécurité           |
| Cache local  | Hive                                            | Persistance offline-first (stats, inventaire, compagnons, jetons) |
| IA           | Edge Function Supabase → Anthropic Claude Haiku | Validation de preuves visuelles et génération de quêtes |
| Paiement     | Stripe (mode abonnement)                        | Offre premium et gestion de l'entitlement             |
| CI/CD        | GitHub Actions                                  | Analyse statique, tests, couverture                   |

---

## Architecture

```
lib/
├── main.dart                       # Initialisation : Supabase, Hive, dotenv, MultiProvider
├── app.dart                        # Navigation : PageView + DockBar flottante
│
├── config/
│   └── supabase_config.dart        # Lecture .env : URLs, clés
│
├── data/
│   ├── models/                     # Quest, PlayerStats, Item, Cat, Character, CraftRecipe, LeaderboardEntry
│   └── repositories/               # Auth, Quest, Player, User, ...
│
├── domain/
│   └── services/                   # QuestRewardsCalculator, ValidationAIService (interface),
│                                   # ClaudeValidationAIService, ClaudeQuestGeneratorService,
│                                   # ItemFactory, CraftService, WeeklyBossService,
│                                   # AchievementService, HealthRegenerationService,
│                                   # CatMoodService, NotificationService
│
├── presentation/
│   ├── view_models/                # Un ViewModel par fonctionnalité (ChangeNotifier)
│   └── use_cases/                  # CompleteQuestUseCase
│
└── ui/
    ├── pages/                      # auth, onboarding, home, quest, inventory, market, invocation,
    │                               # cat, minigames, rewards, profile, settings, avatar, social
    ├── theme/                      # AppTheme, AppColors
    └── widgets/                    # common, cat, character
```

L'architecture suit un découpage en 4 couches avec une règle de dépendance stricte : `UI → Presentation → Domain → Data`. Les services métier sont abstraits (par exemple `ValidationAIService`, avec `MockValidationAIService` en développement et `ClaudeValidationAIService` en production) pour permettre le remplacement d'implémentation sans toucher au reste du code. Le cycle de vie d'authentification est uniformisé pour tous les ViewModels et services, décision consignée dans un enregistrement de décision d'architecture (voir `docs/adr/0001`).

→ Détails complets : [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md)

---

## Fonctionnalités

### Boucle principale

- **Quêtes** : création, filtrage, tri, validation par preuve photo (IA) ou manuelle, génération assistée par IA.
- **Récompenses** : XP, gold, cristaux, calculés selon la difficulté, la ponctualité et le streak.
- **Progression RPG** : niveaux, seuils d'XP progressifs, HP avec régénération passive.

### Systèmes secondaires

- **Inventaire** : 50 emplacements, items stackables, système d'équipement par slots.
- **Craft** : recettes de fabrication d'items.
- **Gacha (Invocation)** : tirage avec raretés (Common à Mythic) et pity system.
- **Marché** : boutique cosmétique, vente d'items, filtres par catégorie.
- **Compagnons** : chats avec mécanique d'humeur liée à l'activité du joueur.
- **Boss hebdomadaire** : objectif collectif ou individuel renouvelé chaque semaine.
- **Achievements** : succès débloquables suivant la progression.
- **Mini-jeux** : anagramme, mémoire, séquence, réaction, chiffres.
- **Leaderboard** : classement entre joueurs.

### Monétisation (freemium)

- **Jetons de validation IA** : chaque analyse de preuve consomme un crédit, suivi par utilisateur.
- **Premium** : abonnement Stripe qui lève les limites, avec rafraîchissement de l'entitlement fiabilisé et garde anti-rachat.

### Conformité et infrastructure

- **Auth** : email / mot de passe avec confirmation par mail (Supabase Auth).
- **Suppression de compte RGPD** : Edge Function dédiée, garde JWT, suppression respectant les clés étrangères, purge locale déclenchée seulement après confirmation serveur.
- **Offline-first** : les stats joueur, l'inventaire, les compagnons et le portefeuille de jetons sont lus depuis Hive et synchronisés vers Supabase en arrière-plan. Les quêtes sont, elles, servies directement par Supabase.
- **Notifications** : rappels quotidiens configurables.
- **Thème** : clair / sombre / système, persisté en local.

---

## Backend, Supabase

**Plan** : Free tier (500 MB DB, 1 GB storage, Edge Functions incluses).

### Tables

| Table                  | Rôle                                                                      |
| ---------------------- | ------------------------------------------------------------------------- |
| `users`                | Profil joueur (level, XP, gold, HP, streak, achievements)                 |
| `quests`               | Quêtes créées par les joueurs (titre, difficulté, statut, deadline, preuve) |
| `items`                | Catalogue d'items disponibles dans le jeu                                 |
| `user_inventory`       | Inventaire des joueurs (items possédés, quantité)                         |
| `user_equipment`       | Équipement actuellement porté                                             |
| `companions`           | Compagnons possédés par les joueurs                                       |
| `transactions`         | Historique des transactions (achats, ventes, récompenses)                 |
| `player_stats`         | Stats joueur synchronisées entre appareils (niveau, XP, or, HP, streak)   |
| `ai_validation_credits`| Crédits de validation IA par utilisateur (freemium)                       |
| `premium_subscriptions`| État de l'abonnement premium par utilisateur (Stripe)                     |
| `quest_difficulty_audit`| Journal d'audit de la correction de difficulté historique                |

Une vue, `leaderboard_view`, expose une projection publique restreinte pour le classement.

**Sécurité** : Row Level Security activé sur toutes les tables, chaque utilisateur ne voit et ne modifie que ses propres données, JWT vérifié sur chaque requête. La vue de classement est isolée derrière une projection publique restreinte.

→ Setup complet : [documentation/SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md)
→ Schéma SQL : [documentation/supabase_schema.sql](documentation/supabase_schema.sql)

### Edge Functions

Cinq fonctions serverless (Deno / TypeScript), les clés sensibles restant côté serveur via les secrets Supabase :

| Fonction                  | Rôle                                                                                   |
| ------------------------- | -------------------------------------------------------------------------------------- |
| `analyze-quest-proof`     | Valide une preuve photo via Claude Haiku Vision, renvoie un score 0 à 100 (seuil 70).  |
| `suggest-quests`          | Génère des suggestions de quêtes via Claude.                                           |
| `create-checkout-session` | Ouvre une session Stripe Checkout pour l'abonnement premium.                           |
| `stripe-webhook`          | Traite les événements Stripe et met à jour l'entitlement premium.                      |
| `delete-account`          | Supprime le compte de façon conforme au RGPD (garde JWT, ordre FK-safe, purge).        |

→ Guide d'intégration IA : [documentation/IA_ANALYSE_IMAGE.md](documentation/IA_ANALYSE_IMAGE.md)
→ Déploiement de l'Edge Function : [documentation/SUPABASE_EDGE_FUNCTION_IA.md](documentation/SUPABASE_EDGE_FUNCTION_IA.md)

---

## Tests

**469 cas de test** répartis sur **64 fichiers** et 147 groupes, couvrant les quatre couches :

- **Domain** : QuestRewardsCalculator (récompenses, bonus de ponctualité, streak, pénalités), ItemFactory (raretés, gacha, marché), CraftService, WeeklyBossService, HealthRegenerationService (limites, plafonds, horodatages), ValidationAIService (parsing, erreurs HTTP, fallback).
- **Data** : sérialisation aller-retour des modèles (`toSupabaseMap` et `fromSupabaseMap`), parsing d'enums avec fallback, CRUD des repositories via mocks.
- **Presentation** : un fichier de test par ViewModel (Auth, QuestsList, Player, QuestValidation, Inventory, Leaderboard, ...).

```bash
flutter test                       # Lancer tous les tests
flutter test --coverage            # Avec rapport de couverture
```

---

## CI/CD

Le pipeline GitHub Actions (`.github/workflows/ci.yml`) s'exécute sur chaque push vers `main` / `develop` et sur les pull requests :

1. **Checkout** et setup Flutter (canal stable, avec cache).
2. **Injection `.env`** via GitHub Secrets (les clés ne sont jamais dans le code).
3. **`flutter pub get`** : installation des dépendances.
4. **`flutter analyze`** : analyse statique Dart (0 issue exigée).
5. **`flutter test --coverage`** : exécution des tests avec rapport de couverture.
6. **Résumé lcov** : affichage du taux de couverture.

### Secrets

| Portée            | Secret              | Où la trouver                          |
| ----------------- | ------------------- | -------------------------------------- |
| CI (GitHub)       | `SUPABASE_URL`      | Dashboard Supabase, Settings, API      |
| CI (GitHub)       | `SUPABASE_ANON_KEY` | Dashboard Supabase, Settings, API      |
| Serveur (Supabase)| `ANTHROPIC_API_KEY` | Console Anthropic                      |
| Serveur (Supabase)| Clés Stripe         | Dashboard Stripe                       |

Les clés serveur (Anthropic, Stripe) ne sont jamais embarquées dans l'application : elles vivent dans les secrets Supabase et ne sont utilisées que par les Edge Functions.

---

## Commandes utiles

```bash
flutter pub get                    # Installer les dépendances
flutter run                        # Lancer l'app (device par défaut)
flutter run -d chrome              # Lancer sur Chrome
flutter analyze                    # Analyse statique
flutter test                       # Tests unitaires et widget
flutter test --coverage            # Tests avec couverture
flutter build apk --release        # Build Android (APK de production)
flutter build web                  # Build Web
```

---

## Documentation

| Document                                                                 | Contenu                                                                    |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| [ARCHITECTURE.md](documentation/ARCHITECTURE.md)                         | Architecture MVVM, 4 couches, conventions, règle de dépendance             |
| [SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md)                     | Configuration Supabase, schéma, clés API, RLS                              |
| [supabase_schema.sql](documentation/supabase_schema.sql)                 | Schéma SQL complet (tables, enums, triggers, RLS)                          |
| [IA_ANALYSE_IMAGE.md](documentation/IA_ANALYSE_IMAGE.md)                 | Flux de validation par IA (Claude Haiku), format d'échange, intégration    |
| [SUPABASE_EDGE_FUNCTION_IA.md](documentation/SUPABASE_EDGE_FUNCTION_IA.md)| Déploiement de l'Edge Function `analyze-quest-proof`                       |
| [docs/adr/](docs/adr/)                                                    | Enregistrements de décisions d'architecture (ADR)                          |

---

## Métriques du projet

| Métrique                    | Valeur   |
| --------------------------- | -------- |
| Lignes de code Dart (lib)   | ~28 500  |
| Fichiers source (lib)       | 99       |
| Cas de test                 | 469 (64 fichiers) |
| Edge Functions              | 5        |
| Tables Supabase             | 11 (+ 1 vue) |
| Analyse statique            | 0 erreur |

---

## Licence

Projet privé. © 2025-2026 Samy BOUDAOUD. Tous droits réservés.

Développé dans le cadre de la certification **RNCP 39583, Expert en Développement Logiciel** (Niveau 7), YNOV Campus, promotion 2025-2026. Un dossier technique accompagne ce dépôt et documente la conception, la sécurisation, les tests et l'exploitation de l'application.
