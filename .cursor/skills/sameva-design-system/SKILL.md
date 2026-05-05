---
name: sameva-design-system
description: Applique le design system Sameva (couleurs, polices, rareté, widgets). Utiliser lors de la création ou modification d'écrans, de widgets, de thème, ou quand l'utilisateur travaille dans lib/ui/.
---

# Design system Sameva

## Couleurs (AppColors)

- **Primaire** : `AppColors.primaryViolet` (#805AD5), `primaryVioletLight` (#B794F4), `primaryVioletGlow` (#E9D5FF)
- **Accent** : `AppColors.gold` (#FDE68A), `goldDark` (#F59E0B)
- **Fonds** : `backgroundNightCosmos` (#120A2E), `backgroundDarkPanel` (#1A0F3C)
- **Accents métier** : `crystalBlue`, `mintMagic`, `coralRare`
- **Texte** : `textPrimary`, `textSecondary`, `textMuted` ; clair : `cream100`, `parchment`

Toujours importer et utiliser `AppColors` depuis `ui/theme/app_colors.dart`. Ne pas définir de couleurs en dur pour l'UI.
Les anciens alias (`primaryTurquoise`, `backgroundNightBlue`, etc.) existent pour compatibilité, mais les nouveaux écrans doivent privilégier les noms actuels.

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
Utiliser `withValues(alpha: x)` au lieu de `withOpacity()`.

## Fichiers de référence

- `lib/ui/theme/app_colors.dart`
- `lib/ui/theme/app_styles.dart`
- `lib/ui/theme/app_theme.dart`
