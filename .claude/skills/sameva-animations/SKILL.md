---
name: sameva-animations
description: Patterns d'animation Flutter (Lottie/Rive) et mapping GameEventBus pour Sameva. Déclenche sur : "animation", "Lottie", "Rive", "glow", "shimmer", "GameEventBus", "AnimationController", "feedback", "confetti", "montée de niveau", "level-up", "SFX", "son", "particules".
---

# Animations & feedbacks — Sameva

Décrit ce qui **existe réellement** dans le code, puis la **convention cible**
du futur GameEventBus. Inventaire dérivé du code (`lib/`) ; revérifier avant de
s'appuyer sur un détail, les chemins peuvent bouger.

## État réel (à connaître avant d'ajouter quoi que ce soit)

- **Lottie : non installé.** Pas de package `lottie` dans `pubspec.yaml`. Les
  trois JSON sous `assets/animations/` (`loading.json`, `rpg_loading.json`,
  `rpg_logo.json`) sont **orphelins** : aucun widget ne les charge. Le commentaire
  « animation Lottie » dans `cat_mood_service.dart` est trompeur — `getIdleAnimation()`
  retourne juste une chaîne de mood (`'cat_happy'`…) consommée par le `CustomPainter`
  de `CatWidget`, pas une anim Lottie.
- **Rive : absent.** Pas de package `rive`, pas de fichier `.riv`.
- **Dossiers vides** : `lib/ui/widgets/magical/`, `animations/`, `transitions/`,
  `logo/`, `figma/` existent mais ne contiennent **aucun** `.dart`. Les effets
  « magical » (glow, aura, particules) vivent directement dans les pages ou dans
  `lib/ui/widgets/cat/`.
- **Son / haptique : absents.** Aucun package audio (`audioplayers`, `just_audio`…),
  zéro `HapticFeedback`, zéro `SystemSound`. `flutter_local_notifications` existe
  mais c'est de la notif système planifiée, pas du SFX in-app.

## Patterns d'animation existants (tout en `AnimationController`)

Le projet anime **exclusivement** via `AnimationController` + `CustomPaint`/
`Transform`/transitions. Patterns de référence :

| Pattern | Fichier | Ce qu'il fait |
|---|---|---|
| Idle pulsation / sway | `lib/ui/widgets/cat/cat_widget.dart` | `_swayCtrl` (rotation ±0,04 rad), `_auraCtrl` (pulse opacité aura) en repeat/reverse |
| Particules « confetti » | `lib/ui/pages/rewards/rewards_page.dart` | `_particleCtrl` (3 s, repeat) drive `_ParticlePainter` (30 cercles flottants) |
| Compteur animé | `lib/ui/pages/rewards/rewards_page.dart` | `_countCtrl` (easeOutCubic) → `_AnimatedCounter` de 0 vers XP/or |
| Overlay notif (slide+fade) | `lib/ui/utils/app_notification.dart` | `_controller` 300 ms : `SlideTransition` depuis le haut + `FadeTransition` |
| Révélation gacha | `lib/ui/pages/invocation/invocation_page.dart` | `_pulseController` (idle scale) + `_revealController` (`TweenSequence` au tirage) |
| Pop réaction chat | `lib/ui/widgets/cat/cat_reaction_overlay.dart` | `_ctrl` 500 ms `elasticOut` (scale) + `easeIn` (fade), auto-dismiss 2 s |
| Révélation récompense | `lib/ui/pages/quest/quest_validation_page.dart` | `_scale` (elasticOut) + `_glow` (boxShadow or) |
| Glow d'étape | `lib/ui/pages/onboarding/onboarding_page.dart` | glow de l'indicateur d'étape active |

**Convention de fait** : durées courtes (300–1200 ms) pour le feedback, repeat/
reverse pour l'idle ; `elasticOut` pour les « pop » de récompense, `easeOut*`
pour les compteurs/glow ; toujours `dispose()` les contrôleurs (les mini-jeux en
ont jusqu'à 16, tous disposés).

## Feedbacks déclenchés aujourd'hui (impératif, au niveau UI)

Aujourd'hui le feedback est appelé **directement** depuis l'UI, sans bus :

- `AppNotification.show(...)` — mécanisme principal (20+ call sites : pénalités HP,
  nouveau boss, succès débloqués dans `sanctuary_page.dart` `_load()`, erreurs de
  validation, résultats gacha/marché).
- `showCatReactionOverlay(...)` puis `Navigator.pushNamed('/rewards', arguments: RewardsArgs(...))`
  dans la séquence post-validation de quête (`quest_validation_page.dart`).

Conséquence : le métier et l'UI sont couplés au point d'émission. C'est ce que le
GameEventBus doit découpler.

## Convention cible : GameEventBus

> **N'existe pas encore.** Les seuls `StreamController.broadcast()` actuels sont
> `onSignedIn`/`onSignedOut` dans `AuthViewModel` (auth, pas jeu).

Principe : **le métier émet un évènement nommé ; il ne connaît ni l'animation ni
le son.** Une couche de présentation s'abonne au bus et fait la correspondance
évènement → anim et évènement → son. Ça permet d'ajouter/retirer un feedback sans
toucher au domaine, et de brancher Lottie/Rive/audio plus tard sans réécrire les
appels.

```dart
// Domaine : émet, point final.
enum GameEvent { questCompleted, levelUp, itemDropped, achievementUnlocked,
                 gachaReveal, currencyGained, questMissed }

// bus broadcast (même pattern que onSignedOut)
class GameEventBus {
  final _ctrl = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get stream => _ctrl.stream;
  void emit(GameEvent e) => _ctrl.add(e);
}
```

**Table évènement → animation** (placeholder par défaut : flash/scale) :

| Évènement | Animation cible | Placeholder par défaut |
|---|---|---|
| `levelUp` | burst + glow doré | scale `elasticOut` |
| `questCompleted` | `showCatReactionOverlay` + récompense | scale + fade |
| `itemDropped` | révélation item (cf. quest_validation) | scale `elasticOut` |
| `achievementUnlocked` | bannière + particules | `AppNotification.show` |
| `gachaReveal` | `_revealController` existant | flash |
| `currencyGained` | compteur animé (`_AnimatedCounter`) | incrément instantané |
| `questMissed` | shake / flash rouge | flash |

**Table évènement → son** (placeholder par défaut : bip ou rien — pas d'audio
installé aujourd'hui) :

| Évènement | Son cible | Placeholder |
|---|---|---|
| `levelUp` | jingle montée de niveau | aucun |
| `questCompleted` | ding succès | aucun |
| `itemDropped` | son selon rareté | aucun |
| `achievementUnlocked` | fanfare | aucun |
| `gachaReveal` | whoosh + révélation | aucun |
| `currencyGained` | tintement pièces | aucun |
| `questMissed` | son d'échec | aucun |

**Règles** :
- Le domaine importe `GameEvent`/`GameEventBus`, **jamais** un widget ni un asset.
- Toute entrée de table a un **fallback** : un évènement sans anim/son mappé tombe
  sur le placeholder (flash/scale, bip ou silence), jamais une exception.
- Migrer progressivement les call sites impératifs (`AppNotification.show`,
  `showCatReactionOverlay`) vers des `emit(...)` au fur et à mesure.
- Avant d'introduire Lottie/Rive ou un package audio : ajouter la dépendance au
  `pubspec.yaml` et brancher les assets orphelins ou les supprimer.
