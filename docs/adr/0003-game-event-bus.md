# 0004. HeroAvatar : widget de héros en couches, câblé dans la navigation réelle

- **Statut** : Proposé
- **Date** : 2026-07-01

---

## Contexte

La page Avatar n'affiche qu'un cercle avec l'initiale de l'utilisateur. Les slots d'équipement existent
dans le ViewModel mais ne sont rendus nulle part.

Prérequis : [ADR 0002](0002-asset-resolver.md), pour disposer de la résolution d'assets du héros.

## Contraintes de projet rappelées

- **Paco** : mascotte et visage de MougiBot uniquement. Ni héros jouable, ni compagnon.
- **Héros** : humanoïdes à classes (Guerrier, Mage, Barde, Moine), distincts de Mougi et des compagnons.
- **Compagnons** : entités RPG obtenues par gacha, distinctes des héros, sans lien stylistique avec Paco.
- Les assets définitifs proviennent d'une commission humaine. Aucun asset généré pour les héros et compagnons.
- Anti-pattern interdit : un ViewModel qui reçoit un `String id` puis fait un `firstWhere` sur un snapshot mémoire périmé. Toujours passer l'objet complet.

---

## Inventaire factuel, rendu de l'avatar et du héros

### Tableau C : Rendu avatar/héros actuel

| Entité | Fichier | Rendu actuel |
|---|---|---|
| **Mougi (compagnon)** | `lib/ui/widgets/cat/cat_widget.dart:20` | `Stack` + `CustomPainter` (`_CatPainter`) + couches widget (aura, tenue, pantalon, chaussures, accessoire, chapeau emoji). AnimationControllers : `_swayCtrl` (3 s, repeat/reverse) + `_auraCtrl` (2 s, repeat/reverse). C'est la seule entité avec un rendu graphique natif. |
| **Héros (page Avatar)** | `lib/ui/pages/avatar/avatar_page.dart:100` | `Container` circulaire avec initiale de l'email en `Text`. Aucun `CustomPainter`, aucune image, aucun widget de personnage. C'est un placeholder basique. |
| **Slots cosmétiques RPG** | `lib/presentation/view_models/equipment_view_model.dart:13` | Existent dans `EquipmentViewModel` (`_equipped` 5 slots + `_cosmetics` map) mais ne sont rendus nulle part sous forme graphique, seulement listés en texte dans `_EquipmentSection` d'`AvatarPage`. |

---

### Problème

La `AvatarPage` (`lib/ui/pages/avatar/avatar_page.dart:100`) affiche un `Container` circulaire avec l'initiale de l'email, un placeholder de développement. Les slots RPG héros (`EquipmentViewModel._equipped` : 5 slots arme/armure/casque/bottes/anneau) sont rendus en texte plat. Il n'existe aucun widget de personnage héros.

La direction produit veut des héros humanoïdes à classes (Guerrier, Mage, Barde, Moine). Les vrais assets viendront d'une commission humaine (Noyuss). Le travail de P4 est la **tuyauterie** : le widget en couches câblé au vrai flux de données, prêt à recevoir les vrais assets via `AssetResolver` (P2).

**Paco n'est pas un héros jouable.** Paco = mascotte/MougiBot. Le `CatWidget` (Mougi) et le `HeroAvatar` (héros joueur) sont deux widgets distincts, sans lien stylistique.

### Décision

Créer `HeroAvatar` en `lib/ui/widgets/fantasy/hero_avatar.dart` : widget en couches `Stack` + `CustomPainter` (silhouette héros placeholder) + calques d'équipement, animé par un `AnimationController` idle (idle float, 4 s, repeat/reverse, différent du sway du chat pour éviter la confusion visuelle).

**Architecture en couches (ordre de dessin) :**

```
Stack (HeroAvatar)
  ├── [0] Fond/aura d'équipement (BoxDecoration selon rareté dominante)
  ├── [1] Silhouette héros (CustomPaint, _HeroPainter, classe comme paramètre)
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

---

## Conséquences

**Négatif et dette acceptée**

- Sans persistance de la classe du héros dans la première itération, la valeur par défaut sera visible par tous les utilisateurs jusqu'à une itération ultérieure.
