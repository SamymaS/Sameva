# CLAUDE.md

Ce fichier donne les consignes de travail pour les agents sur le projet Sameva.

## Vue d'ensemble du projet

Sameva est une application Flutter de gestion de tâches gamifiée en RPG. Les utilisateurs terminent des quêtes pour gagner XP, or, cristaux et objets, avec inventaire, équipement, invocation/gacha, mini-jeux, validation IA et notifications.

## Commandes utiles

```bash
flutter pub get                    # Installer les dépendances
flutter run                        # Lancer l'app sur l'appareil détecté
flutter run -d chrome              # Lancer sur Chrome
flutter run -d windows             # Lancer sur Windows
flutter analyze                    # Analyse statique
flutter test                       # Tests
flutter test test/widget_test.dart # Test ciblé
dart run build_runner build        # Générer les adaptateurs Hive après modification @HiveType/@HiveField
flutter build apk                  # Build Android
flutter build web                  # Build Web
```

## Architecture

Architecture MVVM/Clean en couches strictes avec Provider/ChangeNotifier :

```
lib/
├── config/          # Configuration Supabase, constantes et .env
├── data/            # Modèles et repositories (Supabase + Hive)
├── domain/          # Services métier purs
├── presentation/    # ViewModels ChangeNotifier et use cases
├── ui/
│   ├── pages/       # Écrans par fonctionnalité
│   ├── theme/       # AppTheme, AppColors, AppStyles
│   └── widgets/     # common/, minimalist/, magical/, fantasy/
└── utils/           # Helpers SVG/Figma
```

- `lib/main.dart` initialise dotenv, Supabase, Hive, les repositories, les ViewModels globaux et `MultiProvider`.
- `lib/app.dart` contient la navigation principale avec Stack, dock flottant et pages de l'application.
- Les dépendances vont de l'UI vers la présentation, puis vers les services/domain et repositories injectés. L'UI n'accède jamais directement à Supabase ou aux boxes Hive.

## État applicatif

Provider reste le mécanisme d'injection et d'écoute. Ne pas introduire BLoC ni Riverpod.

ViewModels globaux enregistrés dans `main.dart` :

| ViewModel | Stockage / dépendances | Rôle |
|-----------|------------------------|------|
| `AuthViewModel` | `AuthRepository` / Supabase Auth | Connexion, inscription, session |
| `QuestViewModel` | `QuestRepository` / Supabase | CRUD et état partagé des quêtes |
| `PlayerViewModel` | `PlayerRepository` / Hive + Supabase | Niveau, XP, or, cristaux, HP, streak |
| `InventoryViewModel` | Hive `inventory` | Inventaire, stacks, objets |
| `EquipmentViewModel` | Hive `equipment` | Équipement et slots |
| `CatViewModel` | Hive `cats` | Chats compagnons |
| `ThemeViewModel` | Hive `settings` | Thème sombre/clair/système |
| `NotificationViewModel` | Hive `settings` | Préférences et rappels |

Règles :
- Appeler `notifyListeners()` après toute mutation d'état observable.
- Exposer les erreurs via un champ d'état (`error`, `errorMessage`, etc.) avec `try/catch`, sans crash silencieux.
- Utiliser `context.watch<T>()` pour l'affichage réactif et `context.read<T>()` pour les actions ponctuelles.

## Backend, local et configuration

- **Supabase** : Auth + PostgreSQL. Configuration dans `lib/config/supabase_config.dart`, clés dans `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- **Hive** : persistance locale. Boxes ouvertes dans `main.dart` : `quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`.
- Après toute modification d'un modèle `@HiveType` ou `@HiveField`, lancer `dart run build_runner build`.
- Les opérations DB passent par les repositories et ViewModels, jamais directement depuis l'UI.
- Pour une migration Supabase : commenter le SQL, respecter les policies RLS existantes, tester par `SELECT` avant tout `UPDATE`/`DELETE`, et mettre `ON DELETE CASCADE` sur les foreign keys vers `auth.users`.

## Design system

- Material 3 avec thèmes dans `lib/ui/theme/`.
- Utiliser `AppColors` depuis `lib/ui/theme/app_colors.dart` pour l'UI, sans couleurs hardcodées.
- Palette actuelle : violet cosmique (`primaryViolet` / `primary`), or (`gold` / `accent`), fond sombre (`backgroundNightCosmos` / `background`), bleu cristal, vert succès, rouge/rose erreur.
- Raretés : `rarityCommon`, `rarityUncommon`, `rarityRare`, `rarityEpic`, `rarityLegendary`, `rarityMythic`.
- Polices : MedievalSharp pour les titres fantasy, Press Start 2P pour les stats jeu, Quicksand/Poppins pour le corps.
- Widgets : `minimalist/`, `magical/`, `fantasy/`, `common/`. Réutiliser les widgets existants avant d'en créer de nouveaux.

## Services métier à respecter

- `QuestRewardsCalculator` : XP = 10 × difficulté, or = 25 × difficulté, cristaux si difficulté > 3.
- Bonus timing : en avance (temps réel <= 80 % estimé) ×1.25, à temps ×1.10, en retard ×0.80.
- Streak >= 7 jours : +0.10 au multiplicateur.
- Level-up joueur : seuil XP `(100 × level × 1.5).round()`, HP max `100 + (level - 1) × 10`.
- `ItemFactory.rollGachaRarity` : Mythic 0,1 %, Legendary 0,9 %, Epic 4 %, Rare 10 %, Uncommon 25 %, Common 60 %.
- Services IA : Claude via appels `http` directs, avec clés dans `.env` ou configuration dédiée.
- Notifications : `flutter_local_notifications` + `timezone`.

## Règles de développement

1. Lire le fichier complet avant de le modifier.
2. Choisir la solution la plus simple qui respecte l'architecture.
3. Ne modifier que les fichiers nécessaires à la demande.
4. Ne pas ajouter de commentaires sauf si la logique n'est pas évidente.
5. Garder l'UI, la documentation, les commentaires utiles, variables métier et commits en français.
6. Préférer `withValues(alpha: x)` à `withOpacity()`.
7. Après chaque `await` suivi d'un usage de `context`, vérifier `context.mounted`.
8. Ne jamais hardcoder les clés API ; utiliser `.env` et `config/`.
9. Corriger les warnings introduits par la modification.
10. Commits en français au format `feat:`, `fix:`, `refactor:`, `style:` ou `chore:`.

## Assets visuels

Pour les icônes, illustrations, bannières et splash screens :
- Générer via Python + Pillow ou cairosvg si nécessaire.
- Style : fantasy RPG dark, effets lumineux, particules.
- Couleurs : violet/pourpre profond, or/ambre, fond noir/gris très sombre, accents rouge HP, bleu magie, vert succès.
- Placer les PNG dans `assets/images/` et les SVG dans `assets/icons/` selon le type.
- Ajouter la référence dans `pubspec.yaml` si elle n'existe pas déjà.
