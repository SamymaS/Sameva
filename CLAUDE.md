# CLAUDE.md

Ce fichier guide les agents de code qui travaillent sur le projet Sameva.

## Vue d'ensemble du projet

Sameva est une application Flutter de gestion de tâches gamifiée, inspirée des RPG. Les utilisateurs accomplissent des quêtes pour gagner de l'XP, de l'or, des cristaux et des items. Le projet suit une Clean Architecture avec Provider / ChangeNotifier pour l'état partagé.

## Commandes utiles

```bash
flutter pub get                    # Installer les dépendances
flutter run                        # Lancer l'app avec détection automatique
flutter run -d chrome              # Lancer sur Chrome
flutter run -d windows             # Lancer sur Windows
flutter analyze                    # Analyse statique
flutter test                       # Lancer les tests
flutter test test/widget_test.dart # Lancer un test précis
dart run build_runner build        # Régénérer les adapters Hive après modification @HiveType/@HiveField
flutter build apk                  # Build Android release
flutter build web                  # Build Web release
```

## Architecture

Clean Architecture en 4 couches :

```
lib/
├── config/          # Configuration Supabase et constantes
├── data/            # Models, repositories, datasources (Supabase + Hive)
├── domain/          # Entités, services métier, repositories abstraits
├── presentation/    # ViewModels ChangeNotifier et use cases
├── ui/
│   ├── pages/       # Écrans par fonctionnalité
│   ├── theme/       # AppTheme, AppColors, AppStyles
│   └── widgets/     # Widgets réutilisables
└── utils/           # Helpers divers
```

Point d'entrée : `lib/main.dart` initialise dotenv, Supabase, Hive (`quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`), `NotificationService`, puis expose les repositories et ViewModels avec `MultiProvider`.

## État et accès aux données

- Utiliser Provider / ChangeNotifier uniquement ; ne pas introduire BLoC ou Riverpod.
- Les ChangeNotifier actuels sont dans `lib/presentation/view_models/`.
- L'UI utilise `context.watch<T>()` pour la réactivité et `context.read<T>()` pour les actions ponctuelles.
- Les opérations Supabase et Hive passent par les repositories, use cases ou ViewModels, jamais directement depuis les pages.
- Après toute mutation d'état dans un ChangeNotifier, appeler `notifyListeners()`.
- Les erreurs sont capturées avec `try/catch`, exposées via un état `_error` ou équivalent, puis affichées proprement par l'UI.

## Persistance et backend

- Supabase : Auth + PostgreSQL. La configuration est dans `lib/config/supabase_config.dart` et les secrets dans `.env`.
- Hive : persistance locale. Les boîtes principales sont ouvertes dans `main.dart`.
- IA : appels Claude via `http` direct, avec clés/API dans `.env` ou configuration dédiée.
- Notifications : `flutter_local_notifications` + `timezone`, initialisés via `NotificationService`.
- Pour les migrations Supabase, respecter les RLS existantes ; les foreign keys vers `auth.users` utilisent `ON DELETE CASCADE`.

## Règles de développement

1. Lire le fichier complet avant de le modifier.
2. Choisir la solution la plus simple qui respecte l'architecture existante.
3. Ne modifier que les fichiers nécessaires à la demande.
4. Ne pas faire de refactoring non demandé.
5. Écrire l'UI, les commentaires utiles, la documentation et les commits en français.
6. Ne commenter que la logique non évidente.
7. Utiliser `withValues(alpha: x)` plutôt que `withOpacity()`.
8. Après chaque `await` suivi d'une utilisation de `context`, vérifier `context.mounted`.
9. Ne jamais hardcoder les clés API ; utiliser `.env` et `config/`.
10. Après modification `@HiveType` / `@HiveField`, exécuter `dart run build_runner build`.
11. Corriger les warnings pertinents de `flutter analyze` pour les fichiers touchés.
12. Commits en français au format `feat:`, `fix:`, `refactor:`, `style:` ou `chore:`.

## Design system

- Material 3 avec thèmes light/dark dans `lib/ui/theme/`.
- Couleurs : utiliser `AppColors` depuis `lib/ui/theme/app_colors.dart`.
- Direction artistique actuelle : cosmos/fantasy sombre, violet profond, or, bleu cristal, vert succès, rouge/rose erreur.
- Polices : MedievalSharp pour les titres fantasy, Press Start 2P pour les stats, Quicksand/Poppins pour le corps.
- Widgets : réutiliser `minimalist/`, `magical/`, `fantasy/` et `common/` avant de créer un nouveau composant.
- Assets visuels : PNG pour images, SVG pour icônes ; les placer dans `assets/images/` ou `assets/icons/` selon le type et référencer `pubspec.yaml` si nécessaire.

## Logique métier de référence

- Récompenses de base : XP = `10 × difficulty`, Or = `25 × difficulty`, cristaux si difficulté > 3.
- Ponctualité : terminé en avance (< 80 % du temps estimé) = ×1.25 ; à temps = ×1.10 ; en retard = ×0.80.
- Streak : +0.10 au multiplicateur si streak >= 7 jours.
- Level-up : seuil XP `(100 × level × 1.5).round()`, HP max `100 + (level - 1) × 10`.
- Gacha : Mythic 0,1 %, Legendary 0,9 %, Epic 4 %, Rare 10 %, Uncommon 25 %, Common 60 %.

## Réponse et collaboration

- Expliquer brièvement pourquoi une modification est faite.
- Montrer uniquement les sections modifiées ou le diff, pas des fichiers entiers.
- En cas de doute bloquant sur l'intention, demander une clarification.
