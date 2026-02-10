# Agents et skills Cursor pour Sameva

Ce dossier configure des **skills** (savoir-faire) et des **règles** (conventions) pour que Claude travaille de façon cohérente sur le projet Sameva.

## Skills (savoir-faire)

Les skills sont dans `.cursor/skills/`. Cursor les active automatiquement quand la conversation correspond à leur description.

| Skill | Quand il s'active |
|-------|-------------------|
| **sameva-architecture** | Ajout de fonctionnalités, refactoring, nouvelles pages ou providers, questions sur où placer le code |
| **sameva-design-system** | Création ou modification d'écrans, widgets, thème, travail dans `lib/ui/` |
| **sameva-domain** | Logique métier (quêtes, récompenses, items, équipement), Hive, Supabase |

## Règles (conventions)

Les règles sont dans `.cursor/rules/`. Elles s'appliquent quand tu travailles sur des fichiers qui correspondent aux patterns indiqués.

| Règle | Fichiers concernés |
|-------|---------------------|
| **sameva-dart** | `lib/**/*.dart` — Conventions Dart/Flutter et français |
| **sameva-ui** | `lib/ui/**/*.dart` — Design system, AppColors, widgets existants |

## Résumé

- **Skills** = ce que l’agent sait faire (architecture, design, domaine).
- **Règles** = ce qu’il doit respecter (Dart, français, UI) selon les fichiers ouverts.

Tu peux aussi mentionner explicitement un skill dans ta requête (ex. « en suivant sameva-architecture ») pour le forcer.
