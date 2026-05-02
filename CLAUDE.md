# CLAUDE.md

Ce fichier donne les lignes directrices à suivre pour travailler sur Sameva.

## Vue d'ensemble du projet

Sameva est une application Flutter de gestion de tâches gamifiée, inspirée des RPG. Les utilisateurs terminent des quêtes pour gagner de l'XP, de l'or, des cristaux et des objets. Le projet suit une Clean Architecture en 4 couches avec Provider / ChangeNotifier pour la gestion d'état.

## Commandes utiles

```bash
flutter pub get                    # Installer les dépendances
flutter run                        # Lancer l'app sur l'appareil détecté
flutter run -d chrome              # Lancer sur Chrome
flutter run -d windows             # Lancer sur Windows
flutter analyze                    # Analyse statique (flutter_lints)
flutter test                       # Tests
flutter test test/widget_test.dart # Test ciblé
dart run build_runner build        # Générer les adapters Hive après modification @HiveType
flutter build apk                  # Build Android release
flutter build web                  # Build Web release
```

## Architecture

Clean Architecture avec 4 couches :

```
lib/
├── config/          # Configuration Supabase, constantes, .env
├── data/            # Modèles, repositories implémentés, datasources Supabase/Hive
├── domain/          # Entités, repositories abstraits, services métier
├── presentation/    # Providers ChangeNotifier
├── ui/
│   ├── pages/       # Écrans par feature (auth/, home/, quest/, etc.)
│   ├── theme/       # AppTheme, AppColors, AppStyles
│   └── widgets/     # Widgets common/, minimalist/, magical/, fantasy/
└── utils/           # Helpers SVG/Figma
```

**Point d'entrée** : `lib/main.dart` initialise dotenv, Supabase et les boxes Hive (`quests`, `playerStats`, `inventory`, `equipment`, `settings`), puis lance l'app via `lib/app_new.dart`.

**Navigation** : `app_new.dart` utilise une Stack avec AnimatedSwitcher et une barre dock flottante. Pages principales : Sanctuaire, Quêtes, Inventaire, Avatar, Marché, Invocation, Minijeux, Profil. Le FAB flottant ouvre la création de quête.

## Gestion d'état

Les providers sont enregistrés via `MultiProvider` dans `main.dart` :

| Provider | Stockage | Rôle |
|----------|----------|------|
| `AuthProvider` | Supabase Auth | Connexion email/mot de passe, anonyme, écoute auth |
| `QuestProvider` | Supabase DB | CRUD quêtes, filtres, calcul des récompenses |
| `PlayerProvider` | Hive | Niveau, XP, or, cristaux, HP, moral, streak |
| `InventoryProvider` | Hive | Inventaire 50 emplacements avec empilement |
| `EquipmentProvider` | Hive | Équipement et objets équipés |
| `ThemeProvider` | Hive | Persistance thème clair/sombre/système |
| `NotificationProvider` | Local notifications | Planification et état des notifications |

Les pages UI ne doivent jamais appeler directement Supabase, Hive ou la couche `data`. Elles passent par les providers et les services du domaine.

## Backend et persistance

- **Supabase** : Auth + PostgreSQL pour les quêtes, profils et données cloud. Configuration dans `lib/config/supabase_config.dart`, clés dans `.env`.
- **Hive** : persistance locale pour joueur, inventaire, équipement et réglages. Les boxes sont ouvertes au démarrage.
- **IA** : API Claude via appels `http` directs, avec clés/API secrets dans `.env`.
- **Notifications** : `flutter_local_notifications` + `timezone`.

## Design System

- **Material 3** avec thèmes clair/sombre dans `ui/theme/`.
- **Couleurs** : utiliser `AppColors`, sans valeurs `Color(0x...)` en dur dans l'UI.
- **Style** : fantasy RPG dark, surfaces sombres, accents lumineux, particules si pertinent.
- **Polices** : MedievalSharp pour les titres fantasy, Press Start 2P pour les stats, Quicksand/Poppins pour le corps.
- **Rareté** : Common gris, Uncommon vert, Rare bleu, Epic violet, Legendary or, Mythic rouge/rose.
- **Widgets** : réutiliser `common/`, `minimalist/`, `magical/` et `fantasy/` avant de créer un nouveau composant.

## Règles de développement impératives

1. Lire le fichier complet avant toute modification.
2. Choisir la solution la plus simple qui respecte l'architecture existante.
3. Ne pas refactorer du code non concerné par la demande.
4. Après toute mutation d'état dans un provider, appeler `notifyListeners()`.
5. Après tout changement `@HiveType` ou `@HiveField`, lancer `dart run build_runner build`.
6. Toutes les opérations Supabase/Hive passent par providers, repositories ou services adaptés, jamais directement depuis l'UI.
7. Exposer les erreurs via un état `_error` ou équivalent ; ne pas les ignorer silencieusement.
8. Ne pas hardcoder de clés API, URLs sensibles ou constantes métier dispersées.
9. Utiliser `withValues(alpha: x)` au lieu de `withOpacity()`.
10. Après un `await` dans une méthode utilisant `BuildContext`, vérifier `context.mounted` avant de réutiliser le contexte.
11. UI, documentation, commentaires utiles, variables métier et messages de commit doivent être en français.
12. Les commits utilisent le format `feat:`, `fix:`, `refactor:`, `style:` ou `chore:` avec un libellé français.

## Logique métier de référence

- **Récompenses de quêtes** : XP = `10 × difficulté`, Or = `25 × difficulté`, cristaux si difficulté > 3.
- **Multiplicateurs de temps** : en avance = `×1.25`, à temps = `×1.10`, en retard = `×0.80`.
- **Bonus de streak** : streak ≥ 7 jours = `+0.10` au multiplicateur.
- **Level-up** : seuil XP = `(100 × level × 1.5).round()`, HP max = `100 + (level - 1) × 10`.
- **Gacha** : Mythic 0,1 %, Legendary 0,9 %, Epic 4 %, Rare 10 %, Uncommon 25 %, Common 60 %.

## Assets visuels

Pour créer des icônes, illustrations, bannières ou splash screens :

- Utiliser Python + PIL/Pillow ou cairosvg.
- Placer les fichiers dans `assets/images/` ou `assets/icons/`.
- Ajouter la référence dans `pubspec.yaml` si nécessaire.
- Utiliser PNG pour les images et SVG pour les icônes vectorielles.
- Respecter les couleurs et le style fantasy RPG dark du design system.

## Supabase

- Écrire les migrations SQL avec commentaires explicatifs.
- Respecter les policies RLS existantes.
- Tester avec un `SELECT` avant tout `UPDATE` ou `DELETE`.
- Les foreign keys vers `auth.users` utilisent `ON DELETE CASCADE`.
