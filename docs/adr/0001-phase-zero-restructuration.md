# 0001 — Phase-zero restructuration : lifecycle auth, AssetResolver, GameEventBus, HeroAvatar

- **Statut** : Proposé
- **Date** : 2026-07-01

---

## Inventaire factuel (base de l'ADR)

Cet inventaire a été établi par lecture directe du code. Aucune valeur n'est devinée.

### Tableau A — Lifecycle auth des ViewModels/Services

| VM / Service | Fichier | Mode de chargement actuel | onSignedOut | onSignedIn | État per-user |
|---|---|---|---|---|---|
| `QuestViewModel` | `lib/presentation/view_models/quest_view_model.dart:16` | Manuel — `loadQuests(userId)` déclenché par `SanctuaryPage._load()` via `addPostFrameCallback` | **NON** — `clearCache()` existe (ligne 34) mais n'est jamais appelé au logout | **NON** | OUI (`_quests`, Supabase) |
| `PlayerViewModel` | `lib/presentation/view_models/player_view_model.dart:25` | Manuel — `loadPlayerStats(userId)` via `SanctuaryPage._load()` | OUI → `reset()` (ligne 27) | **NON** — pas de rechargement automatique au sign-in | OUI (`_stats`, Hive `playerStats`, clé fixe `stats`) |
| `InventoryViewModel` | `lib/presentation/view_models/inventory_view_model.dart:15` | Constructeur — `loadInventory()` appelé au boot `main.dart:84`, une seule fois | OUI → `reset()` (ligne 17) | **NON** | OUI (`_items`, Hive `inventory`, clé fixe `items`) |
| `EquipmentViewModel` | `lib/presentation/view_models/equipment_view_model.dart:27` | Constructeur — `loadEquipment()` appelé au boot `main.dart:85`, une seule fois | OUI → `reset()` (ligne 29) | **NON** | OUI (`_equipped`/`_cosmetics`, Hive `equipment`, clés fixes `equipment`/`cosmetics`) |
| `CatViewModel` | `lib/presentation/view_models/cat_view_model.dart:28` | Constructeur + `onSignedIn` → `loadCats()` (ligne 41) | OUI → `reset()` (ligne 37) | OUI → `loadCats()` (ligne 41) | OUI (Hive `cats`, clé isolée `cats_list_$userId`) |
| `AiValidationCreditsService` | `lib/presentation/view_models/ai_validation_credits_service.dart:81` | `onSignedIn` → `_onSignedIn()` → `load(uid)` (ligne 96) | OUI → `reset()` (ligne 92) | OUI → `_onSignedIn()` (ligne 96) | OUI (Hive `aiValidation`, clé isolée `ai_validation_$userId`) |
| `ThemeViewModel` | `lib/presentation/view_models/theme_view_model.dart:11` | Constructeur — lecture Hive `settings` | NON | NON | NON (préférence globale) |
| `LeaderboardViewModel` | `lib/presentation/view_models/leaderboard_view_model.dart:6` | Manuel — `load(userId)` depuis la page | NON | NON | NON (classement public ; reste en mémoire entre sessions) |
| `ActivityLogService` | `lib/domain/services/activity_log_service.dart:37` | Service statique — `_cache` chargé lazily, clé Hive fixe `activity_log` dans `settings` | NON — `clearLog()` (ligne 76) appelé uniquement au `deleteAccount()`, pas au logout simple | NON | OUI (`_cache` statique, clé Hive fixe partagée entre users) |
| `ProfileViewModel` | `lib/presentation/view_models/profile_view_model.dart:12` | Manuel — `load(userId)` depuis la page (VM local, reconstruit à chaque navigation) | NON | NON | OUI (VM local, reconstitué par route) |

**Anti-patterns actifs identifiés :**

1. `QuestViewModel` (fichier:34) : aucun abonnement `onSignedOut`/`onSignedIn`. Les quêtes du user précédent restent visibles si la `SanctuaryPage` est KeepAlive (elle l'est : `app.dart:51`, index 0).
2. `PlayerViewModel` (fichier:25) : pas de `onSignedIn`. `_stats` reste `null` après sign-in d'un autre user jusqu'à ce que `SanctuaryPage` appelle `loadPlayerStats()`.
3. `InventoryViewModel` / `EquipmentViewModel` : clés Hive fixes. Après `signOut → reset()` + `signIn` d'un autre user, les données ne se rechargent pas car il n'y a pas de déclencheur `onSignedIn`. L'inventaire reste vide jusqu'à un rechargement manuel.
4. `ActivityLogService` : `_cache` statique survit au logout simple. Un user B peut lire le log de user A jusqu'à la première écriture qui écraserait le cache.

### Tableau B — Références d'assets hardcodées

| Fichier | Lignes | Type | Comptage | Statut |
|---|---|---|---|---|
| `lib/domain/services/item_factory.dart` | 22–393 | `assets/items/*.svg` | 46 chemins | Les 46 fichiers SVG existent dans `assets/items/` |
| `lib/domain/services/craft_service.dart` | 29, 48 | `assets/items/*.svg` | 2 chemins | Fichiers présents |
| `assets/animations/` | — | JSON Lottie | 3 fichiers orphelins (`loading.json`, `rpg_loading.json`, `rpg_logo.json`) | Aucun widget ne les charge ; package `lottie` absent du `pubspec.yaml` |

Aucune classe `AssetResolver` n'existe. Les chemins SVG items sont passés en `String` dans le modèle `Item` (champ `assetPath`, `data/models/item_model.dart:25`) puis consommés par `ItemIcon` (`lib/ui/widgets/common/item_icon.dart:80`) via `SvgPicture.asset()`. `ItemIcon` dispose déjà d'un fallback `_fallbackIcon()` (ligne 88) mais celui-ci est local au widget, pas une stratégie globale pilotable.

### Tableau C — Rendu avatar/héros actuel

| Entité | Fichier | Rendu actuel |
|---|---|---|
| **Mougi (compagnon)** | `lib/ui/widgets/cat/cat_widget.dart:20` | `Stack` + `CustomPainter` (`_CatPainter`) + couches widget (aura, tenue, pantalon, chaussures, accessoire, chapeau emoji). AnimationControllers : `_swayCtrl` (3 s, repeat/reverse) + `_auraCtrl` (2 s, repeat/reverse). C'est la seule entité avec un rendu graphique natif. |
| **Héros (page Avatar)** | `lib/ui/pages/avatar/avatar_page.dart:100` | `Container` circulaire avec initiale de l'email en `Text`. Aucun `CustomPainter`, aucune image, aucun widget de personnage. C'est un placeholder basique. |
| **Slots cosmétiques RPG** | `lib/presentation/view_models/equipment_view_model.dart:13` | Existent dans `EquipmentViewModel` (`_equipped` 5 slots + `_cosmetics` map) mais ne sont rendus nulle part sous forme graphique — seulement listés en texte dans `_EquipmentSection` d'`AvatarPage`. |

### Tableau D — Déclencheurs d'animation (couplage actuel)

| Pattern | Fichier | Déclencheur | Type de couplage |
|---|---|---|---|
| Notification slide+fade | `lib/ui/utils/app_notification.dart` | `AppNotification.show(context, ...)` — 20+ call sites dans les pages (`sanctuary_page.dart:60,99,136`, `quest_validation_page.dart:136,270`, `cat_page.dart:87,246,253`, `market_page.dart:291,978,1149`, `invocation_page.dart:214,279,919`, etc.) | Appel impératif UI → animation |
| Réaction chat post-validation | `lib/ui/pages/quest/quest_validation_page.dart:239` | `showCatReactionOverlay(...)` | Appel impératif UI → animation |
| Particules récompenses | `lib/ui/pages/rewards/rewards_page.dart` | `_particleCtrl` local (3 s, repeat) drive `_ParticlePainter` | Local à la page, déclenché au build |
| Compteur animé | `lib/ui/pages/rewards/rewards_page.dart` | `_countCtrl` + `_AnimatedCounter` | Local à la page |
| Révélation gacha | `lib/ui/pages/invocation/invocation_page.dart` | `_pulseController` + `_revealController` | Local à la page |
| Pop réaction chat | `lib/ui/widgets/cat/cat_reaction_overlay.dart` | `_ctrl` 500 ms `elasticOut` | Local au widget overlay |
| Révélation récompense quête | `lib/ui/pages/quest/quest_validation_page.dart:1164` | `_ctrl` AnimationController (ligne 1171) | Local à la page |
| Idle Mougi | `lib/ui/widgets/cat/cat_widget.dart:61` | `_swayCtrl` + `_auraCtrl` en repeat/reverse | Permanent, local au widget |

Aucun `GameEventBus` n'existe. Les seuls `StreamController.broadcast()` présents sont `onSignedIn`/`onSignedOut` dans `AuthViewModel` (auth uniquement).

---

## Contexte (commun aux 4 phases)

Sameva accumule quatre dettes structurelles découvertes lors de l'inventaire. Elles sont indépendantes en nature mais liées par ordre de risque : la dette auth (P1) est la seule à provoquer des bugs runtime visibles par l'utilisateur (quêtes d'un autre user visibles). Les autres (P2, P3, P4) sont des dettes d'extensibilité qui bloquent l'ajout d'assets commissionés (P2), de son/haptique (P3), et du personnage héros (P4). L'ordre des phases reflète le risque décroissant et les dépendances inter-phases.

Contraintes non négociables rappelées :

- **Paco** = mascotte / MougiBot uniquement. Pas un héros jouable, pas un compagnon.
- **Héros** = humanoïdes à classes (Guerrier, Mage, Barde, Moine). Entités distinctes de Mougi et des compagnons.
- **Compagnons** = entités RPG gacha distinctes des héros. Aucun lien stylistique avec Paco.
- **AssetResolver** opère sur des placeholders par défaut. Les vrais assets viennent d'une commission humaine (Noyuss, post-MVP). Aucun asset IA pour héros/compagnons.
- Anti-pattern interdit : ViewModel prenant un `String id` + `firstWhere` sur un snapshot mémoire périmé. Passer toujours l'objet complet.

---

## Phase P1 — Abonnement UNIFORME des VM/Services au lifecycle auth

### Problème

`QuestViewModel`, `PlayerViewModel`, `InventoryViewModel`, `EquipmentViewModel`, et `ActivityLogService` ne sont pas abonnés à `onSignedIn` (ou à `onSignedOut` pour `QuestViewModel`). Les conséquences concrètes :

- Un user A se connecte, charge ses quêtes. Il se déconnecte. La `SanctuaryPage` est KeepAlive (`app.dart:51`). Ses quêtes restent dans `QuestViewModel._quests`. User B se connecte — il voit les quêtes de user A jusqu'à ce que `SanctuaryPage._load()` soit re-déclenché (ce qui ne se produit pas si la page est déjà construite et KeepAlive).
- `ActivityLogService._cache` est statique. Il traverse les changements d'utilisateur.
- `PlayerViewModel._stats`, `InventoryViewModel._items`, `EquipmentViewModel._equipped` restent à leur état post-reset (null/vide) après sign-in d'un autre user, jusqu'à ce que l'UI les recharge manuellement.

### Décision

Normaliser tous les ViewModels à état per-user selon le même contrat que `CatViewModel` et `AiValidationCreditsService` : `{Stream<void>? onSignedOut, Stream<void>? onSignedIn}` injectés au constructeur, abonnements dans le constructeur, `cancel()` dans `dispose()`.

Pour `ActivityLogService` (service statique, refactoring plus invasif) : ajouter `ActivityLogService.clearLog()` dans `AuthViewModel._purgeHiveData()` — chemin le moins invasif, idempotent, couvre le logout simple.

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

**Note sur les clés Hive fixes** (`InventoryViewModel`, `EquipmentViewModel`, `PlayerViewModel`) : la migration vers des clés per-user (comme `CatViewModel`) est souhaitable à terme mais sort du périmètre P1. P1 se contente d'ajouter le déclencheur `onSignedIn`. La contamination inter-user est déjà couverte par le `reset()` au `onSignedOut` qui purge la clé Hive fixe — un user B ne verra jamais les données de user A, mais ses propres données (d'une session précédente) auraient été écrasées. Ce risque est documenté et reporté.

### Alternatives écartées

- **Rechargement depuis la page uniquement (statu quo)** : ne couvre pas le cas KeepAlive. `SanctuaryPage` est en KeepAlive (index 0) et ne rebuild pas au sign-in d'un autre user. Bogue validé.
- **Déplacer tous les chargements dans `app.dart` après sign-in** : crée un couplage fort entre `_AuthGate` et chaque VM. Le pattern stream est plus découplé et déjà en place pour `CatViewModel`.
- **Migrer les clés Hive vers per-user en P1** : invasif, change le format de données stockées (risque de migration), sort du périmètre. Réservé comme chantier P1b post-validation.

### Impact MVVM

P1 est additif : ajout de paramètres optionnels aux constructeurs existants. Aucune interface publique modifiée. Les pages qui appelaient `loadQuests()` manuellement continuent de fonctionner — la garde idempotente absorbe le double appel.

### Stratégie de test

- Test unitaire `QuestViewModel` : injecter un `StreamController<void>.broadcast()`, vérifier que `clearCache()` est appelé au `add(null)` sur `onSignedOut`, et que `loadQuests()` est déclenché au `add(null)` sur `onSignedIn`.
- Test `ActivityLogService` : vérifier que `clearLog()` vide `_cache` + supprime la clé Hive.
- Test d'intégration `AuthViewModel` : simuler `signOut()`, vérifier que `_purgeHiveData()` appelle `clearLog()`.

### Risques

- **Double-chargement QuestViewModel** : couvert par la garde idempotente. Risque faible.
- **Race condition onSignedIn vs boot** : identique au cas `CatViewModel`, déjà résolu par la garde `_cats.isNotEmpty`. Reproductible uniquement si l'event `onSignedIn` arrive avant `loadCats()` du constructeur — non observable car `main()` est synchrone jusqu'au `runApp()`.
- **uid null au moment du onSignedIn** : `Supabase.instance.client.auth.currentUser?.id` peut théoriquement être null si Supabase n'a pas encore hydraté la session. Le pattern `CatViewModel` gère ce cas en testant `if (key == null) return` — répliquer.

---

## Phase P2 — AssetResolver : placeholders par défaut, contrat vers vrais assets

### Problème

48 chemins d'assets sont hardcodés dans la couche domaine (`item_factory.dart`, `craft_service.dart`). Quand les vrais assets héros/compagnons seront commissionés (Noyuss), ils devront être intégrés sans modifier le domaine. Actuellement, tout ajout d'un nouveau type visuel (héros, compagnon) nécessiterait de modifier `item_factory.dart` directement.

De plus, le widget `ItemIcon` (`lib/ui/widgets/common/item_icon.dart:80`) fait `SvgPicture.asset(item.assetPath!)` sans passer par une couche d'indirection : si un chemin devient invalide, l'erreur est silencieuse (fallback local) mais non observable depuis le domaine.

### Décision

Créer `AssetResolver` en `lib/utils/asset_resolver.dart` : service statique (sans état) qui centralise la résolution de chemins d'assets. Le domaine ne connaît que des **identifiants logiques** ; `AssetResolver` mappe vers le chemin physique ou vers un placeholder.

**Contrat Dart proposé :**

```dart
/// Résout un chemin d'asset depuis un identifiant logique.
/// Retourne toujours un chemin valide : vrai asset si présent, placeholder sinon.
/// Le domaine n'importe jamais ce service — seule la couche UI l'utilise.
abstract final class AssetResolver {

  // ── Items (déjà présents dans assets/items/) ────────────────────────────
  /// Retourne le chemin SVG d'un item depuis son assetPath stocké.
  /// Si le chemin est null ou inconnu : retourne [_kPlaceholderItem].
  static String item(String? assetPath) =>
      assetPath ?? _kPlaceholderItem;

  // ── Héros (assets commissionés — placeholders par défaut) ───────────────
  /// Retourne le chemin SVG d'un héros selon sa classe.
  /// Dégradation propre vers [_kPlaceholderHero] tant que l'asset n'existe pas.
  static String hero(HeroClass cls) =>
      _heroAssets[cls] ?? _kPlaceholderHero;

  // ── Compagnons (assets commissionés — placeholders par défaut) ──────────
  /// Retourne le chemin SVG d'un compagnon selon sa race.
  /// Dégradation propre vers [_kPlaceholderCompanion] tant que l'asset n'existe pas.
  static String companion(String race) =>
      _companionAssets[race] ?? _kPlaceholderCompanion;

  // ── Privé ────────────────────────────────────────────────────────────────
  static const _kPlaceholderItem      = 'assets/items/_placeholder.svg';
  static const _kPlaceholderHero      = 'assets/heroes/_placeholder.svg';
  static const _kPlaceholderCompanion = 'assets/companions/_placeholder.svg';

  /// Rempli au fur et à mesure des commissions (vide = placeholder partout).
  static const Map<HeroClass, String> _heroAssets = {};
  static const Map<String, String>    _companionAssets = {};
}

enum HeroClass { warrior, mage, bard, monk }
```

**Consommateurs à mettre à jour :**

- `ItemIcon` (`lib/ui/widgets/common/item_icon.dart:79`) : remplacer `SvgPicture.asset(item.assetPath!)` par `SvgPicture.asset(AssetResolver.item(item.assetPath))`.
- `item_factory.dart` et `craft_service.dart` : conserver les chemins hardcodés comme valeurs de `assetPath` dans le JSON — ils restent valides et passent par `AssetResolver.item()`. Pas de modification du domaine pour les items existants.
- `HeroAvatar` (P4) : consommera `AssetResolver.hero(cls)` et `AssetResolver.companion(race)`.

**Assets placeholder à créer :** trois SVGs minimalistes (carré grisé + point d'interrogation) dans `assets/items/`, `assets/heroes/`, `assets/companions/`. Ce ne sont pas des assets artistiques — juste des rectangles SVG fonctionnels.

### Alternatives écartées

- **Conserver les chemins hardcodés, gérer les absences dans chaque widget** : chaque nouveau type de widget devrait réimplémenter la logique de fallback. Pas extensible.
- **Injecter `AssetResolver` comme dépendance dans le domaine** : violerait la règle d'isolation du domaine (le domaine ne doit pas dépendre de la présentation/utils). `AssetResolver` vit dans `lib/utils/`, consommé uniquement par la couche UI.
- **Générer les chemins via `build_runner`** : ajoute une dépendance build inutile. Le catalogue d'items est connu statiquement ; une map Dart suffit.

### Impact MVVM

P2 est additif. `ItemIcon` est le seul call site à modifier. Aucun ViewModel n'est impacté. Les chemins existants dans `item_factory.dart` restent en place (ils fonctionnent).

### Stratégie de test

- Test unitaire `AssetResolver.item(null)` → retourne `_kPlaceholderItem`.
- Test `AssetResolver.hero(HeroClass.warrior)` quand `_heroAssets` est vide → retourne `_kPlaceholderHero`.
- Widget test `ItemIcon` : item avec `assetPath = null` → affiche l'icône Material fallback (comportement déjà existant, ne change pas).

### Risques

- **Oubli d'un call site `SvgPicture.asset()` direct** : grep `SvgPicture.asset` après la migration. Un seul call site actuel (`item_icon.dart:80`).
- **Placeholder SVG absent au premier lancement** : flutter analyze détecte les assets manquants référencés dans `pubspec.yaml`. Les placeholders doivent être déclarés dans `pubspec.yaml` dès la création.

---

## Phase P3 — GameEventBus : découplage métier/animation

### Problème

Le métier et l'UI sont couplés au point d'émission de feedback. `AppNotification.show(context, ...)` est appelé 20+ fois directement depuis les pages. `showCatReactionOverlay(...)` est appelé dans `quest_validation_page.dart:239` dans la séquence post-validation. Ce couplage rend impossible :

- L'ajout de son/haptique sans modifier chaque call site.
- Le test des feedbacks sans l'arbre de widgets complet.
- Le remplacement de `AppNotification` par Lottie/Rive sans réécrire 20 fichiers.

### Décision

Créer `GameEventBus` en `lib/domain/services/game_event_bus.dart` : singleton `StreamController.broadcast()` émettant un `GameEvent` enum. **Le domaine émet, les animations consomment via des tables de correspondance.** La couche de présentation s'abonne dans `initState` / `dispose`.

**Interfaces Dart proposées :**

```dart
// lib/domain/services/game_event_bus.dart
enum GameEvent {
  questCompleted,
  levelUp,
  itemDropped,
  achievementUnlocked,
  gachaReveal,
  currencyGained,
  questMissed,
}

/// Singleton — une seule instance par session applicative.
/// Pattern identique à onSignedIn/onSignedOut d'AuthViewModel.
class GameEventBus {
  GameEventBus._();
  static final GameEventBus instance = GameEventBus._();

  final _ctrl = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get stream => _ctrl.stream;

  /// Le domaine appelle emit(). Jamais un widget, jamais un asset.
  void emit(GameEvent event) => _ctrl.add(event);

  /// Appelé uniquement depuis main() au teardown (tests d'intégration).
  void dispose() => _ctrl.close();
}
```

**Table événement → animation (placeholder par défaut) :**

| Événement | Animation cible | Placeholder implémenté dans P3 |
|---|---|---|
| `questCompleted` | `showCatReactionOverlay` + `/rewards` | Conserver l'appel existant, déclenché par l'abonné |
| `levelUp` | burst doré + scale `elasticOut` | `AppNotification.show` avec icône ⬆ |
| `itemDropped` | révélation item (scale `elasticOut`) | `AppNotification.show` avec nom de l'item |
| `achievementUnlocked` | bannière + particules | `AppNotification.show` existant |
| `gachaReveal` | `_revealController` existant | flash (déjà local à la page) |
| `currencyGained` | `_AnimatedCounter` | incrément instantané (`AppNotification`) |
| `questMissed` | flash rouge + shake | `AppNotification.show` rouge existant |

**Table événement → son (placeholder : silence) :** aucun package audio n'est installé. La table existe mais toutes les entrées sont des no-op. Câbler le son = ajouter le package `audioplayers` + remplir la table sans toucher le domaine.

**Ordre de migration des call sites :**

1. Créer `GameEventBus` (singleton, 0 abonné — pas de régression).
2. Émettre `GameEvent.questCompleted` depuis `CompleteQuestUseCase` (ou `QuestViewModel.completeQuest`).
3. Émettre `GameEvent.levelUp` depuis `PlayerViewModel.addExperience` si `levelsGained > 0`.
4. Émettre `GameEvent.questMissed` depuis `DailyResetUseCase`.
5. Dans `SanctuaryPage` et `QuestValidationPage` : s'abonner au bus et rerouter les `AppNotification.show` correspondants via la table. Supprimer les appels directs au fur et à mesure.

**Règle stricte :** le domaine (`domain/`, `presentation/use_cases/`) importe `GameEvent`/`GameEventBus`. Il n'importe **jamais** un widget (`AppNotification`, `showCatReactionOverlay`) ni un asset.

### Alternatives écartées

- **InheritedWidget pour les événements** : synchrone, pas adapté aux streams d'événements ponctuels.
- **BLoC/Cubit** : sur-ingénierie pour un bus d'événements simples. Le pattern `StreamController.broadcast()` est déjà la convention dans `AuthViewModel`.
- **Migrer tous les call sites en une seule PR** : trop risqué. Migration progressive avec garde de fallback (le bus sans abonné = aucun effet, les appels directs continuent à fonctionner pendant la migration).

### Impact MVVM

P3 est additif. Les appels directs existants (`AppNotification.show`, `showCatReactionOverlay`) restent en place pendant la migration. Chaque call site est migré individuellement et le comportement est identique (seul le chemin change).

### Stratégie de test

- Test unitaire `GameEventBus` : émettre un événement, vérifier qu'un abonné le reçoit.
- Test `PlayerViewModel.addExperience` avec level-up : vérifier `GameEventBus.instance.stream` reçoit `GameEvent.levelUp` (injecter un bus de test via override ou refactoring minime).
- Test `DailyResetUseCase` avec quêtes manquées : vérifier `GameEvent.questMissed` émis.

### Risques

- **Double feedback pendant la migration** : si un call site émet via le bus ET conserve l'appel direct `AppNotification.show`, l'utilisateur voit deux notifications. Mitigation : supprimer l'appel direct immédiatement après avoir ajouté l'émission bus + l'abonné.
- **Abonné non dispose** : fuites mémoire si `StreamSubscription` non annulée dans `dispose()`. Convention : toujours stocker dans `StreamSubscription? _sub` + `_sub?.cancel()` dans `dispose()`.
- **Bus non initialisé avant le premier événement** : le singleton est créé à l'import. Pas de risque d'accès avant initialisation.

---

## Phase P4 — Widget HeroAvatar en couches, câblé dans la navigation réelle

### Problème

La `AvatarPage` (`lib/ui/pages/avatar/avatar_page.dart:100`) affiche un `Container` circulaire avec l'initiale de l'email — un placeholder de développement. Les slots RPG héros (`EquipmentViewModel._equipped` : 5 slots arme/armure/casque/bottes/anneau) sont rendus en texte plat. Il n'existe aucun widget de personnage héros.

La direction produit veut des héros humanoïdes à classes (Guerrier, Mage, Barde, Moine). Les vrais assets viendront d'une commission humaine (Noyuss). Le travail de P4 est la **tuyauterie** : le widget en couches câblé au vrai flux de données, prêt à recevoir les vrais assets via `AssetResolver` (P2).

**Paco n'est pas un héros jouable.** Paco = mascotte/MougiBot. Le `CatWidget` (Mougi) et le `HeroAvatar` (héros joueur) sont deux widgets distincts, sans lien stylistique.

### Décision

Créer `HeroAvatar` en `lib/ui/widgets/fantasy/hero_avatar.dart` : widget en couches `Stack` + `CustomPainter` (silhouette héros placeholder) + calques d'équipement, animé par un `AnimationController` idle (idle float, 4 s, repeat/reverse — différent du sway du chat pour éviter la confusion visuelle).

**Architecture en couches (ordre de dessin) :**

```
Stack (HeroAvatar)
  ├── [0] Fond/aura d'équipement (BoxDecoration selon rareté dominante)
  ├── [1] Silhouette héros (CustomPaint — _HeroPainter, classe comme paramètre)
  ├── [2] Couche armure (SvgPicture via AssetResolver.hero(cls), placeholder si absent)
  ├── [3] Couche arme (SvgPicture via AssetResolver.hero(cls))
  ├── [4] Couche casque
  ├── [5] Couche bottes
  ├── [6] Couche anneau (badge dans un corner)
  └── [7] Badge niveau (Positioned top-right)
```

**Signature proposée :**

```dart
// lib/ui/widgets/fantasy/hero_avatar.dart
class HeroAvatar extends StatefulWidget {
  final HeroClass heroClass;          // Guerrier, Mage, Barde, Moine
  final Map<EquipmentSlot, Item?> equipped; // de EquipmentViewModel.equipped
  final int level;
  final double size;

  const HeroAvatar({
    super.key,
    required this.heroClass,
    required this.equipped,
    required this.level,
    this.size = 200,
  });
}
```

**Câblage dans la navigation réelle :**

`HeroAvatar` s'insère dans `AvatarPage` (`lib/ui/pages/avatar/avatar_page.dart`) pour remplacer `_AvatarHeader`. La `AvatarPage` est accessible via la route `/avatar` (`app.dart:113`) poussée en route secondaire depuis `ProfilePage`. Elle consomme `EquipmentViewModel` (déjà dans le provider tree) et `PlayerViewModel`. Aucun VM orphelin.

**`HeroClass` :** choisi par l'utilisateur à l'onboarding (chantier à définir en P4b) ou défini par défaut (`warrior`). Persisté dans Hive `settings` via une clé `hero_class_$userId`. Pour P4 initial : valeur par défaut fixe (`HeroClass.warrior`).

**Placeholder `_HeroPainter` :** silhouette géométrique simple (rectangle tronqué épaules larges + rectangle tête) sans détail artistique. Pas un personnage AI-généré. Remplacé par les vrais assets dès que `AssetResolver._heroAssets[cls]` est rempli.

### Alternatives écartées

- **Adapter `CatWidget` pour les héros** : le `CatWidget` est spécifique à Mougi (anatomie chat, moods, couleurs de pelage). Réutiliser son code créerait une confusion stylistique entre Mougi et les héros. Interdit par la contrainte Paco.
- **Utiliser un plugin Spine/Rive pour les héros** : Rive n'est pas installé, les assets n'existent pas, et le budget technique est limité pour la certification Bloc 1. Réservé post-MVP.
- **VM `HeroViewModel` dédié** : les données héros viennent de `EquipmentViewModel` (slots) et `PlayerViewModel` (niveau, classe). Pas de logique métier spécifique au héros qui justifierait un VM supplémentaire. `HeroAvatar` consomme directement les objets passés en paramètre (`equipped`, `level`).

### Impact MVVM

P4 est additif. `AvatarPage` remplace `_AvatarHeader` par `HeroAvatar`. `EquipmentViewModel` et `PlayerViewModel` ne sont pas modifiés. `AssetResolver` (P2) est déjà en place.

### Stratégie de test

- Widget test `HeroAvatar` avec `equipped` vide → affiche le placeholder sans erreur.
- Widget test avec item équipé (rarité `epic`) → l'aura de fond reflète `AppColors.rarityEpic`.
- `flutter analyze` 0 erreur après l'ajout.

### Risques

- **Assets placeholder manquants dans `pubspec.yaml`** : `SvgPicture.asset()` sur un chemin absent lance une exception en debug. Mitigation : créer les SVGs placeholder et les déclarer dans `pubspec.yaml` avant tout widget test.
- **`HeroClass` non persisté en P4 initial** : la classe par défaut (`warrior`) est hardcodée. Acceptable pour P4 initial ; la persistance est P4b.

---

## Ordre de migration et dépendances inter-phases

```
P1 (auth lifecycle)          — prérequis aucun ; à implémenter en premier (risque runtime actif)
  └─> P2 (AssetResolver)     — prérequis : P1 terminé et projet vert ; indépendant de P3/P4
        └─> P4 (HeroAvatar)  — prérequis : P2 (AssetResolver.hero() disponible)
P3 (GameEventBus)            — peut commencer en parallèle de P2 ; prérequis P1
```

**P1 doit être validé et projet vert avant de démarrer P2 ou P3.** `flutter analyze 0` + tests passants après chaque phase.

---

## Conséquences globales

**Positif :**
- Fin du bug "quêtes du user précédent visibles au sign-in sur KeepAlivePage".
- Extensibilité audio/Lottie sans modifier le domaine (P3).
- Intégration des vrais assets héros/compagnons sans modifier `item_factory.dart` (P2).
- Architecture cohérente : tous les VMs per-user suivent le même contrat d'abonnement.

**Négatif / dette acceptée :**
- Les clés Hive fixes (`InventoryViewModel`, `EquipmentViewModel`, `PlayerViewModel`) ne sont pas migrées vers des clés per-user en P1. Le risque de contamination inter-user sur un seul appareil est documenté et reporté (P1b).
- `ActivityLogService` reste un service statique. La dette de ne pas l'instancier dans le provider tree est maintenue — le clearLog() dans `_purgeHiveData()` est un correctif local, pas une refonte.
- La migration P3 des 20+ call sites `AppNotification.show` est progressive. Pendant la migration, coexistence des deux mécanismes (appels directs + bus). Durée estimée : plusieurs PRs.
- `HeroClass` sans persistence en P4 initial : la valeur par défaut `warrior` sera visible par tous les utilisateurs jusqu'à P4b.
