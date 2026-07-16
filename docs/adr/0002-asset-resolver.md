# 0002. AssetResolver : placeholders par défaut et contrat vers les assets définitifs

- **Statut** : Proposé
- **Date** : 2026-07-01

---

## Contexte

Les chemins d'assets sont aujourd'hui codés en dur et dispersés. Cette décision prépare l'intégration des
assets définitifs, issus d'une commission humaine, sans réécrire le domaine.

Prérequis : [ADR 0001](0001-cycle-de-vie-authentification.md) implémenté et projet vert.

## Contraintes de projet rappelées

- **Paco** : mascotte et visage de MougiBot uniquement. Ni héros jouable, ni compagnon.
- **Héros** : humanoïdes à classes (Guerrier, Mage, Barde, Moine), distincts de Mougi et des compagnons.
- **Compagnons** : entités RPG obtenues par gacha, distinctes des héros, sans lien stylistique avec Paco.
- Les assets définitifs proviennent d'une commission humaine. Aucun asset généré pour les héros et compagnons.
- Anti-pattern interdit : un ViewModel qui reçoit un `String id` puis fait un `firstWhere` sur un snapshot mémoire périmé. Toujours passer l'objet complet.

---

## Inventaire factuel, références d'assets codées en dur

### Tableau B : Références d'assets hardcodées

| Fichier | Lignes | Type | Comptage | Statut |
|---|---|---|---|---|
| `lib/domain/services/item_factory.dart` | 22-393 | `assets/items/*.svg` | 46 chemins | Les 46 fichiers SVG existent dans `assets/items/` |
| `lib/domain/services/craft_service.dart` | 29, 48 | `assets/items/*.svg` | 2 chemins | Fichiers présents |
| `assets/animations/` |, | JSON Lottie | 3 fichiers orphelins (`loading.json`, `rpg_loading.json`, `rpg_logo.json`) | Aucun widget ne les charge ; package `lottie` absent du `pubspec.yaml` |

Aucune classe `AssetResolver` n'existe. Les chemins SVG items sont passés en `String` dans le modèle `Item` (champ `assetPath`, `data/models/item_model.dart:25`) puis consommés par `ItemIcon` (`lib/ui/widgets/common/item_icon.dart:80`) via `SvgPicture.asset()`. `ItemIcon` dispose déjà d'un fallback `_fallbackIcon()` (ligne 88) mais celui-ci est local au widget, pas une stratégie globale pilotable.

---

### Problème

48 chemins d'assets sont hardcodés dans la couche domaine (`item_factory.dart`, `craft_service.dart`). Quand les vrais assets héros/compagnons seront commissionés (Noyuss), ils devront être intégrés sans modifier le domaine. Actuellement, tout ajout d'un nouveau type visuel (héros, compagnon) nécessiterait de modifier `item_factory.dart` directement.

De plus, le widget `ItemIcon` (`lib/ui/widgets/common/item_icon.dart:80`) fait `SvgPicture.asset(item.assetPath!)` sans passer par une couche d'indirection : si un chemin devient invalide, l'erreur est silencieuse (fallback local) mais non observable depuis le domaine.

### Décision

Créer `AssetResolver` en `lib/utils/asset_resolver.dart` : service statique (sans état) qui centralise la résolution de chemins d'assets. Le domaine ne connaît que des **identifiants logiques** ; `AssetResolver` mappe vers le chemin physique ou vers un placeholder.

**Contrat Dart proposé :**

```dart
/// Résout un chemin d'asset depuis un identifiant logique.
/// Retourne toujours un chemin valide : vrai asset si présent, placeholder sinon.
/// Le domaine n'importe jamais ce service, seule la couche UI l'utilise.
abstract final class AssetResolver {

  // ── Items (déjà présents dans assets/items/) ────────────────────────────
  /// Retourne le chemin SVG d'un item depuis son assetPath stocké.
  /// Si le chemin est null ou inconnu : retourne [_kPlaceholderItem].
  static String item(String? assetPath) =>
      assetPath ?? _kPlaceholderItem;

  // ── Héros (assets commissionés, placeholders par défaut) ───────────────
  /// Retourne le chemin SVG d'un héros selon sa classe.
  /// Dégradation propre vers [_kPlaceholderHero] tant que l'asset n'existe pas.
  static String hero(HeroClass cls) =>
      _heroAssets[cls] ?? _kPlaceholderHero;

  // ── Compagnons (assets commissionés, placeholders par défaut) ──────────
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
- `item_factory.dart` et `craft_service.dart` : conserver les chemins hardcodés comme valeurs de `assetPath` dans le JSON, ils restent valides et passent par `AssetResolver.item()`. Pas de modification du domaine pour les items existants.
- `HeroAvatar` (P4) : consommera `AssetResolver.hero(cls)` et `AssetResolver.companion(race)`.

**Assets placeholder à créer :** trois SVGs minimalistes (carré grisé + point d'interrogation) dans `assets/items/`, `assets/heroes/`, `assets/companions/`. Ce ne sont pas des assets artistiques, juste des rectangles SVG fonctionnels.

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

---

## Conséquences

**Positif**

- Intégration des assets définitifs de héros et compagnons sans modifier `item_factory.dart`.
- Stratégie de repli globale et pilotable, au lieu d'un repli local au widget `ItemIcon`.
