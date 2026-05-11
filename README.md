# Sameva

[![CI](https://github.com/SamymaS/Sameva/actions/workflows/ci.yml/badge.svg)](https://github.com/SamymaS/Sameva/actions/workflows/ci.yml)

> Application mobile de gestion d'habitudes gamifiée — les quêtes du quotidien deviennent des aventures RPG.

**Sameva** pousse l'utilisateur à réaliser des **actions réelles** en rendant la validation des tâches **crédible, vérifiable et gratifiante**. L'utilisateur crée des quêtes, soumet une preuve photo, et une IA analyse l'image pour produire un score sur 100. Au-dessus de 70, la récompense est complète (XP, gold, items). En dessous, une validation manuelle reste toujours disponible à demi-récompense — **l'app ne bloque jamais l'utilisateur**.

Tout le reste — avatar, loot, compagnons, animations, gacha — existe pour servir cette boucle.

---

## Démarrage rapide

```bash
git clone https://github.com/SamymaS/Sameva.git
cd Sameva
cp .env.example .env          # Renseigner SUPABASE_URL et SUPABASE_ANON_KEY
flutter pub get
flutter run
```

> **Prérequis** : Flutter ≥ 3.29 · Dart ≥ 3.7 · Un projet [Supabase](https://supabase.com) configuré (voir ci-dessous)

---

## Stack technique

| Couche | Technologie | Rôle |
|--------|-------------|------|
| Client | Flutter (Material Design 3) | Application cross-platform iOS / Android |
| Architecture | MVVM — Provider / ChangeNotifier | Séparation UI / logique / données |
| Backend | Supabase (PostgreSQL + Auth JWT + RLS) | Base de données, authentification, sécurité |
| Cache local | Hive | Persistence offline-first (quêtes, stats, inventaire) |
| IA (prévu) | Edge Function Supabase → OpenAI Vision | Validation de preuves visuelles |
| CI/CD | GitHub Actions | Analyse statique, tests, couverture |

---

## Architecture

```
lib/
├── main.dart                       # Initialisation — Supabase, Hive, dotenv, MultiProvider
├── app.dart                        # Navigation — PageView + DockBar flottante (8 pages)
│
├── config/
│   └── supabase_config.dart        # Lecture .env — URLs, clés
│
├── data/
│   ├── models/                     # Quest, PlayerStats, Item, Cat, Character (Hive + Supabase)
│   └── repositories/               # AuthRepository, QuestRepository, PlayerRepository, UserRepository
│
├── domain/
│   └── services/                   # QuestRewardsCalculator, ValidationAIService (interface),
│                                   # ItemFactory, HealthRegenerationService, CatMoodService,
│                                   # NotificationService
│
├── presentation/
│   ├── view_models/                # Un ViewModel par fonctionnalité (ChangeNotifier)
│   └── use_cases/                  # CompleteQuestUseCase
│
└── ui/
    ├── pages/                      # auth, home, quest, profile, inventory, market,
    │                               # invocation, cat, minigames, rewards, settings, onboarding
    ├── theme/                      # AppTheme, AppColors
    └── widgets/                    # common, cat, character
```

L'architecture suit un découpage en 4 couches avec une règle de dépendance stricte : `UI → Presentation → Domain → Data`. Les services métier sont abstraits (ex. `ValidationAIService` → `MockValidationAIService` en dev, `ApiValidationAIService` en prod) pour permettre le swap d'implémentation sans toucher au reste du code.

→ Détails complets : [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md)

---

## Fonctionnalités

### Boucle principale
- **Quêtes** : création, filtrage, tri, validation par preuve photo (IA) ou manuelle, génération par thème
- **Récompenses** : XP, gold, cristaux — calculées selon la difficulté, la ponctualité, et le streak
- **Progression RPG** : niveaux, seuils d'XP progressifs, HP avec régénération passive

### Systèmes secondaires
- **Inventaire** : 50 emplacements, items stackables, système d'équipement par slots
- **Gacha (Invocation)** : système de tirage avec raretés (Common → Mythic) et pity system
- **Marché** : boutique cosmétiques, vente d'items, filtres par catégorie
- **Compagnons** : chats avec mécanique d'humeur liée à l'activité du joueur
- **Mini-jeux** : anagramme, mémoire, séquence, réaction, chiffres
- **Leaderboard** : classement entre joueurs

### Infrastructure
- **Auth** : email/password avec confirmation par mail (Supabase Auth)
- **Offline-first** : Hive en cache local, synchronisation vers Supabase
- **Notifications** : rappels quotidiens configurables (heure via Settings)
- **Thème** : dark / light / système — persisté en local

---

## Pages

| Page | Description |
|------|-------------|
| **Sanctuary** | Tableau de bord — stats joueur, compagnon, quêtes du jour |
| **Quêtes** | Liste, création, validation (photo + IA), génération par thème |
| **Inventaire** | 50 emplacements, items stackables, équipement |
| **Avatar** | Personnage équipé, slots d'équipement |
| **Marché** | Boutique cosmétiques, vente d'items |
| **Invocation** | Gacha d'items avec pity system |
| **Mini-jeux** | 5 mini-jeux (anagramme, mémoire, séquence, réaction, chiffres) |
| **Profil** | Stats, historique, achievements, déconnexion |

---

## Backend — Supabase

**Plan** : Free tier (500 MB DB, 1 GB storage, 50K MAU, 500K Edge Function invocations/mois)

### Tables

| Table | Rôle |
|-------|------|
| `users` | Profil joueur — level, XP, gold, HP, streak, achievements (extension de `auth.users`) |
| `quests` | Quêtes créées par les joueurs — titre, difficulté, statut, deadline, preuve |
| `items` | Catalogue d'items disponibles dans le jeu |
| `user_inventory` | Inventaire des joueurs (items possédés, quantité) |
| `user_equipment` | Équipement actuellement porté |
| `companions` | Compagnons possédés par les joueurs |
| `transactions` | Historique des transactions (achats, ventes, récompenses) |

**Sécurité** : Row Level Security (RLS) activé sur toutes les tables — chaque utilisateur ne voit et ne modifie que ses propres données. JWT vérifié sur chaque requête.

→ Setup complet : [documentation/SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md)
→ Schéma SQL : [documentation/supabase_schema.sql](documentation/supabase_schema.sql)

### Edge Function (prévue)

`analyze-quest-proof` : reçoit une image en base64 + contexte de la quête, appelle OpenAI Vision, renvoie un score 0–100 avec explication. La clé API reste côté serveur (secrets Supabase). En développement, le `MockValidationAIService` simule ce comportement.

→ Guide d'intégration : [documentation/IA_ANALYSE_IMAGE.md](documentation/IA_ANALYSE_IMAGE.md)
→ Setup Edge Function : [documentation/SUPABASE_EDGE_FUNCTION_IA.md](documentation/SUPABASE_EDGE_FUNCTION_IA.md)

---

## Tests

**208 tests** répartis sur 32 fichiers couvrant les 3 couches :

- **Domain** : QuestRewardsCalculator (scénarios de récompenses, bonus ponctualité, streak, pénalités), ItemFactory (raretés, gacha, marché), HealthRegenerationService (limites, plafonds, timestamps), ValidationAIService (parsing, erreurs HTTP, fallbacks)
- **Data** : sérialisation aller-retour des modèles (toSupabaseMap ↔ fromSupabaseMap), parsing d'enums avec fallback, CRUD repositories via mocks
- **Presentation** : un fichier de test par ViewModel — AuthViewModel, QuestsListViewModel, PlayerViewModel, QuestValidationViewModel

```bash
flutter test                       # Lancer tous les tests
flutter test --coverage            # Avec rapport de couverture
```

---

## CI/CD

Le pipeline GitHub Actions (`.github/workflows/ci.yml`) s'exécute sur chaque push vers `main`/`develop` et sur les pull requests :

1. **Checkout** + setup Flutter (stable, avec cache)
2. **Injection `.env`** via GitHub Secrets (les clés ne sont jamais dans le code)
3. **`flutter pub get`** — installation des dépendances
4. **`flutter analyze`** — analyse statique Dart
5. **`flutter test --coverage`** — exécution des tests avec rapport de couverture
6. **Résumé lcov** — affichage du taux de couverture

### Secrets requis

| Secret | Valeur | Où la trouver |
|--------|--------|---------------|
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` | Dashboard Supabase → Settings → API |
| `SUPABASE_ANON_KEY` | `eyJ...` (clé anon publique) | Dashboard Supabase → Settings → API |

---

## Commandes utiles

```bash
flutter pub get                    # Installer les dépendances
flutter run                        # Lancer l'app (device par défaut)
flutter run -d chrome              # Lancer sur Chrome
flutter analyze                    # Analyse statique
flutter test                       # Tests unitaires et widget
flutter test --coverage            # Tests avec couverture
dart run build_runner build        # Générer les adaptateurs Hive (@HiveType)
flutter build apk                  # Build Android (APK)
flutter build web                  # Build Web
```

---

## Documentation

| Document | Contenu |
|----------|---------|
| [ARCHITECTURE.md](documentation/ARCHITECTURE.md) | Architecture MVVM — 4 couches, conventions, règle de dépendance |
| [SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md) | Configuration Supabase, schéma, clés API, RLS |
| [supabase_schema.sql](documentation/supabase_schema.sql) | Schéma SQL complet (7 tables, enums, triggers, RLS policies) |
| [IA_ANALYSE_IMAGE.md](documentation/IA_ANALYSE_IMAGE.md) | Flux de validation par IA — architecture, format d'échange, intégration Flutter |
| [SUPABASE_EDGE_FUNCTION_IA.md](documentation/SUPABASE_EDGE_FUNCTION_IA.md) | Déploiement de l'Edge Function analyze-quest-proof |
| [ROADMAP_FEATURES.md](documentation/ROADMAP_FEATURES.md) | Roadmap des fonctionnalités — MVP et post-MVP |

---

## Métriques du projet

| Métrique | Valeur |
|----------|--------|
| Lignes de code (Dart) | ~24 000+ |
| Fichiers source | 85+ |
| Tests | 208 (32 fichiers) |
| Commits | 131+ |
| Tables Supabase | 7 |
| Pages applicatives | 8 |

---

## Licence

Projet privé — © 2025-2026 Samy. Tous droits réservés.

Développé dans le cadre de la certification **RNCP 39583 — Expert en Développement Logiciel** (Niveau 7), YNOV Campus, promotion 2025–2026.
