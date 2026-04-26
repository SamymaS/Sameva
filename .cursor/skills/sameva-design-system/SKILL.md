---
name: sameva-design-system
description: Applique le design system Sameva (couleurs, polices, rareté, widgets). Utiliser lors de la création ou modification d'écrans, de widgets, de thème, ou quand l'utilisateur travaille dans lib/ui/.
---

# Design system Sameva

## Couleurs (AppColors)

- **Primaire** : `AppColors.primaryViolet` (#805AD5), `primaryVioletLight`, `primaryVioletGlow`
- **Accents** : `AppColors.gold`, `goldDark`, `crystalBlue`, `mintMagic`, `coralRare`
- **Fonds** : `backgroundNightCosmos`, `backgroundNightBlue` (alias), `backgroundDeepViolet`, `backgroundDarkPanel`
- **Texte** : `textPrimary`, `textSecondary`, `textMuted` ; clair : `cream100`, `parchment`
- **Compatibilité** : les anciens alias (`primaryTurquoise`, `secondaryViolet`, etc.) existent encore, mais préférer les noms alignés avec la DA actuelle quand du nouveau code est créé.

Toujours importer et utiliser `AppColors` depuis `ui/theme/app_colors.dart`. Ne pas définir de couleurs en dur pour l'UI.

## Rareté (items, équipement)

Utiliser les constantes et helpers :

- `AppColors.rarityCommon` (gris), `rarityUncommon` (vert), `rarityRare` (bleu), `rarityEpic` (violet), `rarityLegendary` (or), `rarityMythic` (rouge)
- `AppColors.getRarityColor(String rarity)` pour une chaîne
- `AppColors.shouldGlow(rarity)` pour savoir si un effet glow est approprié (epic, legendary, mythic)

## Polices

- **Titres fantasy** : MedievalSharp
- **Stats / jeu** : Press Start 2P (pixel)
- **Corps** : Quicksand / Poppins

Styles communs dans `AppStyles` : `titleStyle`, `subtitleStyle`, `radius`, `softShadow`.

## Catégories de widgets

| Dossier | Usage |
|--------|--------|
| **minimalist/** | Composants plats, épurés (boutons, cartes, dock, FAB, panels) |
| **magical/** | Effets glow, particules, fonds animés, hover |
| **fantasy/** | Style RPG (boutons, cartes, champs, thème médiéval) |
| **common/** | Partagés (header, loading, transitions, rarity_border) |

Choisir le dossier en fonction du style de la page (Sanctuaire/Quêtes → souvent minimalist ou magical ; Marché/Invocation → fantasy).

## Material 3

Thèmes light/dark dans `ui/theme/app_theme.dart`. Utiliser le thème via `Theme.of(context)` pour les couleurs schématiques quand c'est cohérent avec le design system.

## Assets visuels

- Style : fantasy RPG sombre / cosmos, effets lumineux et particules sobres.
- PNG pour images, SVG pour icônes vectorielles.
- Placer les fichiers dans `assets/images/`, `assets/icons/` ou le dossier d'assets existant le plus cohérent, puis référencer `pubspec.yaml` si nécessaire.

## Fichiers de référence

- `lib/ui/theme/app_colors.dart`
- `lib/ui/theme/app_styles.dart`
- `lib/ui/theme/app_theme.dart`
