# 0003. GameEventBus : découplage entre logique métier et animations

- **Statut** : Proposé
- **Date** : 2026-07-01

---

## Contexte

Les déclencheurs d'animation sont appelés directement depuis la logique métier, ce qui empêche d'ajouter
son et haptique sans toucher au domaine.

Prérequis : [ADR 0001](0001-cycle-de-vie-authentification.md) implémenté. Peut être mené en parallèle de
l'[ADR 0002](0002-asset-resolver.md).

## Contraintes de projet rappelées

- **Paco** : mascotte et visage de MougiBot uniquement. Ni héros jouable, ni compagnon.
- **Héros** : humanoïdes à classes (Guerrier, Mage, Barde, Moine), distincts de Mougi et des compagnons.
- **Compagnons** : entités RPG obtenues par gacha, distinctes des héros, sans lien stylistique avec Paco.
- Les assets définitifs proviennent d'une commission humaine. Aucun asset généré pour les héros et compagnons.
- Anti-pattern interdit : un ViewModel qui reçoit un `String id` puis fait un `firstWhere` sur un snapshot mémoire périmé. Toujours passer l'objet complet.

---

## Inventaire factuel, déclencheurs d'animation

### Tableau D : Déclencheurs d'animation (couplage actuel)

| Pattern | Fichier | Déclencheur | Type de couplage |
|---|---|---|---|
| Notification slide+fade | `lib/ui/utils/app_notification.dart` | `AppNotification.show(context, ...)`, 20+ call sites dans les pages (`sanctuary_page.dart:60,99,136`, `quest_validation_page.dart:136,270`, `cat_page.dart:87,246,253`, `market_page.dart:291,978,1149`, `invocation_page.dart:214,279,919`, etc.) | Appel impératif UI → animation |
| Réaction chat post-validation | `lib/ui/pages/quest/quest_validation_page.dart:239` | `showCatReactionOverlay(...)` | Appel impératif UI → animation |
| Particules récompenses | `lib/ui/pages/rewards/rewards_page.dart` | `_particleCtrl` local (3 s, repeat) drive `_ParticlePainter` | Local à la page, déclenché au build |
| Compteur animé | `lib/ui/pages/rewards/rewards_page.dart` | `_countCtrl` + `_AnimatedCounter` | Local à la page |
| Révélation gacha | `lib/ui/pages/invocation/invocation_page.dart` | `_pulseController` + `_revealController` | Local à la page |
| Pop réaction chat | `lib/ui/widgets/cat/cat_reaction_overlay.dart` | `_ctrl` 500 ms `elasticOut` | Local au widget overlay |
| Révélation récompense quête | `lib/ui/pages/quest/quest_validation_page.dart:1164` | `_ctrl` AnimationController (ligne 1171) | Local à la page |
| Idle Mougi | `lib/ui/widgets/cat/cat_widget.dart:61` | `_swayCtrl` + `_auraCtrl` en repeat/reverse | Permanent, local au widget |

Aucun `GameEventBus` n'existe. Les seuls `StreamController.broadcast()` présents sont `onSignedIn`/`onSignedOut` dans `AuthViewModel` (auth uniquement).

---

---

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

/// Singleton, une seule instance par session applicative.
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

1. Créer `GameEventBus` (singleton, 0 abonné, pas de régression).
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

---

## Conséquences

**Positif**

- Extensibilité audio et Lottie sans modifier la couche domaine.

**Négatif et dette acceptée**

- La migration des points d'appel existants est progressive : les deux mécanismes coexistent pendant la transition, sur plusieurs pull requests.
