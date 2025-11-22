# Guide d'intégration des mockups Figma dans Sameva

## 📋 Analyse des assets exportés

### Structure des composants React
Les mockups Figma ont été exportés en composants React/TypeScript dans `assets/components/`. Ces fichiers servent de **référence de design** et ne sont pas directement utilisables dans Flutter.

### Composants disponibles
- **UI Components** (`assets/components/ui/`): Composants de base (Button, Card, Badge, Avatar, etc.)
- **Figma Components** (`assets/components/figma/`): Composants spécifiques Figma (ImageWithFallback)

### Palette de couleurs identifiée
D'après `globals.css`, le thème utilise:
- **Primary**: `rgb(120, 80, 150)` - Violet
- **Background**: `#f5f0f5` - Rose pâle
- **Foreground**: `#3c2850` - Violet foncé
- **Accent**: `rgb(200, 180, 220)` - Violet clair
- **Radius**: `1rem` (16px)

## 🎯 Plan d'intégration

### 1. Mise à jour du thème Flutter
Adapter `lib/theme/app_colors.dart` et `lib/theme/app_theme.dart` pour correspondre aux couleurs Figma.

### 2. Création de widgets Flutter équivalents
Créer des widgets Flutter qui reproduisent le style des composants React:
- `FantasyCard` (équivalent à Card)
- `FantasyBadge` (équivalent à Badge)
- `FantasyAvatar` (équivalent à Avatar)
- `FantasyButton` (déjà existant, à améliorer)

### 3. Amélioration des pages existantes
- **HomePage**: Intégrer les assets d'avatar et de background
- **MarketPage**: Utiliser les images d'items depuis `assets/images/items/`
- **InvocationPage**: Ajouter les animations et effets visuels
- **AvatarPage**: Intégrer les assets d'avatars et de customization

### 4. Utilisation des images
Vérifier et utiliser les images dans:
- `assets/images/avatars/` - Pour les avatars
- `assets/images/items/` - Pour les items du marché
- `assets/images/backgrounds/` - Pour les fonds de page
- `assets/images/companions/` - Pour les compagnons
- `assets/images/auras/` - Pour les effets visuels

## 📝 Prochaines étapes

1. ✅ Analyser la structure des composants
2. ✅ Mettre à jour les couleurs du thème
3. ✅ Créer les widgets Flutter équivalents (FantasyCard, FantasyBadge, FantasyAvatar)
4. ✅ Améliorer la page Market avec les nouveaux widgets
5. ⏳ Exporter les images depuis Figma et les placer dans les dossiers appropriés
6. ⏳ Tester et ajuster

## 🎨 Widgets créés

### FantasyCard
**Fichier**: `lib/widgets/figma/fantasy_card.dart`
- Équivalent au composant Card React
- Support pour header, footer, title, description, action
- Style cohérent avec le thème Figma

### FantasyBadge
**Fichier**: `lib/widgets/figma/fantasy_badge.dart`
- Équivalent au composant Badge React
- Variants: default, secondary, destructive, outline
- Support pour icônes

### FantasyAvatar
**Fichier**: `lib/widgets/figma/fantasy_avatar.dart`
- Équivalent au composant Avatar React
- Support pour images avec fallback
- Personnalisable (taille, couleur de fond)

## 📦 Structure des images à exporter depuis Figma

Pour que les pages fonctionnent correctement, vous devez exporter les images depuis Figma et les placer dans les dossiers suivants:

```
assets/images/
├── items/
│   ├── heaume_du_zénith.png
│   ├── épée_légendaire.png
│   ├── bouclier_commun.png
│   └── ... (autres items)
├── avatars/
│   ├── hero_base.png
│   ├── hero_1.png
│   └── ... (autres avatars)
├── backgrounds/
│   ├── market_background.png
│   ├── home_background.png
│   └── ... (autres backgrounds)
├── companions/
│   └── ... (compagnons)
└── auras/
    └── ... (effets visuels)
```

## 🔧 Utilisation des widgets

### Exemple: Utiliser FantasyCard
```dart
FantasyCard(
  title: 'Titre de la carte',
  description: 'Description de la carte',
  child: Text('Contenu de la carte'),
  action: IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
)
```

### Exemple: Utiliser FantasyBadge
```dart
FantasyBadge(
  label: 'EPIC',
  variant: BadgeVariant.default_,
  icon: Icon(Icons.star),
)
```

### Exemple: Utiliser FantasyAvatar
```dart
FantasyAvatar(
  imageUrl: 'assets/images/avatars/hero_base.png',
  size: 60,
  fallbackText: 'H',
)
```

## 🎯 Pages améliorées

### MarketPage
- ✅ Utilise maintenant FantasyCard et FantasyBadge
- ✅ Prête à recevoir les images depuis `assets/images/items/`
- ✅ Style cohérent avec le thème Figma

### Prochaines améliorations
- AvatarPage: Intégrer les avatars depuis `assets/images/avatars/`
- HomePage: Utiliser les backgrounds depuis `assets/images/backgrounds/`
- InvocationPage: Ajouter les effets visuels depuis `assets/images/auras/`

