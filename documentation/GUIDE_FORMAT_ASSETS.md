# Guide des Formats d'Assets - Sameva

## 📋 Formats Recommandés

### ✅ Formats Acceptés par Flutter

Flutter supporte plusieurs formats d'images :

1. **PNG** (recommandé pour les assets avec transparence)
   - ✅ Transparence (alpha channel)
   - ✅ Qualité élevée
   - ⚠️ Taille de fichier plus importante
   - **Utilisez PNG pour** : Avatars, Items, Familiers, Auras, Icônes

2. **WebP** (recommandé pour optimisation)
   - ✅ Excellente compression
   - ✅ Transparence supportée
   - ✅ Taille réduite (30-50% plus petit que PNG)
   - **Utilisez WebP pour** : Backgrounds, grandes images

3. **JPEG** (non recommandé pour ce projet)
   - ❌ Pas de transparence
   - ✅ Bonne compression
   - **Évitez JPEG** : Nécessite des fonds transparents

## 🎨 Utilisation Directe des Mockups PNG

### ✅ OUI, vous pouvez utiliser vos PNG de mockups directement !

Flutter peut charger des PNG sans problème. Voici comment :

### 1. Format des Fichiers

**Nommage recommandé** :
- ✅ `hero_base.png`
- ✅ `sword_epic.png`
- ✅ `companion_fox.png`
- ❌ `Hero Base.png` (espaces et majuscules)
- ❌ `épée_légendaire.png` (accents)

**Convention** :
- Minuscules uniquement
- Underscores (_) pour les espaces
- Pas d'accents ni caractères spéciaux
- Extension `.png` en minuscules

### 2. Tailles Recommandées

Pour une qualité optimale sur tous les écrans :

| Type d'Asset | Taille Recommandée | Résolution @2x | Résolution @3x |
|--------------|-------------------|----------------|----------------|
| **Avatars** | 256x256px | 512x512px | 768x768px |
| **Familiers** | 128x128px | 256x256px | 384x384px |
| **Items** | 128x128px | 256x256px | 384x384px |
| **Auras** | 256x256px | 512x512px | 768x768px |
| **Backgrounds** | 1080x1920px | 2160x3840px | 3240x5760px |

**Note** : Flutter peut redimensionner automatiquement, mais des tailles appropriées améliorent la qualité.

### 3. Export depuis vos Mockups

#### Depuis Figma :
1. Sélectionnez l'élément
2. Clic droit → **Export**
3. Format : **PNG**
4. Taille : **2x** ou **3x** (pour haute résolution)
5. ✅ Cocher "Transparent background" si nécessaire

#### Depuis Photoshop/Illustrator :
1. Fichier → **Export As** → **PNG**
2. ✅ Cocher "Transparent"
3. Qualité : **Maximum**
4. Résolution : **144 DPI** minimum

#### Depuis Sketch :
1. Sélectionnez l'artboard/élément
2. **Make Exportable**
3. Format : **PNG**
4. Taille : **2x** ou **3x**

## 📦 Structure des Assets

### Organisation Recommandée

```
assets/images/
├── avatars/
│   ├── hero_base.png          (256x256)
│   ├── hero_base@2x.png       (512x512) - Optionnel
│   ├── hero_base@3x.png       (768x768) - Optionnel
│   ├── hero_1.png
│   └── ...
├── companions/
│   ├── companion_1.png
│   ├── companion_fox.png
│   └── ...
├── items/
│   ├── sword_common.png
│   ├── sword_epic.png
│   ├── armor_rare.png
│   └── ...
├── auras/
│   ├── aura_1.png
│   ├── aura_fire.png
│   └── ...
└── backgrounds/
    ├── home_background.png
    ├── market_background.png
    └── ...
```

### Support Multi-Résolution

Flutter supporte automatiquement les résolutions multiples :

**Nommage** :
- `hero_base.png` → Résolution de base (1x)
- `hero_base@2x.png` → Résolution 2x (pour écrans haute densité)
- `hero_base@3x.png` → Résolution 3x (pour écrans très haute densité)

**Flutter choisit automatiquement** la meilleure résolution selon l'écran !

## 🔧 Configuration dans pubspec.yaml

Assurez-vous que vos assets sont déclarés :

```yaml
flutter:
  assets:
    - assets/images/avatars/
    - assets/images/companions/
    - assets/images/items/
    - assets/images/auras/
    - assets/images/backgrounds/
    - assets/images/invocations/
```

**Ou déclarer individuellement** :
```yaml
flutter:
  assets:
    - assets/images/avatars/hero_base.png
    - assets/images/avatars/hero_1.png
    # ...
```

## 🎯 Workflow Complet

### Étape 1 : Préparer vos Assets depuis les Mockups

1. **Exporter depuis votre outil de design** (Figma, Sketch, etc.)
   - Format : PNG
   - Taille : 2x ou 3x recommandé
   - Transparence : Activée si nécessaire

2. **Renommer les fichiers**
   - Enlever les espaces → underscores
   - Mettre en minuscules
   - Enlever les accents
   - Exemple : `Héros Base.png` → `hero_base.png`

3. **Placer dans les bons dossiers**
   ```
   assets/images/avatars/hero_base.png
   assets/images/items/sword_epic.png
   ```

### Étape 2 : Utiliser dans le Code

```dart
// Directement avec le chemin
Image.asset('assets/images/avatars/hero_base.png')

// Ou avec les widgets helper
AvatarImageWidget(
  avatarId: 'hero_base',  // Flutter cherchera hero_base.png
  size: 80,
)
```

### Étape 3 : Tester

```dart
// Le widget affichera automatiquement :
// 1. L'image si elle existe
// 2. Une icône de fallback si l'image n'existe pas
```

## 🚀 Optimisation (Optionnel)

### Compression PNG

Si vos fichiers PNG sont trop lourds :

1. **TinyPNG** (https://tinypng.com/)
   - Réduit la taille de 50-70%
   - Conserve la qualité visuelle
   - Gratuit (jusqu'à 20 images/jour)

2. **ImageOptim** (Mac)
   - Compression locale
   - Batch processing

3. **Squoosh** (https://squoosh.app/)
   - Outil web gratuit
   - Comparaison avant/après

### Conversion en WebP (Avancé)

Pour réduire encore plus la taille :

```bash
# Avec cwebp (Google)
cwebp input.png -q 80 -o output.webp
```

**Avantages WebP** :
- 30-50% plus petit que PNG
- Qualité équivalente
- Transparence supportée

**Note** : Flutter supporte WebP nativement, changez juste l'extension !

## 📐 Spécifications Techniques

### Transparence

✅ **Toujours utiliser PNG avec transparence** pour :
- Avatars (fond transparent)
- Items (fond transparent)
- Familiers (fond transparent)
- Auras (fond transparent)
- Icônes (fond transparent)

### Couleurs

- **Mode couleur** : RGB (pas CMYK)
- **Profondeur** : 24-bit ou 32-bit (avec alpha)
- **Espace colorimétrique** : sRGB

### Compression

- **PNG** : Compression sans perte (lossless)
- **WebP** : Compression avec perte contrôlée (lossy)

## 🎨 Exemples Concrets

### Exemple 1 : Avatar depuis Figma

1. **Dans Figma** :
   - Sélectionnez le frame "Hero Base"
   - Export → PNG → 2x
   - Téléchargez `Hero Base@2x.png`

2. **Renommer** :
   ```
   Hero Base@2x.png → hero_base.png
   ```

3. **Placer** :
   ```
   assets/images/avatars/hero_base.png
   ```

4. **Utiliser** :
   ```dart
   AvatarImageWidget(avatarId: 'hero_base', size: 80)
   ```

### Exemple 2 : Item depuis Sketch

1. **Dans Sketch** :
   - Sélectionnez l'artboard "Sword Epic"
   - Make Exportable → PNG → 2x
   - Export

2. **Renommer** :
   ```
   Sword Epic@2x.png → sword_epic.png
   ```

3. **Placer** :
   ```
   assets/images/items/sword_epic.png
   ```

4. **Utiliser** :
   ```dart
   ItemImageWidget(
     itemId: 'sword_epic',
     size: 64,
     rarityColor: AppColors.rarityEpic,
   )
   ```

## ⚠️ Points d'Attention

### ❌ À Éviter

1. **Espaces dans les noms** : `hero base.png` → `hero_base.png`
2. **Majuscules** : `Hero.png` → `hero.png`
3. **Accents** : `épée.png` → `epee.png`
4. **Caractères spéciaux** : `sword@epic.png` → `sword_epic.png`
5. **Fichiers trop lourds** : Compresser si > 500KB
6. **Résolution trop basse** : Minimum 128x128px pour les items

### ✅ Bonnes Pratiques

1. ✅ Nommer en minuscules avec underscores
2. ✅ Utiliser PNG avec transparence
3. ✅ Exporter en 2x ou 3x pour haute qualité
4. ✅ Organiser par dossiers (avatars/, items/, etc.)
5. ✅ Compresser les gros fichiers
6. ✅ Tester sur différents écrans

## 🔍 Vérification

### Checklist avant d'ajouter un asset

- [ ] Nom en minuscules avec underscores
- [ ] Format PNG avec transparence
- [ ] Taille appropriée (voir tableau ci-dessus)
- [ ] Fichier dans le bon dossier
- [ ] Déclaré dans `pubspec.yaml` (si dossier complet)
- [ ] Testé dans l'application

## 📚 Ressources Utiles

- **TinyPNG** : https://tinypng.com/ (Compression PNG)
- **Squoosh** : https://squoosh.app/ (Compression et conversion)
- **Flutter Assets** : https://docs.flutter.dev/development/ui/assets-and-images
- **ImageOptim** : https://imageoptim.com/ (Compression locale)

## 💡 Astuce Pro

Pour un workflow optimal :

1. **Créer un script de renommage** (optionnel)
   ```bash
   # Exemple avec PowerShell (Windows)
   Get-ChildItem *.png | Rename-Item -NewName { $_.Name.ToLower().Replace(' ', '_') }
   ```

2. **Utiliser un outil de batch processing** pour :
   - Renommer en masse
   - Optimiser en masse
   - Convertir en WebP en masse

3. **Créer un template** dans votre outil de design avec :
   - Tailles standardisées
   - Noms pré-formatés
   - Export automatique

---

**En résumé** : OUI, vous pouvez utiliser vos PNG de mockups directement ! Il suffit de :
1. Les exporter en PNG
2. Les renommer correctement
3. Les placer dans les bons dossiers
4. Les utiliser avec les widgets

Flutter s'occupe du reste ! 🚀

