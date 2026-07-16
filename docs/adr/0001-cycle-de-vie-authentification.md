# 0001. Cycle de vie d'authentification uniforme des ViewModels et services

- **Statut** : Accepté et implémenté
- **Date** : décidé le 2026-07-01, implémenté le 2026-07-01

---

## Contexte

Sameva accumule quatre dettes structurelles découvertes lors de l'inventaire. Elles sont indépendantes en nature mais liées par ordre de risque : la dette auth (P1) est la seule à provoquer des bugs runtime visibles par l'utilisateur (quêtes d'un autre user visibles). Les autres (P2, P3, P4) sont des dettes d'extensibilité qui bloquent l'ajout d'assets commissionés (P2), de son/haptique (P3), et du personnage héros (P4). L'ordre des phases reflète le risque décroissant et les dépendances inter-phases.

Contraintes non négociables rappelées :

- **Paco** = mascotte / MougiBot uniquement. Pas un héros jouable, pas un compagnon.
- **Héros** = humanoïdes à classes (Guerrier, Mage, Barde, Moine). Entités distinctes de Mougi et des compagnons.
- **Compagnons** = entités RPG gacha distinctes des héros. Aucun lien stylistique avec Paco.
- **AssetResolver** opère sur des placeholders par défaut. Les vrais assets viennent d'une commission humaine (Noyuss, post-MVP). Aucun asset IA pour héros/compagnons.
- Anti-pattern interdit : ViewModel prenant un `String id` + `firstWhere` sur un snapshot mémoire périmé. Passer toujours l'objet complet.

---

Cette décision traite la dette d'authentification, seule des quatre dettes inventoriées à provoquer des
anomalies visibles par l'utilisateur, comme l'affichage des quêtes d'un compte précédent après un
changement de session.

## Contraintes de projet rappelées

- **Paco** : mascotte et visage de MougiBot uniquement. Ni héros jouable, ni compagnon.
- **Héros** : humanoïdes à classes (Guerrier, Mage, Barde, Moine), distincts de Mougi et des compagnons.
- **Compagnons** : entités RPG obtenues par gacha, distinctes des héros, sans lien stylistique avec Paco.
- Les assets définitifs proviennent d'une commission humaine. Aucun asset généré pour les héros et compagnons.
- Anti-pattern interdit : un ViewModel qui reçoit un `String id` puis fait un `firstWhere` sur un snapshot mémoire périmé. Toujours passer l'objet complet.

---

## Inventaire factuel, cycle de vie auth des ViewModels et services

Cet inventaire a été établi par lecture directe du code, à la date de la décision. Aucune valeur n'est devinée.

### Tableau A : Lifecycle auth des ViewModels/Services

| VM / Service | Fichier | Mode de chargement actuel | onSignedOut | onSignedIn | État per-user |
|---|---|---|---|---|---|
| `QuestViewModel` | `lib/presentation/view_models/quest_view_model.dart:16` | Manuel, `loadQuests(userId)` déclenché par `SanctuaryPage._load()` via `addPostFrameCallback` | **NON**, `clearCache()` existe (ligne 34) mais n'est jamais appelé au logout | **NON** | OUI (`_quests`, Supabase) |
| `PlayerViewModel` | `lib/presentation/view_models/player_view_model.dart:25` | Manuel, `loadPlayerStats(userId)` via `SanctuaryPage._load()` | OUI → `reset()` (ligne 27) | **NON**, pas de rechargement automatique au sign-in | OUI (`_stats`, Hive `playerStats`, clé fixe `stats`) |
| `InventoryViewModel` | `lib/presentation/view_models/inventory_view_model.dart:15` | Constructeur, `loadInventory()` appelé au boot `main.dart:84`, une seule fois | OUI → `reset()` (ligne 17) | **NON** | OUI (`_items`, Hive `inventory`, clé fixe `items`) |
| `EquipmentViewModel` | `lib/presentation/view_models/equipment_view_model.dart:27` | Constructeur, `loadEquipment()` appelé au boot `main.dart:85`, une seule fois | OUI → `reset()` (ligne 29) | **NON** | OUI (`_equipped`/`_cosmetics`, Hive `equipment`, clés fixes `equipment`/`cosmetics`) |
| `CatViewModel` | `lib/presentation/view_models/cat_view_model.dart:28` | Constructeur + `onSignedIn` → `loadCats()` (ligne 41) | OUI → `reset()` (ligne 37) | OUI → `loadCats()` (ligne 41) | OUI (Hive `cats`, clé isolée `cats_list_$userId`) |
| `AiValidationCreditsService` | `lib/presentation/view_models/ai_validation_credits_service.dart:81` | `onSignedIn` → `_onSignedIn()` → `load(uid)` (ligne 96) | OUI → `reset()` (ligne 92) | OUI → `_onSignedIn()` (ligne 96) | OUI (Hive `aiValidation`, clé isolée `ai_validation_$userId`) |
| `ThemeViewModel` | `lib/presentation/view_models/theme_view_model.dart:11` | Constructeur, lecture Hive `settings` | NON | NON | NON (préférence globale) |
| `LeaderboardViewModel` | `lib/presentation/view_models/leaderboard_view_model.dart:6` | Manuel, `load(userId)` depuis la page | NON | NON | NON (classement public ; reste en mémoire entre sessions) |
| `ActivityLogService` | `lib/domain/services/activity_log_service.dart:37` | Service statique, `_cache` chargé lazily, clé Hive fixe `activity_log` dans `settings` | NON, `clearLog()` (ligne 76) appelé uniquement au `deleteAccount()`, pas au logout simple | NON | OUI (`_cache` statique, clé Hive fixe partagée entre users) |
| `ProfileViewModel` | `lib/presentation/view_models/profile_view_model.dart:12` | Manuel, `load(userId)` depuis la page (VM local, reconstruit à chaque navigation) | NON | NON | OUI (VM local, reconstitué par route) |

**Anti-patterns actifs identifiés :**

1. `QuestViewModel` (fichier:34) : aucun abonnement `onSignedOut`/`onSignedIn`. Les quêtes du user précédent restent visibles si la `SanctuaryPage` est KeepAlive (elle l'est : `app.dart:51`, index 0).
2. `PlayerViewModel` (fichier:25) : pas de `onSignedIn`. `_stats` reste `null` après sign-in d'un autre user jusqu'à ce que `SanctuaryPage` appelle `loadPlayerStats()`.
3. `InventoryViewModel` / `EquipmentViewModel` : clés Hive fixes. Après `signOut → reset()` + `signIn` d'un autre user, les données ne se rechargent pas car il n'y a pas de déclencheur `onSignedIn`. L'inventaire reste vide jusqu'à un rechargement manuel.
4. `ActivityLogService` : `_cache` statique survit au logout simple. Un user B peut lire le log de user A jusqu'à la première écriture qui écraserait le cache.

---

### Problème

`QuestViewModel`, `PlayerViewModel`, `InventoryViewModel`, `EquipmentViewModel`, et `ActivityLogService` ne sont pas abonnés à `onSignedIn` (ou à `onSignedOut` pour `QuestViewModel`). Les conséquences concrètes :

- Un user A se connecte, charge ses quêtes. Il se déconnecte. La `SanctuaryPage` est KeepAlive (`app.dart:51`). Ses quêtes restent dans `QuestViewModel._quests`. User B se connecte, il voit les quêtes de user A jusqu'à ce que `SanctuaryPage._load()` soit re-déclenché (ce qui ne se produit pas si la page est déjà construite et KeepAlive).
- `ActivityLogService._cache` est statique. Il traverse les changements d'utilisateur.
- `PlayerViewModel._stats`, `InventoryViewModel._items`, `EquipmentViewModel._equipped` restent à leur état post-reset (null/vide) après sign-in d'un autre user, jusqu'à ce que l'UI les recharge manuellement.

### Décision

Normaliser tous les ViewModels à état per-user selon le même contrat que `CatViewModel` et `AiValidationCreditsService` : `{Stream<void>? onSignedOut, Stream<void>? onSignedIn}` injectés au constructeur, abonnements dans le constructeur, `cancel()` dans `dispose()`.

Pour `ActivityLogService` (service statique, refactoring plus invasif) : ajouter `ActivityLogService.clearLog()` dans `AuthViewModel._purgeHiveData()`, chemin le moins invasif, idempotent, couvre le logout simple.

**Migrations à effectuer :**

| VM / Service | Changement | Fichier | Déclencheur après changement |
|---|---|---|---|
| `QuestViewModel` | Ajouter `Stream<void>? onSignedOut` → `clearCache()` ; `Stream<void>? onSignedIn` → `loadQuests(uid)` avec résolution uid via `Supabase.instance.client.auth.currentUser?.id` (même pattern que `CatViewModel:48`) | `quest_view_model.dart` | Auto au sign-in/out |
| `PlayerViewModel` | Ajouter `Stream<void>? onSignedIn` → `loadPlayerStats(uid)` | `player_view_model.dart` | Auto au sign-in |
| `InventoryViewModel` | Ajouter `Stream<void>? onSignedIn` → `loadInventory()` | `inventory_view_model.dart` | Auto au sign-in |
| `EquipmentViewModel` | Ajouter `Stream<void>? onSignedIn` → `loadEquipment()` | `equipment_view_model.dart` | Auto au sign-in |
| `ActivityLogService` | Ajouter `await ActivityLogService.clearLog()` dans `AuthViewModel._purgeHiveData()` (ligne 260) | `auth_view_model.dart` | Auto au logout |
| `main.dart` | Passer `onSignedIn: signedInStream` aux constructeurs `QuestViewModel`, `PlayerViewModel`, `InventoryViewModel`, `EquipmentViewModel` | `main.dart:82-85` | Câblage statique |

**Garde idempotente pour `QuestViewModel.onSignedIn` :** si `_quests.isNotEmpty`, ne pas recharger (même garde que `CatViewModel:93`). Cela évite le double-chargement avec `SanctuaryPage._load()`.

**Note sur les clés Hive fixes** (`InventoryViewModel`, `EquipmentViewModel`, `PlayerViewModel`) : la migration vers des clés per-user (comme `CatViewModel`) est souhaitable à terme mais sort du périmètre P1. P1 se contente d'ajouter le déclencheur `onSignedIn`. La contamination inter-user est déjà couverte par le `reset()` au `onSignedOut` qui purge la clé Hive fixe, un user B ne verra jamais les données de user A, mais ses propres données (d'une session précédente) auraient été écrasées. Ce risque est documenté et reporté.

### Alternatives écartées

- **Rechargement depuis la page uniquement (statu quo)** : ne couvre pas le cas KeepAlive. `SanctuaryPage` est en KeepAlive (index 0) et ne rebuild pas au sign-in d'un autre user. Bogue validé.
- **Déplacer tous les chargements dans `app.dart` après sign-in** : crée un couplage fort entre `_AuthGate` et chaque VM. Le pattern stream est plus découplé et déjà en place pour `CatViewModel`.
- **Migrer les clés Hive vers per-user en P1** : invasif, change le format de données stockées (risque de migration), sort du périmètre. Réservé comme chantier P1b post-validation.

### Impact MVVM

P1 est additif : ajout de paramètres optionnels aux constructeurs existants. Aucune interface publique modifiée. Les pages qui appelaient `loadQuests()` manuellement continuent de fonctionner, la garde idempotente absorbe le double appel.

### Stratégie de test

- Test unitaire `QuestViewModel` : injecter un `StreamController<void>.broadcast()`, vérifier que `clearCache()` est appelé au `add(null)` sur `onSignedOut`, et que `loadQuests()` est déclenché au `add(null)` sur `onSignedIn`.
- Test `ActivityLogService` : vérifier que `clearLog()` vide `_cache` + supprime la clé Hive.
- Test d'intégration `AuthViewModel` : simuler `signOut()`, vérifier que `_purgeHiveData()` appelle `clearLog()`.

### Risques

- **Double-chargement QuestViewModel** : couvert par la garde idempotente. Risque faible.
- **Race condition onSignedIn vs boot** : identique au cas `CatViewModel`, déjà résolu par la garde `_cats.isNotEmpty`. Reproductible uniquement si l'event `onSignedIn` arrive avant `loadCats()` du constructeur, non observable car `main()` est synchrone jusqu'au `runApp()`.
- **uid null au moment du onSignedIn** : `Supabase.instance.client.auth.currentUser?.id` peut théoriquement être null si Supabase n'a pas encore hydraté la session. Le pattern `CatViewModel` gère ce cas en testant `if (key == null) return`, répliquer.

---

---

## Conséquences

**Positif**

- Fin de l'anomalie « quêtes du compte précédent visibles après connexion » sur une page maintenue en mémoire.
- Contrat d'abonnement homogène : tous les ViewModels porteurs d'un état propre à l'utilisateur suivent le même patron, celui du `CatViewModel`.
- Le rechargement du portefeuille de jetons en session restaurée est corrigé par voie structurelle plutôt que par un correctif ponctuel.

**Négatif et dette acceptée**

- Les clés Hive fixes (`InventoryViewModel`, `EquipmentViewModel`, `PlayerViewModel`) ne sont pas migrées vers des clés propres à l'utilisateur. Le risque de contamination entre comptes sur un même appareil est documenté et reporté.
- `ActivityLogService` reste un service statique : sa purge par `_purgeHiveData()` à la déconnexion est un correctif local, pas une refonte. Il n'est donc pas abonné aux flux d'événements.

---

## État d'implémentation

| Élément | État |
| --- | --- |
| `AuthViewModel` expose `onSignedIn` et `onSignedOut` | Implémenté |
| `QuestViewModel`, `PlayerViewModel`, `InventoryViewModel`, `EquipmentViewModel`, `CatViewModel`, `AiValidationCreditsService` abonnés depuis `main.dart` | Implémenté |
| Garde idempotente contre le double chargement | Implémenté |
| `ActivityLogService` purgé via `_purgeHiveData()` | Implémenté |
| Migration vers des clés Hive propres à l'utilisateur | Reporté |
