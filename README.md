# Sameva

**Sameva** pousse l'utilisateur à réaliser des **actions réelles** en rendant la validation des tâches **crédible, vérifiable et gratifiante**.

Tout le reste (avatar, loot, animations, IA, etc.) existe uniquement pour servir cette fonction.

---

## Lancer le projet

```bash
git clone <repo>
cd Sameva
cp .env.example .env   # renseigner SUPABASE_URL et SUPABASE_ANON_KEY
flutter pub get
flutter run
```

- **Backend** : Supabase (auth + PostgreSQL). Voir [documentation/SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md).
- **Données locales** : Hive (playerStats, inventory, equipment, settings, cats).

---

## Structure du code

```
lib/
├── main.dart                   # Point d'entrée — Supabase, Hive, MultiProvider
├── app.dart                    # SamevaApp — navigation Stack + dock flottant (8 pages)
├── config/
│   └── supabase_config.dart
├── data/
│   ├── models/                 # quest_model, player_stats_model, item_model, cat_model, character_model
│   └── repositories/           # auth, quest, player, user
├── domain/
│   └── services/               # quest_rewards_calculator, validation_ai_service, item_factory,
│                               # health_regeneration_service, cat_mood_service, notification_service
├── presentation/
│   ├── view_models/            # un ViewModel par fonctionnalité (ChangeNotifier)
│   └── use_cases/              # complete_quest_use_case
└── ui/
    ├── pages/                  # auth, home, quest, profile, inventory, market,
    │                           # invocation, cat, minigames, rewards, settings, onboarding
    ├── theme/                  # app_theme, app_colors
    └── widgets/                # common, cat, character
```

→ Voir [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md) pour le détail des couches.

---

## Pages principales

| Page | Description |
|------|-------------|
| Sanctuary | Tableau de bord — stats joueur, chat compagnon, quêtes du jour |
| Quêtes | Liste, création, validation (photo + IA), génération par thème |
| Inventaire | 50 emplacements, items stackables, équipement |
| Avatar | Personnage équipé, slots d'équipement |
| Marché | Boutique cosmétiques, vente d'items |
| Invocation | Gacha d'items avec système pity |
| Mini-jeux | Anagramme, mémoire, séquence, réaction, chiffres |
| Profil | Stats, historique, déconnexion |

---

## Commandes utiles

```bash
flutter pub get                    # Installer les dépendances
flutter run                        # Lancer l'app
flutter run -d chrome              # Lancer sur Chrome
flutter analyze                    # Analyse statique
flutter test                       # Tests
dart run build_runner build        # Générer les adaptateurs Hive (@HiveType)
flutter build apk                  # Build Android
flutter build web                  # Build web
```

---

## Documentation

| Fichier | Contenu |
|---------|---------|
| [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md) | Architecture MVVM — 3 couches, conventions |
| [documentation/SUPABASE_SETUP.md](documentation/SUPABASE_SETUP.md) | Configuration Supabase, schéma, clés API |
| [documentation/supabase_schema.sql](documentation/supabase_schema.sql) | Schéma SQL Supabase |
| [documentation/ROADMAP_FEATURES.md](documentation/ROADMAP_FEATURES.md) | Roadmap des fonctionnalités |
| [documentation/IA_ANALYSE_IMAGE.md](documentation/IA_ANALYSE_IMAGE.md) | Validation par analyse d'image IA |
