# Guide d'Utilisation des Assets - Sameva

## 📋 Vue d'ensemble

Ce guide explique comment utiliser les assets d'images dans l'application Sameva, en remplacement des emojis.

## 🗂️ Structure des Assets

Les assets sont organisés dans le dossier `assets/images/` :

```
assets/images/
├── avatars/          # Images des personnages/avatars
├── companions/       # Images des familiers/compagnons
├── items/            # Images des objets/équipements
├── auras/            # Images des effets visuels (auras)
├── backgrounds/      # Images de fond pour les pages
├── invocations/      # Images pour les effets d'invocation
└── icons/            # Icônes diverses
```

## 🎨 Utilisation des Widgets

### 1. AvatarImageWidget - Pour les avatars

Remplace les emojis d'avatar par de vraies images.

```dart
AvatarImageWidget(
  avatarId: 'hero_base',  // ID de l'avatar (sans extension)
  size: 80,
  showBorder: true,
)
```

**Chemins automatiques** : `assets/images/avatars/{avatarId}.png`

### 2. CompanionImageWidget - Pour les familiers

Remplace les emojis de familier par de vraies images.

```dart
CompanionImageWidget(
  companionId: 'companion_1',  // ID du familier
  size: 60,
  animated: false,
)
```

**Chemins automatiques** : `assets/images/companions/{companionId}.png`

### 3. ItemImageWidget - Pour les objets

Affiche les images d'objets avec support de la rareté.

```dart
ItemImageWidget(
  itemId: 'sword_epic',
  size: 64,
  rarityColor: AppColors.rarityEpic,  // Couleur de bordure selon rareté
)
```

**Chemins automatiques** : `assets/images/items/{itemId}.png`

### 4. AssetImageWidget - Widget générique

Widget de base pour tous les assets avec fallback automatique.

```dart
AssetImageWidget(
  imagePath: 'assets/images/avatars/hero_base.png',
  size: 100,
  fallbackIcon: Icons.person,
  fallbackColor: AppColors.primaryTurquoise,
)
```

## 🔧 AssetsManager - Gestionnaire centralisé

Le `AssetsManager` fournit des méthodes pour obtenir les chemins des assets :

```dart
import 'package:sameva/utils/assets_manager.dart';

// Avatars
String avatarPath = AssetsManager.getAvatarPath('hero_base');
// Retourne: 'assets/images/avatars/hero_base.png'

// Familiers
String companionPath = AssetsManager.getCompanionPath('companion_1');
// Retourne: 'assets/images/companions/companion_1.png'

// Items
String itemPath = AssetsManager.getItemPath('Épée Légendaire');
// Retourne: 'assets/images/items/epee_legendaire.png' (normalisé)
```

## 📝 Migration depuis les Emojis

### Avant (avec emoji)
```dart
MagicalAvatar(
  emoji: '🧙‍♀️',
  companionEmoji: '🦊',
)
```

### Après (avec assets)
```dart
MagicalAvatar(
  avatarId: 'hero_base',
  companionId: 'companion_1',
)
```

## 🎯 Exemples d'Utilisation

### Dans SanctuaryPage
```dart
Consumer<EquipmentProvider>(
  builder: (context, equipmentProvider, _) {
    final equipment = equipmentProvider.playerEquipment;
    return MagicalAvatar(
      avatarId: equipment?.outfitId ?? 'hero_base',
      companionId: equipment?.companionId ?? 'companion_1',
      size: 140,
      showMagicCircle: true,
    );
  },
)
```

### Dans InventoryPage
```dart
ItemImageWidget(
  itemId: item.id,
  itemName: item.name,
  size: 64,
  rarityColor: _getRarityColor(item.rarity),
)
```

### Dans AvatarPage
```dart
AvatarImageWidget(
  avatarId: equipment?.outfitId,
  size: 120,
  showBorder: true,
)
```

## 🖼️ Format des Assets

### Recommandations
- **Format** : PNG avec transparence
- **Résolution** : 
  - Avatars : 256x256px minimum
  - Items : 128x128px minimum
  - Familiers : 128x128px minimum
  - Auras : 256x256px minimum (peuvent être plus grandes)
- **Nommage** : 
  - En minuscules
  - Utiliser des underscores (_) pour les espaces
  - Pas d'accents ni de caractères spéciaux
  - Exemple : `hero_base.png`, `sword_epic.png`, `companion_fox.png`

## 🔄 Système de Fallback

Tous les widgets d'assets ont un système de fallback automatique :

1. **Si l'image existe** : Elle est affichée
2. **Si l'image n'existe pas** : 
   - Une icône stylisée est affichée
   - La couleur de fallback est utilisée
   - Un conteneur avec bordure est créé

Cela permet de développer même sans tous les assets disponibles.

## 📦 Ajout de Nouveaux Assets

### 1. Ajouter l'image dans le bon dossier
```
assets/images/avatars/mon_nouvel_avatar.png
```

### 2. Utiliser directement dans le code
```dart
AvatarImageWidget(
  avatarId: 'mon_nouvel_avatar',
  size: 80,
)
```

### 3. (Optionnel) Ajouter dans AssetsManager
Si vous voulez centraliser les chemins, ajoutez dans `lib/utils/assets_manager.dart` :
```dart
static const List<String> availableAvatars = [
  'hero_base',
  'mon_nouvel_avatar',  // Ajouté
];
```

## 🎨 Intégration avec les Mockups

Si vous avez des mockups Figma ou autres :

1. **Exporter les assets** depuis Figma
2. **Nommer les fichiers** selon la convention (minuscules, underscores)
3. **Placer dans les bons dossiers** (`assets/images/avatars/`, etc.)
4. **Utiliser les widgets** dans le code

### Exemple de workflow
1. Export depuis Figma : `Hero_Base.png`
2. Renommer : `hero_base.png`
3. Placer dans : `assets/images/avatars/hero_base.png`
4. Utiliser : `AvatarImageWidget(avatarId: 'hero_base')`

## 🐛 Dépannage

### L'image ne s'affiche pas
1. Vérifier que le fichier existe dans `assets/images/`
2. Vérifier le nom du fichier (sensible à la casse)
3. Vérifier que le fichier est déclaré dans `pubspec.yaml` :
```yaml
flutter:
  assets:
    - assets/images/avatars/
    - assets/images/companions/
    - assets/images/items/
```

### L'icône de fallback s'affiche
C'est normal si l'image n'existe pas encore. Le système de fallback permet de continuer le développement.

## 📚 Références

- `lib/utils/assets_manager.dart` - Gestionnaire centralisé
- `lib/ui/widgets/common/asset_image_widget.dart` - Widgets d'assets
- `lib/ui/widgets/common/magical_avatar.dart` - Avatar magique avec assets

