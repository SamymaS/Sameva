# Backlog technique Sameva

État : 19/05/2026
Maintenu manuellement à chaque fin de session.

## Priorité haute (dette architecturale)

### 1. Refonte des sources de vérité ViewModels

**Pattern observé 3 fois** :
- Bug Companions (résolu B2, commit d9b5216) — table Supabase non synchronisée
- Bug Quest validation "Quête introuvable" — QuestViewModel snapshot non rafraîchi
- Bug Quest validation "No element" — même cause, autre firstWhere

**Cause racine** : plusieurs ViewModels (singletons globaux + instances locales) maintiennent des snapshots in-memory parallèles. Les mutations dans un VM ne notifient pas les autres.

**[Résolu Quest — 11/06/2026]** Le `QuestViewModel` global est désormais l'**unique source de vérité**
des quêtes (cohérent avec le pattern Cat). `QuestsListViewModel`, `CreateQuestViewModel`,
`QuestValidationViewModel` et `ProfileViewModel` ne détiennent plus de snapshot : ils lisent
`questVM.quests` / délèguent leurs mutations (la liste de filtres forwarde les notifications du VM source).
`QuestRepository` reste stateless et n'est plus exposé via Provider. Patch défensif retiré.

**Reliquat** :
- **Player** : appliquer le même pattern (couplé à la dette Hive vs Remote, TECH_DEBT.md).
- **Cat** : déjà conforme (VM global unique = autorité).

### 2. Migration initial_schema versionnée

**Constat** : la table companions et autres viennent d'un schéma initial non présent dans `supabase/migrations/`. Si déploiement sur nouvelle instance Supabase → migrations B1, B2 échoueraient sur tables inexistantes.

**Fix** : créer `supabase/migrations/20260101000000_initial_schema.sql` qui rejoue les CREATE TABLE de tout le schéma actuel. Argument certif Bloc 4 (portabilité, reproductibilité environnement).

## Priorité moyenne

### 3. Feature delete account RGPD

Bouton "Supprimer mon compte" dans Paramètres, remplace "Remettre à zéro". Edge Function avec service_role + cleanup Hive + cascade DB. Outil de test infini en plus.

### 4. Wording erreur MougiBot 529

Distinguer dans l'UI "réseau down" vs "API IA surchargée" (Anthropic 529 overloaded_error). Améliore l'expérience user en cas d'incident Anthropic.

### 5. Race condition rarity gacha

Dart `_validRarities` inclut `'special'` absent du CHECK SQL `companions_rarity_check` (qui contient `'veryRare'` à la place). À aligner avant implémentation gacha (sinon upsert silencieusement rejeté). TODO existant dans `cat_model.dart`.

## Priorité basse (nettoyage)

### 6. Suggestions reviewer B2 (S-1, S-4)

- S-1 : commentaire warning sur `_persist()` dans CatViewModel
- S-4 : cast `response as List` → `response is List` plus défensif dans CatRepository

### 7. Naming primaryTurquoise → primaryViolet

L'alias `primaryTurquoise` pointe sur du violet `0xFF805AD5` dans `app_colors.dart`. Renommer pour clarté, ou créer un vrai `accentTurquoise` distinct.

### 8. Colonne mood résiduelle dans companions

Colonne `integer NOT NULL DEFAULT 100` héritée du schéma initial RPG générique, non mappée côté Dart. DROP COLUMN à faire dans une migration future.

### 9. Settings catch-all box Hive

Le widget `quest_detail_sheet` persiste des sous-tâches dans `Hive.box('settings')`, convention catch-all du repo. Créer une box dédiée `'subtasks'` ou `'quest_state'` pour mieux typer.

### 10. Tests AuthVM.waitForSignedInUserId

Skip lors de session B2 car `Supabase.instance` singleton non-injectable. À couvrir avec un wrapper `SupabaseAuthClient` injectable.

### 11. Pin version Flutter (FVM ou équivalent)

Bug pipeline du 19/05/2026 : assertion Flutter ListTile durcie en erreur sur le runner CI mais pas en local après `flutter upgrade` récent. Divergence de versions Flutter entre machines = source de bugs CI imprévisibles.

Solution : utiliser FVM (Flutter Version Manager) avec un `.fvmrc` versionné dans le repo, ou pinner via le workflow GitHub Actions une version exacte. Argument certif Bloc 4 (reproductibilité environnement).

## Historique de résolution

- 16/05/2026 : Session B2 — sync companions cross-device (commits 7898e14 → baf52ce)
- 19/05/2026 : Fix quest-validation court terme + patch défensif cat-vm
- 19/05/2026 : Fix pipeline CI quest_detail_sheet (DecoratedBox → Material)
- 11/06/2026 : Refonte source de vérité Quest — QuestViewModel global = source unique, VMs page délèguent (dette #1 résolue pour Quest)
- 11/06/2026 : Navbar épurée — DockBar réduite à 5 onglets MVP (Accueil/Quêtes/Portail/Chat/Profil) ; Marché+Invocation fusionnés en Portail (TabBar Invocation/Boutique/Vendre) ; Stock via Profil ; Jeux/Premium masqués via lib/config/feature_flags.dart
