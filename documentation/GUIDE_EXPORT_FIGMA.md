# Guide d'exportation depuis Figma vers Flutter

## 📋 Lien Figma
Votre design Figma : [Mockup Sameva](https://www.figma.com/make/LqRoDzdtmLcC2AV2E08ess/Mockup-Sameva--Community---Copy-?node-id=0-1&t=xZq5WkElAlQ4ySP1-1)

## 🎨 Composants identifiés dans votre design

D'après `assets/App.tsx`, votre design Figma contient :
- **Sanctuary** - Page principale/sanctuaire
- **QuestCreation** - Création de quêtes
- **Marketplace** - Marché
- **Summoning** - Invocation
- **Customization** - Personnalisation
- **MiniGame** - Mini-jeux
- **Navigation** - Barre de navigation

## 📥 Comment exporter les assets depuis Figma

### 1. Exporter les images

#### Pour les images statiques (PNG/WebP)
1. Sélectionnez l'élément dans Figma
2. Clic droit → **Export** ou utilisez le panneau Export à droite
3. Choisissez le format :
   - **PNG** pour les images avec transparence (avatars, items, icônes)
   - **WebP** pour les backgrounds (meilleure compression)
4. Exportez à 2x ou 3x pour les écrans haute résolution
5. Placez les fichiers dans les dossiers appropriés :

```
assets/images/
├── avatars/
│   ├── hero_base.png (2x: hero_base@2x.png, 3x: hero_base@3x.png)
│   └── ...
├── items/
│   ├── heaume_du_zénith.png
│   ├── épée_légendaire.png
│   └── ...
├── backgrounds/
│   ├── market_background.png
│   ├── home_background.png
│   └── ...
├── companions/
│   └── ...
└── auras/
    └── ...
```

#### Pour les icônes (SVG recommandé)
1. Sélectionnez l'icône
2. Export → Format **SVG**
3. Placez dans `assets/images/icons/`

### 2. Exporter les couleurs

Dans Figma :
1. Ouvrez le panneau **Design** → **Styles**
2. Notez les couleurs utilisées
3. Vérifiez que `lib/theme/app_colors.dart` correspond

### 3. Exporter les polices

Si vous utilisez des polices personnalisées :
1. Sélectionnez un texte avec la police
2. Notez le nom de la police
3. Téléchargez le fichier de police (.ttf ou .otf)
4. Placez dans `assets/fonts/`
5. Ajoutez dans `pubspec.yaml` :

```yaml
fonts:
  - family: NomDeLaPolice
    fonts:
      - asset: assets/fonts/nom_police.ttf
```

### 4. Exporter les composants spécifiques

Pour les composants comme Sanctuary, Marketplace, etc. :
1. Sélectionnez le frame/composant
2. Export → **PNG** ou **SVG** selon le besoin
3. Utilisez ces images comme référence pour recréer en Flutter

## 🔧 Intégration dans Flutter

### Structure recommandée

Une fois les assets exportés, organisez-les ainsi :

```
assets/
├── images/
│   ├── avatars/
│   │   ├── hero_base.png
│   │   ├── hero_base@2x.png
│   │   └── hero_base@3x.png
│   ├── items/
│   │   ├── heaume_du_zénith.png
│   │   └── ...
│   ├── backgrounds/
│   │   └── ...
│   ├── companions/
│   │   └── ...
│   └── auras/
│       └── ...
├── animations/
│   ├── rive/
│   └── lottie/
└── fonts/
    └── ...
```

### Utilisation dans le code

#### Images avec résolution multiple
```dart
Image.asset(
  'assets/images/avatars/hero_base.png', // Flutter choisit automatiquement @2x ou @3x
  width: 100,
  height: 100,
)
```

#### Images simples
```dart
Image.asset(
  'assets/images/items/heaume_du_zénith.png',
  fit: BoxFit.contain,
)
```

#### Backgrounds
```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/backgrounds/market_background.png'),
      fit: BoxFit.cover,
    ),
  ),
)
```

## 📐 Correspondance Figma → Flutter

### Espacements
- Figma utilise des pixels (px)
- Flutter utilise des `EdgeInsets` avec des valeurs en `double`
- Exemple : `padding: 16` dans Figma → `padding: const EdgeInsets.all(16)`

### Bordures arrondies
- Figma : `border-radius: 16px`
- Flutter : `BorderRadius.circular(16)`

### Ombres
- Figma : `box-shadow`
- Flutter : `BoxShadow` dans `boxShadow: [...]`

### Couleurs
- Figma : Hex (#785096) ou RGB
- Flutter : `Color(0xFF785096)` (ajoutez FF pour l'opacité)

## 🎯 Checklist d'exportation

- [ ] Exporter tous les avatars depuis le composant Customization
- [ ] Exporter tous les items depuis Marketplace
- [ ] Exporter les backgrounds pour chaque page
- [ ] Exporter les compagnons
- [ ] Exporter les auras/effets visuels
- [ ] Vérifier les couleurs dans app_colors.dart
- [ ] Exporter les icônes en SVG
- [ ] Tester l'affichage dans l'app Flutter

## 💡 Astuces

1. **Nommage** : Utilisez des noms en minuscules avec underscores (ex: `hero_base.png`)
2. **Optimisation** : Compressez les images PNG avec [TinyPNG](https://tinypng.com/)
3. **Résolutions** : Exportez toujours en 1x, 2x et 3x pour supporter tous les écrans
4. **Organisation** : Gardez la même structure que dans Figma pour faciliter la maintenance

## 🔗 Ressources

- [Documentation Flutter - Assets](https://docs.flutter.dev/development/ui/assets-and-images)
- [Figma Export Guide](https://help.figma.com/hc/en-us/articles/360040328153-Export-files-from-Figma)
- [Flutter Image Resolution](https://docs.flutter.dev/development/ui/assets-and-images#resolution-aware)









