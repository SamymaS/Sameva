# Structure des Assets Sameva

Cette structure suit les spécifications du cahier des charges Sameva.

## Organisation des dossiers

```
assets/
├── animations/
│   ├── rive/          # Animations Rive (avatar, effets spéciaux)
│   └── lottie/        # Animations Lottie (UI, transitions, effets)
├── audio/
│   ├── music/         # Musiques d'ambiance et thèmes
│   └── sfx/           # Effets sonores (interactions, invocations, etc.)
├── fonts/             # Polices personnalisées (Cinzel, Poppins, etc.)
├── images/
│   ├── avatars/       # Avatars et personnages
│   ├── backgrounds/  # Fonds de scène (sanctuaire, marché, etc.)
│   ├── items/         # Objets et items du marché
│   ├── companions/    # Compagnons et familiers
│   ├── auras/         # Auras et effets visuels
│   └── icons/         # Icônes vectorielles (SVG)
└── minigames/
    ├── sprites/       # Sprites pour mini-jeux (Flame)
    ├── tiles/         # Tilesets pour mini-jeux
    └── backgrounds/   # Fonds pour mini-jeux
```

## Référence des assets par page

Consulter le document `SAMEVA - Tableau des Assets à Produire.md` pour la liste complète des assets nécessaires.

## Notes

- Tous les assets sont chargés récursivement depuis les dossiers principaux définis dans `pubspec.yaml`
- Les formats recommandés :
  - Images : WebP pour les backgrounds, PNG pour les sprites/items
  - Animations : Rive (.riv) pour les animations complexes, Lottie (.json) pour les effets UI
  - Audio : MP3 pour la musique, OGG pour les SFX
  - Fonts : TTF/OTF

